import Foundation
import WidgetKit

private struct UITestFailingContainerFactory: ModelContainerProviding {
    @MainActor
    func makeContainer(mode: StoreMode) throws -> StoreBootstrapResult {
        let url = URL(fileURLWithPath: "/ui-test/recovery-store.sqlite")
        throw StoreInitializationError.openFailed(
            url,
            NSError(domain: "UITestStore", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "模拟账本打开失败"
            ])
        )
    }
}

@MainActor
struct AppEnvironment {
    let containerFactory: any ModelContainerProviding
    let storeMode: StoreMode
    let cloudKitService: CloudKitService
    let subscriptionManager: SubscriptionManager
    let recoveryPackageService: RecoveryPackageService
    let now: () -> Date
    let reloadWidgets: () -> Void

    static func automatic() -> AppEnvironment {
        let processInfo = ProcessInfo.processInfo
        let arguments = processInfo.arguments
        let isPreview = processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        let isUnitTest = NSClassFromString("XCTestCase") != nil

        if isPreview || isUnitTest {
            return AppEnvironment(
                containerFactory: ModelContainerFactory(),
                storeMode: .inMemory,
                cloudKitService: CloudKitService(container: nil, startMonitoring: false),
                subscriptionManager: SubscriptionManager(startStoreKit: false),
                recoveryPackageService: RecoveryPackageService(),
                now: Date.init,
                reloadWidgets: {}
            )
        }

        #if DEBUG
        if arguments.contains("--upgrade-local-only") {
            guard let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
            ) else {
                return AppEnvironment(
                    containerFactory: ModelContainerFactory(),
                    storeMode: .recovery(URL(fileURLWithPath: "/upgrade-test/unavailable.sqlite")),
                    cloudKitService: CloudKitService(container: nil, startMonitoring: false),
                    subscriptionManager: SubscriptionManager(startStoreKit: false),
                    recoveryPackageService: RecoveryPackageService(),
                    now: Date.init,
                    reloadWidgets: {}
                )
            }
            let storeURL = containerURL.appendingPathComponent("upgrade-test.sqlite")
            return AppEnvironment(
                containerFactory: ModelContainerFactory(),
                storeMode: .uiTest(storeURL, reset: arguments.contains("--reset")),
                cloudKitService: CloudKitService(container: nil, startMonitoring: false),
                subscriptionManager: SubscriptionManager(startStoreKit: false),
                recoveryPackageService: RecoveryPackageService(),
                now: Date.init,
                reloadWidgets: {}
            )
        }
        #endif

        if arguments.contains("--uitesting") {
            if arguments.contains("--recovery-test") {
                return AppEnvironment(
                    containerFactory: UITestFailingContainerFactory(),
                    storeMode: .recovery(URL(fileURLWithPath: "/ui-test/recovery-store.sqlite")),
                    cloudKitService: CloudKitService(container: nil, startMonitoring: false),
                    subscriptionManager: SubscriptionManager(startStoreKit: false),
                    recoveryPackageService: RecoveryPackageService(),
                    now: Date.init,
                    reloadWidgets: {}
                )
            }
            let storeURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("jizhang-uitest.sqlite")
            return AppEnvironment(
                containerFactory: ModelContainerFactory(),
                storeMode: .uiTest(storeURL, reset: arguments.contains("--reset")),
                cloudKitService: CloudKitService(container: nil, startMonitoring: false),
                subscriptionManager: SubscriptionManager(startStoreKit: false),
                recoveryPackageService: RecoveryPackageService(),
                now: Date.init,
                reloadWidgets: {}
            )
        }

        return AppEnvironment(
            containerFactory: ModelContainerFactory(),
            storeMode: .production,
            cloudKitService: CloudKitService(),
            subscriptionManager: SubscriptionManager(),
            recoveryPackageService: RecoveryPackageService(),
            now: Date.init,
            reloadWidgets: { WidgetCenter.shared.reloadAllTimelines() }
        )
    }
}
