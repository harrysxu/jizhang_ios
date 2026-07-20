import Foundation
import SwiftUI
import SwiftData

enum LaunchState: Equatable {
    case launching
    case ready
    case failed(message: String, storeURL: URL?)
}

@MainActor
@Observable
final class AppState {
    var currentLedger: Ledger? {
        didSet {
            if let ledger = currentLedger, ledger.id != oldValue?.id {
                saveCurrentLedgerID()
                applyTheme(ledger)
            }
        }
    }

    var showLedgerDrawer = false
    var isFirstLaunch = true
    var launchState: LaunchState = .launching
    var shouldShowNewUserSetup = false
    var shouldShowUpdateSummary = false
    private(set) var modelContainer: ModelContainer?
    private(set) var storeURL: URL?
    private(set) var usesCloudKit = false
    private(set) var transactionService: (any TransactionServicing)?
    private(set) var budgetCalculator: (any BudgetCalculating)?
    private(set) var backupService: (any BackupServicing)?
    private(set) var dataIntegrityInspector: (any DataIntegrityInspecting)?
    var pendingTransactionUndo: UndoToken?
    var recentlyCreatedTransactionID: UUID?

    let cloudKitService: CloudKitService
    let subscriptionManager: SubscriptionManager
    let environment: AppEnvironment

    convenience init() {
        self.init(environment: .automatic())
    }

    init(environment: AppEnvironment) {
        self.environment = environment
        self.cloudKitService = environment.cloudKitService
        self.subscriptionManager = environment.subscriptionManager

        let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        isFirstLaunch = sharedDefaults?.bool(forKey: "hasLaunched") != true

        openStore()
        subscriptionManager.loadStatusFromCache()
    }

    func retryOpenStore() {
        launchState = .launching
        openStore()
    }

    func offerUndo(_ token: UndoToken) {
        pendingTransactionUndo = token
        Task { @MainActor [weak self] in
            let delay = max(token.expiresAt.timeIntervalSinceNow, 0)
            try? await Task.sleep(for: .seconds(delay))
            guard self?.pendingTransactionUndo?.expiresAt == token.expiresAt else { return }
            self?.pendingTransactionUndo = nil
        }
    }

    func undoPendingTransactionDeletion() throws {
        guard let token = pendingTransactionUndo,
              let transactionService else { return }
        _ = try transactionService.undo(token)
        pendingTransactionUndo = nil
    }

    func offerUndoForCreatedTransaction(_ receipt: TransactionReceipt) {
        recentlyCreatedTransactionID = receipt.transactionID
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard self?.recentlyCreatedTransactionID == receipt.transactionID else { return }
            self?.recentlyCreatedTransactionID = nil
        }
    }

    func undoRecentlyCreatedTransaction() throws {
        guard let id = recentlyCreatedTransactionID,
              let transactionService else { return }
        _ = try transactionService.delete(id: id)
        recentlyCreatedTransactionID = nil
    }

    private func openStore() {
        do {
            let result = try environment.containerFactory.makeContainer(mode: environment.storeMode)
            modelContainer = result.container
            storeURL = result.storeURL
            usesCloudKit = result.usesCloudKit
            transactionService = TransactionService(
                modelContext: result.container.mainContext,
                now: environment.now,
                reloadWidgets: environment.reloadWidgets
            )
            budgetCalculator = BudgetCalculator(modelContext: result.container.mainContext)
            backupService = BackupService(modelContext: result.container.mainContext)
            dataIntegrityInspector = DataIntegrityInspector(modelContext: result.container.mainContext)

            if result.isNewStore {
                let ledger = try DataInitializer(
                    modelContext: result.container.mainContext
                ).initializeDefaultData()
                ledger.isDefault = true
                try result.container.mainContext.save()
                currentLedger = ledger
                if ProcessInfo.processInfo.arguments.contains("--existing-user") {
                    shouldShowUpdateSummary = !ProcessInfo.processInfo.arguments
                        .contains("--skip-update-summary")
                } else {
                    shouldShowNewUserSetup = true
                }
            } else {
                currentLedger = loadDefaultLedger(in: result.container.mainContext)
                let seenVersion = UserDefaults(suiteName: AppConstants.appGroupIdentifier)?
                    .string(forKey: "lastSeenUpdateSummaryVersion")
                shouldShowUpdateSummary = seenVersion != "2.0"
            }

            UserDefaults(suiteName: AppConstants.appGroupIdentifier)?
                .set(true, forKey: "hasLaunched")
            launchState = .ready
        } catch {
            modelContainer = nil
            transactionService = nil
            budgetCalculator = nil
            backupService = nil
            dataIntegrityInspector = nil
            let initializationError = error as? StoreInitializationError
            storeURL = initializationError?.storeURL
            launchState = .failed(
                message: error.localizedDescription,
                storeURL: initializationError?.storeURL
            )
        }
    }

    func completeNewUserSetup() {
        shouldShowNewUserSetup = false
    }

    func dismissUpdateSummary() {
        UserDefaults(suiteName: AppConstants.appGroupIdentifier)?
            .set("2.0", forKey: "lastSeenUpdateSummaryVersion")
        shouldShowUpdateSummary = false
    }

    func saveCurrentLedgerID() {
        guard let ledgerID = currentLedger?.id else { return }
        UserDefaults(suiteName: AppConstants.appGroupIdentifier)?
            .set(ledgerID.uuidString, forKey: "currentLedgerId")
    }

    func loadDefaultLedger() -> Ledger? {
        guard let context = modelContainer?.mainContext else { return nil }
        return loadDefaultLedger(in: context)
    }

    private func loadDefaultLedger(in context: ModelContext) -> Ledger? {
        if let savedLedgerID = UserDefaults(suiteName: AppConstants.appGroupIdentifier)?
            .string(forKey: "currentLedgerId"),
           let uuid = UUID(uuidString: savedLedgerID) {
            let descriptor = FetchDescriptor<Ledger>(
                predicate: #Predicate { $0.id == uuid && $0.isArchived == false }
            )
            if let ledger = try? context.fetch(descriptor).first {
                return ledger
            }
        }

        let defaultDescriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { $0.isDefault == true && $0.isArchived == false }
        )
        if let ledger = try? context.fetch(defaultDescriptor).first {
            return ledger
        }

        let firstDescriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { $0.isArchived == false },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try? context.fetch(firstDescriptor).first
    }

    func validateCurrentLedger() {
        guard let context = modelContainer?.mainContext else { return }
        guard let currentLedger else {
            self.currentLedger = loadDefaultLedger(in: context)
            return
        }

        let ledgerID = currentLedger.id
        let descriptor = FetchDescriptor<Ledger>(
            predicate: #Predicate { $0.id == ledgerID }
        )
        guard let storedLedger = try? context.fetch(descriptor).first,
              !storedLedger.isArchived else {
            self.currentLedger = loadDefaultLedger(in: context)
            return
        }
        self.currentLedger = storedLedger
    }

    private func applyTheme(_ ledger: Ledger) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        windowScene.windows.forEach { window in
            window.tintColor = UIColor(hexString: ledger.colorHex)
        }
    }
}

extension UIColor {
    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else { return nil }
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255,
            blue: CGFloat(rgb & 0x0000FF) / 255,
            alpha: 1
        )
    }
}
