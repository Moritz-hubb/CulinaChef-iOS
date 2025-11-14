import Foundation
import SwiftUI
import AVFoundation
import Combine

/// Manages multiple cooking timers
final class TimerCenter: ObservableObject {
    @Published var timers: [RunningTimer] = []
    
    func start(minutes: Int, label: String) {
        let timer = RunningTimer(minutes: minutes, label: label)
        timers.append(timer)
    }
    
    func remove(timer: RunningTimer) {
        timer.audioPlayer?.stop()
        timers.removeAll { $0.id == timer.id }
    }
}

/// A single running timer with audio notification
final class RunningTimer: ObservableObject, Identifiable {
    let id = UUID()
    let label: String
    
    @Published var remaining: Int
    @Published var running: Bool = true
    @Published var baseMinutes: Int
    
    var audioPlayer: AVAudioPlayer?
    private var timerTask: Task<Void, Never>?
    
    init(minutes: Int, label: String) {
        self.baseMinutes = minutes
        self.remaining = minutes * 60
        self.label = label
        startTicking()
    }
    
    deinit {
        timerTask?.cancel()
        audioPlayer?.stop()
    }
    
    func reset() {
        remaining = baseMinutes * 60
        running = true
        audioPlayer?.stop()
        startTicking()
    }
    
    private func startTicking() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                if running {
                    remaining -= 1
                    if remaining == 0 {
                        playSound()
                    }
                }
            }
        }
    }
    
    private func playSound() {
        // Try to play a system sound for timer completion
        guard let soundURL = Bundle.main.url(forResource: "timer_complete", withExtension: "mp3") ??
                             Bundle.main.url(forResource: "timer_complete", withExtension: "wav") else {
            // Fallback to system sound if no custom sound available
            AudioServicesPlaySystemSound(1005) // System beep
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = 3 // Repeat 3 times
            audioPlayer?.play()
        } catch {
            // Fallback to system sound
            AudioServicesPlaySystemSound(1005)
        }
    }
}
