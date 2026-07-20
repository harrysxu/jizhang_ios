import XCTest
import SwiftData
@testable import jizhang

@MainActor
final class AppStateLedgerSelectionTests: XCTestCase {
    func testRestoresLastSelectedLedgerBeforeDefaultLedger() throws {
        let fixture = try makeFixture()
        try withSavedLedgerID(fixture.selected.id) {
            let state = AppState(environment: makeEnvironment(container: fixture.container))

            XCTAssertEqual(state.currentLedger?.id, fixture.selected.id)
            XCTAssertEqual(state.launchState, .ready)
        }
    }

    func testFallsBackToDefaultWhenLastSelectedLedgerIsArchived() throws {
        let fixture = try makeFixture()
        fixture.selected.isArchived = true
        try fixture.container.mainContext.save()

        try withSavedLedgerID(fixture.selected.id) {
            let state = AppState(environment: makeEnvironment(container: fixture.container))

            XCTAssertEqual(state.currentLedger?.id, fixture.defaultLedger.id)
            XCTAssertEqual(state.launchState, .ready)
        }
    }

    private func makeFixture() throws -> (
        container: ModelContainer,
        defaultLedger: Ledger,
        selected: Ledger
    ) {
        let configuration = ModelConfiguration(
            schema: ModelContainerFactory.schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: ModelContainerFactory.schema,
            configurations: [configuration]
        )
        let defaultLedger = Ledger(name: "默认账本", sortOrder: 0, isDefault: true)
        let selected = Ledger(name: "上次使用账本", sortOrder: 1)
        container.mainContext.insert(defaultLedger)
        container.mainContext.insert(selected)
        try container.mainContext.save()
        return (container, defaultLedger, selected)
    }

    private func makeEnvironment(container: ModelContainer) -> AppEnvironment {
        AppEnvironment(
            containerFactory: ExistingStoreFactory(container: container),
            storeMode: .inMemory,
            cloudKitService: CloudKitService(container: nil, startMonitoring: false),
            subscriptionManager: SubscriptionManager(startStoreKit: false),
            recoveryPackageService: RecoveryPackageService(),
            now: Date.init,
            reloadWidgets: {}
        )
    }

    private func withSavedLedgerID(_ id: UUID, operation: () throws -> Void) rethrows {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)!
        let previousID = defaults.string(forKey: "currentLedgerId")
        defer {
            if let previousID {
                defaults.set(previousID, forKey: "currentLedgerId")
            } else {
                defaults.removeObject(forKey: "currentLedgerId")
            }
        }
        defaults.set(id.uuidString, forKey: "currentLedgerId")
        try operation()
    }
}

private struct ExistingStoreFactory: ModelContainerProviding {
    let container: ModelContainer

    @MainActor
    func makeContainer(mode: StoreMode) throws -> StoreBootstrapResult {
        StoreBootstrapResult(
            container: container,
            storeURL: nil,
            isNewStore: false,
            usesCloudKit: false
        )
    }
}
