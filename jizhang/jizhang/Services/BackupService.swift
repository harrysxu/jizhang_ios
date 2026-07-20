import Foundation
import SwiftData

@MainActor
protocol BackupServicing {
    func export(ledger: Ledger) throws -> Data
    func preflight(_ data: Data) throws -> ImportPreview
    func importValidated(_ data: Data, newName: String?) throws -> Ledger
}

@MainActor
final class BackupService: BackupServicing {
    private let exportService: LedgerExportService
    private let importService: LedgerImportService

    init(modelContext: ModelContext) {
        exportService = LedgerExportService()
        importService = LedgerImportService(modelContext: modelContext)
    }

    func export(ledger: Ledger) throws -> Data {
        try exportService.export(ledger: ledger)
    }

    func preflight(_ data: Data) throws -> ImportPreview {
        try importService.preview(from: data)
    }

    func importValidated(_ data: Data, newName: String? = nil) throws -> Ledger {
        try importService.importLedger(from: data, newName: newName)
    }
}

@MainActor
protocol DataIntegrityInspecting {
    func report() throws -> DataIntegrityReport
}

@MainActor
struct DataIntegrityInspector: DataIntegrityInspecting {
    let modelContext: ModelContext

    func report() throws -> DataIntegrityReport {
        try DataMigration.inspect(context: modelContext)
    }
}
