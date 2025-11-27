import WidgetKit
import SwiftUI

struct CulinaChefTimerWidget: Widget {
    let kind: String = "CulinaChefTimerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerProvider()) { entry in
            TimerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Koch-Timer")
        .description("Zeigt deine aktiven Timer an")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TimerProvider: TimelineProvider {
    typealias Entry = TimerEntry
    
    func placeholder(in context: Context) -> TimerEntry {
        TimerEntry(date: Date(), timers: [
            TimerInfo(label: "Pasta kochen", remaining: 420, running: true)
        ])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        let entry = TimerEntry(date: Date(), timers: loadTimers())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        let currentDate = Date()
        let timers = loadTimers()
        
        // Update every minute
        guard let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate) else {
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
            return
        }
        let entry = TimerEntry(date: currentDate, timers: timers)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadTimers() -> [TimerInfo] {
        let appGroupID = "group.com.moritzserrin.culinachef"
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let timerData = defaults.array(forKey: "active_timers") as? [[String: Any]] else {
            return []
        }
        
        var timers: [TimerInfo] = []
        for data in timerData {
            guard let label = data["label"] as? String,
                  let remaining = data["remaining"] as? Int,
                  let running = data["running"] as? Bool else {
                continue
            }
            
            // Recalculate remaining time if timer is running
            var actualRemaining = remaining
            if running, let endTimeInterval = data["endTime"] as? TimeInterval, endTimeInterval > 0 {
                let endTime = Date(timeIntervalSince1970: endTimeInterval)
                actualRemaining = max(0, Int(endTime.timeIntervalSinceNow))
            }
            
            timers.append(TimerInfo(label: label, remaining: actualRemaining, running: running))
        }
        
        return timers
    }
}

struct TimerEntry: TimelineEntry {
    let date: Date
    let timers: [TimerInfo]
}

struct TimerInfo {
    let label: String
    let remaining: Int
    let running: Bool
}

struct TimerWidgetEntryView: View {
    var entry: TimerProvider.Entry
    
    var body: some View {
        if entry.timers.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("Keine aktiven Timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(entry.timers.enumerated()), id: \.offset) { _, timer in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timer.label)
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        HStack {
                            Image(systemName: timer.running ? "timer" : "timer.square")
                                .font(.caption)
                                .foregroundStyle(timer.running ? .orange : .secondary)
                            
                            Text(formatTime(timer.remaining))
                                .font(.title3.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview(as: .systemSmall) {
    CulinaChefTimerWidget()
} timeline: {
    TimerEntry(date: .now, timers: [
        TimerInfo(label: "Pasta kochen", remaining: 420, running: true)
    ])
    TimerEntry(date: .now, timers: [])
}

