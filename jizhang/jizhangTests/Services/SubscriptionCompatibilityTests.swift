import XCTest
@testable import jizhang

final class SubscriptionCompatibilityTests: XCTestCase {
    func testExpiredSubscriptionDoesNotGrantPremium() {
        let manager = SubscriptionManager(
            startStoreKit: false,
            initialStatus: .premium(expiresAt: Date().addingTimeInterval(-60))
        )

        XCTAssertFalse(manager.subscriptionStatus.isPremium)
        XCTAssertFalse(manager.hasAccess(to: .comparisonReport))
    }

    func testLifetimeKeepsExistingAdvancedEntitlements() {
        let manager = SubscriptionManager(
            startStoreKit: false,
            initialStatus: .lifetime
        )

        XCTAssertTrue(manager.hasAccess(to: .comparisonReport))
        XCTAssertTrue(manager.hasAccess(to: .exportLedger))
    }

    func testBasicBudgetIsAvailableForFreeUser() {
        let manager = SubscriptionManager(startStoreKit: false)

        XCTAssertTrue(manager.hasAccess(to: .budgetManagement))
        XCTAssertFalse(manager.hasAccess(to: .exportLedger))
    }
}
