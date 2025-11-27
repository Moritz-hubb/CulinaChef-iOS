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
        .description("Zeigt alle deine aktiven Timer an")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
        
        // Update every 10 seconds for running timers, every minute for paused timers
        let hasRunningTimers = timers.contains { $0.running }
        let updateInterval: TimeInterval = hasRunningTimers ? 10 : 60
        
        guard let nextUpdate = Calendar.current.date(byAdding: .second, value: Int(updateInterval), to: currentDate) else {
            let entry = TimerEntry(date: currentDate, timers: timers)
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
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if entry.timers.isEmpty {
            emptyStateView
        } else {
            switch family {
            case .systemSmall:
                smallWidgetView
            case .systemMedium:
                mediumWidgetView
            case .systemLarge:
                largeWidgetView
            default:
                mediumWidgetView
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("Keine aktiven Timer")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Starte einen Timer in der App")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Small Widget (1 Timer)
    @ViewBuilder
    private var smallWidgetView: some View {
        if let firstTimer = entry.timers.first {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: firstTimer.running ? "timer" : "pause.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            firstTimer.running ?
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(colors: [Color.gray], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    if entry.timers.count > 1 {
                        Text("+\(entry.timers.count - 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                
                Text(firstTimer.label)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(formatTime(firstTimer.remaining))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
        } else {
            emptyStateView
        }
    }
    
    // MARK: - Medium Widget (2-3 Timer)
    private var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("\(entry.timers.count) Timer")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(entry.timers.prefix(3).enumerated()), id: \.offset) { index, timer in
                    timerRow(timer: timer, isLast: index == min(2, entry.timers.count - 1))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
    
    // MARK: - Large Widget (Alle Timer)
    private var largeWidgetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Aktive Timer")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Spacer()
                if !entry.timers.isEmpty {
                    Text("\(entry.timers.count)")
                        .font(.title3.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(entry.timers.enumerated()), id: \.offset) { index, timer in
                        timerRow(timer: timer, isLast: index == entry.timers.count - 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
    
    // MARK: - Timer Row Component
    private func timerRow(timer: TimerInfo, isLast: Bool) -> some View {
        HStack(spacing: 12) {
            // Status Icon
            Image(systemName: timer.running ? "timer" : "pause.circle.fill")
                .font(.title3)
                .foregroundStyle(
                    timer.running ?
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.5, blue: 0.3), Color(red: 0.85, green: 0.4, blue: 0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(colors: [Color.gray], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 24)
            
            // Timer Info
            VStack(alignment: .leading, spacing: 2) {
                Text(timer.label)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(formatTime(timer.remaining))
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    timer.running ?
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.3), Color(red: 0.85, green: 0.4, blue: 0.2).opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(colors: [Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Helper
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

#Preview(as: .systemMedium) {
    CulinaChefTimerWidget()
} timeline: {
    TimerEntry(date: .now, timers: [
        TimerInfo(label: "Pasta kochen", remaining: 420, running: true),
        TimerInfo(label: "Sauce köcheln", remaining: 180, running: true),
        TimerInfo(label: "Käse reiben", remaining: 60, running: false)
    ])
}

#Preview(as: .systemLarge) {
    CulinaChefTimerWidget()
} timeline: {
    TimerEntry(date: .now, timers: [
        TimerInfo(label: "Pasta kochen", remaining: 420, running: true),
        TimerInfo(label: "Sauce köcheln", remaining: 180, running: true),
        TimerInfo(label: "Käse reiben", remaining: 60, running: false),
        TimerInfo(label: "Salat zubereiten", remaining: 300, running: true),
        TimerInfo(label: "Brot aufbacken", remaining: 120, running: false)
    ])
}


