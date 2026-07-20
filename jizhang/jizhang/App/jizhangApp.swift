import SwiftUI
import SwiftData
import WidgetKit
import AppIntents

@main
struct jizhangApp: App {
    @State private var appState = AppState()
    @State private var showAddTransactionSheet = false
    @State private var recoveryErrorMessage: String?
    @State private var importURL: URL?
    @State private var showImportSheet = false
    @State private var showSubscriptionSheet = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        if #available(iOS 16.0, *) {
            JizhangShortcuts.updateAppShortcutParameters()
        }
    }

    var body: some Scene {
        WindowGroup {
            rootContent
                .environment(appState)
                .tint(.brandEmerald)
                .task {
                    #if DEBUG
                    await UpgradeFixtureHarness.runIfRequested(appState: appState)
                    #endif
                }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch appState.launchState {
        case .launching:
            ProgressView("正在打开账本")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .ready:
            if let container = appState.modelContainer {
                TabBarView()
                    .modelContainer(container)
                    .sheet(isPresented: $showAddTransactionSheet) {
                        AddTransactionSheet()
                            .environment(appState)
                    }
                    .sheet(isPresented: $showImportSheet) {
                        NavigationStack {
                            LedgerImportView(initialURL: importURL)
                                .environment(appState)
                        }
                    }
                    .sheet(isPresented: $showSubscriptionSheet) {
                        SubscriptionView()
                            .environment(appState)
                    }
                    .onOpenURL(perform: handleURL)
                    .onChange(of: scenePhase) { _, newPhase in
                        guard newPhase == .active else { return }
                        appState.validateCurrentLedger()
                        Task {
                            await appState.subscriptionManager.refreshStatus()
                        }
                    }
            } else {
                recoveryView(message: "ModelContainer 不可用")
            }

        case .failed(let message, let storeURL):
            recoveryView(message: recoveryErrorMessage ?? message, storeURL: storeURL)
        }
    }

    private func recoveryView(message: String, storeURL: URL? = nil) -> some View {
        DataRecoveryView(
            message: message,
            canExportRecoveryPackage: storeURL != nil,
            onRetry: {
                recoveryErrorMessage = nil
                appState.retryOpenStore()
            },
            onExportRecoveryPackage: {
                do {
                    let packageURL = try appState.environment.recoveryPackageService
                        .createPackage(storeURL: storeURL)
                    ShareUtils.share(url: packageURL)
                } catch {
                    recoveryErrorMessage = error.localizedDescription
                }
            }
        )
    }

    private func handleURL(_ url: URL) {
        if url.isFileURL || url.pathExtension.lowercased() == "jizhang" {
            guard appState.subscriptionManager.hasAccess(to: .importLedger) else {
                showSubscriptionSheet = true
                return
            }
            importURL = url
            showImportSheet = true
            return
        }
        guard url.scheme == AppConstants.urlScheme else {
            return
        }

        switch url.host {
        case "add-transaction":
            showAddTransactionSheet = true
        case "home":
            break
        default:
            break
        }
    }
}

func refreshAllWidgets() {
    WidgetCenter.shared.reloadAllTimelines()
}
