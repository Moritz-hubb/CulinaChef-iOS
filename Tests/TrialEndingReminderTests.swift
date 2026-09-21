import XCTest
@testable import CulinaChef

final class TrialEndingReminderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testPlan_schedulesOneDayBeforeTrialEnd() {
        let expiration = now.addingTimeInterval(3 * 24 * 60 * 60)
        let snapshot = TrialEndingReminder.Snapshot(
            isActiveUnlimited: true,
            isTrialPeriod: true,
            expirationDate: expiration
        )

        let plan = TrialEndingReminder.plan(for: snapshot, now: now)
        guard case .schedule(let fireDate) = plan else {
            return XCTFail("Expected schedule plan")
        }
        XCTAssertEqual(fireDate.timeIntervalSince(now), 2 * 24 * 60 * 60, accuracy: 0.5)
    }

    func testPlan_cancelsWhenNotInTrial() {
        let snapshot = TrialEndingReminder.Snapshot(
            isActiveUnlimited: true,
            isTrialPeriod: false,
            expirationDate: now.addingTimeInterval(30 * 24 * 60 * 60)
        )
        XCTAssertEqual(TrialEndingReminder.plan(for: snapshot, now: now), .cancel)
    }

    func testPlan_cancelsWhenInactive() {
        let snapshot = TrialEndingReminder.Snapshot(
            isActiveUnlimited: false,
            isTrialPeriod: true,
            expirationDate: now.addingTimeInterval(2 * 24 * 60 * 60)
        )
        XCTAssertEqual(TrialEndingReminder.plan(for: snapshot, now: now), .cancel)
    }

    func testPlan_cancelsWhenLessThanOneDayRemains() {
        let snapshot = TrialEndingReminder.Snapshot(
            isActiveUnlimited: true,
            isTrialPeriod: true,
            expirationDate: now.addingTimeInterval(12 * 60 * 60)
        )
        XCTAssertEqual(TrialEndingReminder.plan(for: snapshot, now: now), .cancel)
    }

    func testPlan_cancelsWithoutExpiration() {
        let snapshot = TrialEndingReminder.Snapshot(
            isActiveUnlimited: true,
            isTrialPeriod: true,
            expirationDate: nil
        )
        XCTAssertEqual(TrialEndingReminder.plan(for: snapshot, now: now), .cancel)
    }

    func testLocalizationFiles_containTrialReminderKeys() throws {
        let testsDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let localizationDir = testsDir.deletingLastPathComponent()
            .appendingPathComponent("Resources/Localization")
        let languages = ["de", "en", "es", "fr", "it"]
        let keys = ["trial.endingTomorrowTitle", "trial.endingTomorrowBody"]

        for language in languages {
            let url = localizationDir.appendingPathComponent("\(language).json")
            let data = try Data(contentsOf: url)
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
            for key in keys {
                let value = try XCTUnwrap(json[key], "Missing \(key) in \(language).json")
                XCTAssertFalse(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
