import Foundation
import RevenueCat
import UserNotifications

/// Local reminder advertised on the trial paywall: notify one day before the free trial ends.
enum TrialEndingReminder {
    static let notificationIdentifier = "culina.trial.ending.tomorrow"
    static let leadTime: TimeInterval = 24 * 60 * 60
    /// `UNTimeIntervalNotificationTrigger` / calendar triggers must stay in the future.
    static let minimumDelay: TimeInterval = 60

    struct Snapshot: Equatable {
        var isActiveUnlimited: Bool
        var isTrialPeriod: Bool
        var expirationDate: Date?

        static let inactive = Snapshot(isActiveUnlimited: false, isTrialPeriod: false, expirationDate: nil)
    }

    enum Plan: Equatable {
        case cancel
        case schedule(Date)
    }

    static func snapshot(from info: CustomerInfo?) -> Snapshot {
        guard let entitlement = info?.entitlements[RevenueCatManager.unlimitedEntitlementID] else {
            return .inactive
        }
        return Snapshot(
            isActiveUnlimited: entitlement.isActive,
            isTrialPeriod: entitlement.periodType == .trial,
            expirationDate: entitlement.expirationDate
        )
    }

    static func plan(for snapshot: Snapshot, now: Date = Date()) -> Plan {
        guard snapshot.isActiveUnlimited, snapshot.isTrialPeriod, let expiration = snapshot.expirationDate else {
            return .cancel
        }
        let fireDate = expiration.addingTimeInterval(-leadTime)
        guard fireDate.timeIntervalSince(now) >= minimumDelay else {
            return .cancel
        }
        return .schedule(fireDate)
    }
}

@MainActor
final class TrialEndingReminderScheduler {
    static let shared = TrialEndingReminderScheduler()

    private var didStart = false
    private var latestSnapshot = TrialEndingReminder.Snapshot.inactive
    private var languageObserver: NSObjectProtocol?

    private init() {}

    func start() {
        guard !didStart else { return }
        didStart = true
        languageObserver = NotificationCenter.default.addObserver(
            forName: .languageChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.applyLatestSnapshot()
            }
        }
    }

    func sync(from info: CustomerInfo?) {
        latestSnapshot = TrialEndingReminder.snapshot(from: info)
        Task { await applyLatestSnapshot() }
    }

    private func applyLatestSnapshot() async {
        let center = UNUserNotificationCenter.current()
        switch TrialEndingReminder.plan(for: latestSnapshot) {
        case .cancel:
            center.removePendingNotificationRequests(
                withIdentifiers: [TrialEndingReminder.notificationIdentifier]
            )
        case .schedule(let fireDate):
            await schedule(at: fireDate, center: center)
        }
    }

    private func schedule(at fireDate: Date, center: UNUserNotificationCenter) async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                guard granted else {
                    Logger.info("[TrialReminder] permission denied — skip schedule", category: .data)
                    return
                }
            } catch {
                Logger.error("[TrialReminder] permission request failed", error: error, category: .data)
                return
            }
        default:
            Logger.info("[TrialReminder] notifications not allowed — skip schedule", category: .data)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = L.trial_endingTomorrowTitle.localized
        content.body = L.trial_endingTomorrowBody.localized
        content.sound = .default
        content.categoryIdentifier = "TRIAL_ENDING"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: TrialEndingReminder.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(
            withIdentifiers: [TrialEndingReminder.notificationIdentifier]
        )
        do {
            try await center.add(request)
            Logger.info("[TrialReminder] scheduled for \(fireDate)", category: .data)
        } catch {
            Logger.error("[TrialReminder] failed to schedule", error: error, category: .data)
        }
    }
}
