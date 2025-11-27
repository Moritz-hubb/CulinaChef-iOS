import WidgetKit
import SwiftUI
import os.log

struct CulinaChefTimerWidget: Widget {
    let kind: String = "CulinaChefTimerWidget"
    
    private static let log = OSLog(subsystem: "com.moritzserrin.culinachef.widget", category: "CulinaChefTimerWidget")
    
    init() {
        os_log("[Widget] CulinaChefTimerWidget initialized with kind: %{public}@", log: Self.log, type: .info, kind)
    }
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerProvider()) { entry in
            os_log("[Widget] Widget body rendering with %d timers", log: Self.log, type: .debug, entry.timers.count)
            return TimerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Koch-Timer")
        .description("Zeigt alle deine aktiven Timer an")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TimerProvider: TimelineProvider {
    typealias Entry = TimerEntry
    
    private static let log = OSLog(subsystem: "com.moritzserrin.culinachef.widget", category: "TimerProvider")
    
    func placeholder(in context: Context) -> TimerEntry {
        os_log("[Widget] placeholder() called", log: Self.log, type: .info)
        let entry = TimerEntry(date: Date(), timers: [
            TimerInfo(label: "Pasta kochen", remaining: 420, running: true)
        ])
        os_log("[Widget] placeholder() returning %d timers", log: Self.log, type: .info, entry.timers.count)
        return entry
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        os_log("[Widget] getSnapshot() called - context.isPreview: %{public}@", log: Self.log, type: .info, String(context.isPreview))
        let timers = loadTimers()
        os_log("[Widget] getSnapshot() loaded %d timers", log: Self.log, type: .info, timers.count)
        let entry = TimerEntry(date: Date(), timers: timers)
        os_log("[Widget] getSnapshot() completing with %d timers", log: Self.log, type: .info, entry.timers.count)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        os_log("[Widget] getTimeline() called - context.isPreview: %{public}@", log: Self.log, type: .info, String(context.isPreview))
        let currentDate = Date()
        let timers = loadTimers()
        os_log("[Widget] getTimeline() loaded %d timers", log: Self.log, type: .info, timers.count)
        
        // Update every 10 seconds for running timers, every minute for paused timers
        let hasRunningTimers = timers.contains { $0.running }
        let updateInterval: TimeInterval = hasRunningTimers ? 10 : 60
        os_log("[Widget] getTimeline() hasRunningTimers: %{public}@, updateInterval: %.0f seconds", log: Self.log, type: .info, String(hasRunningTimers), updateInterval)
        
        guard let nextUpdate = Calendar.current.date(byAdding: .second, value: Int(updateInterval), to: currentDate) else {
            os_log("[Widget] getTimeline() ERROR: Could not calculate nextUpdate", log: Self.log, type: .error)
            let entry = TimerEntry(date: currentDate, timers: timers)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
            return
        }
        
        os_log("[Widget] getTimeline() nextUpdate: %{public}@", log: Self.log, type: .info, nextUpdate.description)
        let entry = TimerEntry(date: currentDate, timers: timers)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        os_log("[Widget] getTimeline() completing with %d timers, next update in %.0f seconds", log: Self.log, type: .info, timers.count, updateInterval)
        completion(timeline)
    }
    
    private func loadTimers() -> [TimerInfo] {
        let appGroupID = "group.com.moritzserrin.culinachef"
        os_log("[Widget] loadTimers() called, appGroupID: %{public}@", log: Self.log, type: .debug, appGroupID)
        
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            os_log("[Widget] loadTimers() ERROR: Could not access UserDefaults with suiteName: %{public}@", log: Self.log, type: .error, appGroupID)
            return []
        }
        
        os_log("[Widget] loadTimers() UserDefaults accessed successfully", log: Self.log, type: .debug)
        
        guard let timerData = defaults.array(forKey: "active_timers") as? [[String: Any]] else {
            os_log("[Widget] loadTimers() No timer data found in UserDefaults for key 'active_timers'", log: Self.log, type: .info)
            return []
        }
        
        os_log("[Widget] loadTimers() Found %d timer entries in UserDefaults", log: Self.log, type: .info, timerData.count)
        
        var timers: [TimerInfo] = []
        for (index, data) in timerData.enumerated() {
            guard let label = data["label"] as? String,
                  let remaining = data["remaining"] as? Int,
                  let running = data["running"] as? Bool else {
                os_log("[Widget] loadTimers() ERROR: Invalid timer data at index %d: %{public}@", log: Self.log, type: .error, index, String(describing: data))
                continue
            }
            
            // Recalculate remaining time if timer is running
            var actualRemaining = remaining
            if running, let endTimeInterval = data["endTime"] as? TimeInterval, endTimeInterval > 0 {
                let endTime = Date(timeIntervalSince1970: endTimeInterval)
                actualRemaining = max(0, Int(endTime.timeIntervalSinceNow))
                os_log("[Widget] loadTimers() Timer '%{public}@' is running, recalculated remaining: %d seconds", log: Self.log, type: .debug, label, actualRemaining)
            }
            
            os_log("[Widget] loadTimers() Adding timer: label='%{public}@', remaining=%d, running=%{public}@", log: Self.log, type: .debug, label, actualRemaining, String(running))
            timers.append(TimerInfo(label: label, remaining: actualRemaining, running: running))
        }
        
        os_log("[Widget] loadTimers() returning %d valid timers", log: Self.log, type: .info, timers.count)
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
    
    private static let log = OSLog(subsystem: "com.moritzserrin.culinachef.widget", category: "TimerWidgetEntryView")
    
    var body: some View {
        let _ = Self.logWidgetRender()
        
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
    
    private func logWidgetRender() {
        let familyName: String
        switch family {
        case .systemSmall: familyName = "Small"
        case .systemMedium: familyName = "Medium"
        case .systemLarge: familyName = "Large"
        default: familyName = "Unknown"
        }
        os_log("[Widget] TimerWidgetEntryView rendering - family: %{public}@, timers: %d", log: Self.log, type: .info, familyName, entry.timers.count)
        if !entry.timers.isEmpty {
            for (index, timer) in entry.timers.enumerated() {
                os_log("[Widget] Timer %d: label='%{public}@', remaining=%d, running=%{public}@", log: Self.log, type: .debug, index, timer.label, timer.remaining, String(timer.running))
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


