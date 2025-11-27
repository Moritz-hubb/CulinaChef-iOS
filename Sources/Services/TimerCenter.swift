import Foundation
import SwiftUI
import AVFoundation
import Combine
import UserNotifications
import AudioToolbox

/// Manages multiple cooking timers with background support
final class TimerCenter: ObservableObject {
    @Published var timers: [RunningTimer] = []
    
    // App Group for sharing timer data with widget
    private let appGroupID = "group.com.moritzserrin.culinachef"
    private var appGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    init() {
        // Restore timers from persistent storage on init
        restoreTimers()
        // Request notification permission
        requestNotificationPermission()
    }
    
    func start(minutes: Int, label: String) {
        let timer = RunningTimer(minutes: minutes, label: label, timerCenter: self)
        timers.append(timer)
        saveTimers()
    }
    
    func remove(timer: RunningTimer) {
        timer.stopSound()
        timer.cancelNotification()
        timers.removeAll { $0.id == timer.id }
        saveTimers()
    }
    
    func stopAllTimers() {
        for timer in timers {
            timer.stopSound()
            timer.cancelNotification()
        }
        timers.removeAll()
        saveTimers()
    }
    
    func saveTimers() {
        // Save timer data to App Group for widget access
        guard let defaults = appGroupDefaults else { return }
        let timerData = timers.map { timer in
            [
                "id": timer.id.uuidString,
                "label": timer.label,
                "remaining": timer.remaining,
                "baseMinutes": timer.baseMinutes,
                "running": timer.running,
                "endTime": timer.endTime?.timeIntervalSince1970 ?? 0
            ]
        }
        defaults.set(timerData, forKey: "active_timers")
        defaults.synchronize()
    }
    
    private func restoreTimers() {
        guard let defaults = appGroupDefaults,
              let timerData = defaults.array(forKey: "active_timers") as? [[String: Any]] else {
            return
        }
        
        for data in timerData {
            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let label = data["label"] as? String,
                  let baseMinutes = data["baseMinutes"] as? Int else {
                continue
            }
            
            let remaining = data["remaining"] as? Int ?? baseMinutes * 60
            let running = data["running"] as? Bool ?? false
            let endTimeInterval = data["endTime"] as? TimeInterval ?? 0
            let endTime = endTimeInterval > 0 ? Date(timeIntervalSince1970: endTimeInterval) : nil
            
            let timer = RunningTimer(
                id: id,
                minutes: baseMinutes,
                label: label,
                remaining: remaining,
                running: running,
                endTime: endTime,
                timerCenter: self
            )
            timers.append(timer)
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                // Notification permission granted
            }
        }
    }
}

/// A single running timer with audio notification and background support
final class RunningTimer: ObservableObject, Identifiable {
    let id: UUID
    let label: String
    
    @Published var remaining: Int
    @Published var running: Bool = true {
        didSet {
            if running {
                scheduleNotification()
            } else {
                cancelNotification()
            }
            timerCenter?.saveTimers()
        }
    }
    @Published var baseMinutes: Int
    
    var endTime: Date? // When timer will finish (for background calculation)
    weak var timerCenter: TimerCenter?
    var audioPlayer: AVAudioPlayer?
    private var timerTask: Task<Void, Never>?
    
    init(minutes: Int, label: String, timerCenter: TimerCenter) {
        self.id = UUID()
        self.baseMinutes = minutes
        self.remaining = minutes * 60
        self.label = label
        self.timerCenter = timerCenter
        self.endTime = running ? Date().addingTimeInterval(TimeInterval(minutes * 60)) : nil
        startTicking()
        scheduleNotification()
    }
    
    // Restore from saved state
    init(id: UUID, minutes: Int, label: String, remaining: Int, running: Bool, endTime: Date?, timerCenter: TimerCenter) {
        self.id = id
        self.baseMinutes = minutes
        self.remaining = remaining
        self.running = running
        self.label = label
        self.timerCenter = timerCenter
        self.endTime = endTime
        
        // Recalculate remaining time if timer was running in background
        if running, let end = endTime {
            let elapsed = max(0, Int(end.timeIntervalSinceNow))
            self.remaining = max(0, elapsed)
            if self.remaining == 0 {
                // Timer finished while app was in background
                playSound()
                self.running = false
            }
        }
        
        startTicking()
        if running {
            scheduleNotification()
        }
    }
    
    deinit {
        timerTask?.cancel()
        audioPlayer?.stop()
        cancelNotification()
    }
    
    func reset() {
        remaining = baseMinutes * 60
        running = true
        audioPlayer?.stop()
        cancelNotification()
        endTime = Date().addingTimeInterval(TimeInterval(remaining))
        startTicking()
        scheduleNotification()
        timerCenter?.saveTimers()
    }
    
    private func startTicking() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                if running {
                    // Always use endTime calculation for accuracy (handles background time)
                    if let end = endTime {
                        let elapsed = max(0, Int(end.timeIntervalSinceNow))
                        remaining = max(0, elapsed)
                    } else {
                        // Fallback: manual decrement (shouldn't happen, but safety)
                        remaining -= 1
                        endTime = Date().addingTimeInterval(TimeInterval(remaining))
                    }
                    
                    // Save timer state periodically
                    timerCenter?.saveTimers()
                    
                    if remaining == 0 {
                        if !running {
                            // Timer was paused, don't play sound
                        } else {
                            playSound()
                            running = false
                            cancelNotification()
                            timerCenter?.saveTimers()
                        }
                    }
                }
            }
        }
    }
    
    private func scheduleNotification() {
        guard running, remaining > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Timer abgelaufen"
        content.body = "\(label) ist fertig!"
        content.sound = .default
        content.categoryIdentifier = "TIMER_COMPLETE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remaining), repeats: false)
        let request = UNNotificationRequest(identifier: id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                // Failed to schedule notification: \(error)
            }
        }
    }
    
    func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
    
    private func playSound() {
        // Use a pleasant ringtone-like system sound
        // System Sound IDs: 1013, 1014, 1016 are more pleasant than alarm sounds
        // 1016 is a nice ringtone-like sound
        AudioServicesPlaySystemSound(1016) // Pleasant ringtone sound
        
        // Also try to play custom sound if available, but loop it indefinitely
        if let soundURL = Bundle.main.url(forResource: "timer_complete", withExtension: "mp3") ??
                          Bundle.main.url(forResource: "timer_complete", withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely until stopped
                audioPlayer?.play()
            } catch {
                // Custom sound failed, system sound already played
            }
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
