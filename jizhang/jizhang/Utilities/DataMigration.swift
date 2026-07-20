import Foundation
import SwiftData

struct DataIntegrityReport: Equatable {
    let ledgerCount: Int
    let orphanAccountCount: Int
    let orphanCategoryCount: Int
    let orphanTransactionCount: Int
    let orphanBudgetCount: Int
    let orphanTagCount: Int

    var hasOrphanedData: Bool {
        orphanAccountCount + orphanCategoryCount + orphanTransactionCount +
        orphanBudgetCount + orphanTagCount > 0
    }
}

/// Compatibility diagnostics only. Version 2.0 never mutates relationships or
/// creates a ledger based on a timer while CloudKit may still be importing.
enum DataMigration {
    @MainActor
    static func inspect(context: ModelContext) throws -> DataIntegrityReport {
        let ledgers = try context.fetch(FetchDescriptor<Ledger>())
        let accounts = try context.fetch(FetchDescriptor<Account>())
        let categories = try context.fetch(FetchDescriptor<Category>())
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        let budgets = try context.fetch(FetchDescriptor<Budget>())
        let tags = try context.fetch(FetchDescriptor<Tag>())

        return DataIntegrityReport(
            ledgerCount: ledgers.count,
            orphanAccountCount: accounts.filter { $0.ledger == nil }.count,
            orphanCategoryCount: categories.filter { $0.ledger == nil }.count,
            orphanTransactionCount: transactions.filter { $0.ledger == nil }.count,
            orphanBudgetCount: budgets.filter { $0.ledger == nil }.count,
            orphanTagCount: tags.filter { $0.ledger == nil }.count
        )
    }
}
