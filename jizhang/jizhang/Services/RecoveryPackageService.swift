import Foundation

enum RecoveryPackageError: LocalizedError {
    case storeUnavailable
    case noStoreFiles

    var errorDescription: String? {
        switch self {
        case .storeUnavailable:
            return "没有可导出的原始数据路径。"
        case .noStoreFiles:
            return "没有找到可导出的原始数据文件。"
        }
    }
}

struct RecoveryPackageService {
    func createPackage(storeURL: URL?) throws -> URL {
        guard let storeURL else { throw RecoveryPackageError.storeUnavailable }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let packageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("简记账恢复包-\(formatter.string(from: Date())).jizhang-recovery", isDirectory: true)

        try FileManager.default.createDirectory(
            at: packageURL,
            withIntermediateDirectories: true
        )

        let sourceURLs = [
            storeURL,
            storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal"),
            storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
        ]
        var copiedCount = 0

        for sourceURL in sourceURLs where FileManager.default.fileExists(atPath: sourceURL.path) {
            let destinationURL = packageURL.appendingPathComponent(sourceURL.lastPathComponent)
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            copiedCount += 1
        }

        guard copiedCount > 0 else {
            try? FileManager.default.removeItem(at: packageURL)
            throw RecoveryPackageError.noStoreFiles
        }

        let diagnostics = """
        appVersion=\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown")
        build=\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown")
        createdAt=\(ISO8601DateFormatter().string(from: Date()))
        files=\(copiedCount)
        """
        try diagnostics.write(
            to: packageURL.appendingPathComponent("diagnostics.txt"),
            atomically: true,
            encoding: .utf8
        )

        return packageURL
    }
}
