import Foundation
import SwiftData

enum StoreMode: Equatable {
    case production
    case inMemory
    case uiTest(URL, reset: Bool)
    case recovery(URL)
}

struct StoreBootstrapResult {
    let container: ModelContainer
    let storeURL: URL?
    let isNewStore: Bool
    let usesCloudKit: Bool
}

protocol ModelContainerProviding {
    @MainActor
    func makeContainer(mode: StoreMode) throws -> StoreBootstrapResult
}

enum StoreInitializationError: LocalizedError {
    case appGroupUnavailable
    case openFailed(URL?, Error)

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable:
            return "无法访问应用数据目录。原始账本没有被修改。"
        case .openFailed(_, let error):
            return "账本暂时无法打开：\(error.localizedDescription)"
        }
    }

    var storeURL: URL? {
        switch self {
        case .appGroupUnavailable:
            return nil
        case .openFailed(let url, _):
            return url
        }
    }
}

struct ModelContainerFactory: ModelContainerProviding {
    static let schema = Schema([
        Ledger.self,
        Account.self,
        Category.self,
        Transaction.self,
        Budget.self,
        Tag.self
    ])

    @MainActor
    func makeContainer(mode: StoreMode) throws -> StoreBootstrapResult {
        switch mode {
        case .inMemory:
            let configuration = ModelConfiguration(
                schema: Self.schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            return try open(configuration: configuration, url: nil, isNewStore: true, usesCloudKit: false)

        case .production:
            guard let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
            ) else {
                throw StoreInitializationError.appGroupUnavailable
            }
            let storeURL = containerURL.appendingPathComponent("jizhang.sqlite")
            let isNewStore = !FileManager.default.fileExists(atPath: storeURL.path)
            let usesCloudKit = FileManager.default.ubiquityIdentityToken != nil
            let configuration = ModelConfiguration(
                schema: Self.schema,
                url: storeURL,
                cloudKitDatabase: usesCloudKit ? .automatic : .none
            )
            return try open(
                configuration: configuration,
                url: storeURL,
                isNewStore: isNewStore,
                usesCloudKit: usesCloudKit
            )

        case .uiTest(let storeURL, let reset):
            if reset {
                removeTestStoreFiles(at: storeURL)
            }
            let isNewStore = !FileManager.default.fileExists(atPath: storeURL.path)
            let configuration = ModelConfiguration(
                schema: Self.schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            return try open(
                configuration: configuration,
                url: storeURL,
                isNewStore: isNewStore,
                usesCloudKit: false
            )

        case .recovery(let storeURL):
            let configuration = ModelConfiguration(
                schema: Self.schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            return try open(
                configuration: configuration,
                url: storeURL,
                isNewStore: false,
                usesCloudKit: false
            )
        }
    }

    @MainActor
    private func open(
        configuration: ModelConfiguration,
        url: URL?,
        isNewStore: Bool,
        usesCloudKit: Bool
    ) throws -> StoreBootstrapResult {
        do {
            let container = try ModelContainer(
                for: Self.schema,
                configurations: [configuration]
            )
            return StoreBootstrapResult(
                container: container,
                storeURL: url,
                isNewStore: isNewStore,
                usesCloudKit: usesCloudKit
            )
        } catch {
            throw StoreInitializationError.openFailed(url, error)
        }
    }

    private func removeTestStoreFiles(at storeURL: URL) {
        let urls = [
            storeURL,
            storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm"),
            storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        ]
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
