import XCTest
import SwiftData
@testable import jizhang

@MainActor
final class BackupCompatibilityTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var ledger: Ledger!
    private var account: Account!
    private var category: jizhang.Category!

    override func setUpWithError() throws {
        container = try TestHelpers.createInMemoryContainer()
        context = ModelContext(container)
        ledger = TestHelpers.createTestLedger(name: "家庭账本", context: context)
        account = TestHelpers.createTestAccount(
            ledger: ledger,
            name: "=危险账户",
            balance: 900,
            context: context
        )
        category = jizhang.Category(
            ledger: ledger,
            name: "餐饮,外卖",
            type: .expense
        )
        context.insert(category)
        let transaction = Transaction(
            ledger: ledger,
            amount: 100,
            date: Date(timeIntervalSince1970: 1_780_000_000),
            type: .expense,
            fromAccount: account,
            category: category,
            note: "第一行\n\"第二行\""
        )
        context.insert(transaction)
        context.insert(Budget(
            ledger: ledger,
            category: category,
            amount: 1_000,
            period: .custom,
            startDate: Date(timeIntervalSince1970: 1_779_000_000),
            endDate: Date(timeIntervalSince1970: 1_789_000_000)
        ))
        try context.save()
    }

    override func tearDown() {
        category = nil
        account = nil
        ledger = nil
        context = nil
        container = nil
    }

    func testVersion2RoundTripPreservesCountsAndCustomBudgetEndDate() throws {
        let data = try LedgerExportService().export(ledger: ledger)
        let service = LedgerImportService(modelContext: context)

        let preview = try service.preview(from: data)
        XCTAssertEqual(preview.version, "2.0")
        XCTAssertEqual(preview.accountCount, 1)
        XCTAssertEqual(preview.transactionCount, 1)
        XCTAssertEqual(preview.budgetCount, 1)

        let imported = try service.importLedger(from: data)
        XCTAssertNotEqual(imported.id, ledger.id)
        XCTAssertEqual(imported.transactions?.count, 1)
        XCTAssertEqual(imported.budgets?.first?.endDate, Date(timeIntervalSince1970: 1_789_000_000))
    }

    func testVersion1BackupWithoutManifestRemainsReadable() throws {
        let data = try legacyData(from: LedgerExportService().export(ledger: ledger))

        let preview = try LedgerImportService(modelContext: context).preview(from: data)

        XCTAssertEqual(preview.version, "1.0")
        XCTAssertEqual(preview.ledgerName, "家庭账本")
    }

    func testUnknownVersionIsRejected() throws {
        var object = try jsonObject(from: LedgerExportService().export(ledger: ledger))
        object["version"] = "99.0"
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try LedgerImportService(modelContext: context).preview(from: data)) { error in
            guard case LedgerImportError.invalidVersion("99.0") = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testChecksumDetectsModifiedPayload() throws {
        var object = try jsonObject(from: LedgerExportService().export(ledger: ledger))
        var ledgerObject = try XCTUnwrap(object["ledger"] as? [String: Any])
        ledgerObject["name"] = "被篡改"
        object["ledger"] = ledgerObject
        let data = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try LedgerImportService(modelContext: context).preview(from: data)) { error in
            guard case LedgerImportError.dataCorrupted = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testMissingReferenceIsRejectedBeforeAnyWrite() throws {
        var object = try jsonObject(from: try legacyData(from: LedgerExportService().export(ledger: ledger)))
        var transactions = try XCTUnwrap(object["transactions"] as? [[String: Any]])
        transactions[0]["fromAccountId"] = UUID().uuidString
        object["transactions"] = transactions
        let data = try JSONSerialization.data(withJSONObject: object)
        let ledgerCount = try context.fetchCount(FetchDescriptor<Ledger>())

        XCTAssertThrowsError(try LedgerImportService(modelContext: context).importLedger(from: data))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Ledger>()), ledgerCount)
    }

    func testCSVUsesRFC4180EscapingPOSIXAmountsAndFormulaProtection() throws {
        let transaction = try XCTUnwrap(ledger.transactions?.first)

        let csv = CSVExporter.export(transactions: [transaction])

        XCTAssertTrue(csv.contains("100.00"))
        XCTAssertTrue(csv.contains("\"餐饮,外卖\""))
        XCTAssertTrue(csv.contains("'=危险账户"))
        XCTAssertTrue(csv.contains("\"第一行\r\n\"\"第二行\"\"\"\r\n") ||
                      csv.contains("\"第一行\n\"\"第二行\"\"\"\r\n"))
    }

    private func legacyData(from data: Data) throws -> Data {
        var object = try jsonObject(from: data)
        object["version"] = "1.0"
        object.removeValue(forKey: "checksum")
        object.removeValue(forKey: "manifest")
        return try JSONSerialization.data(withJSONObject: object)
    }

    private func jsonObject(from data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
