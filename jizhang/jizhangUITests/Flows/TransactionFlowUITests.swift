import XCTest

@MainActor
final class TransactionFlowUITests: XCTestCase {
    private var app: XCUIApplication!
    private var helper: UITestHelpers!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        helper = UITestHelpers(app: app)
        helper.launchApp(resetState: true)
    }

    override func tearDownWithError() throws {
        app = nil
        helper = nil
    }

    func testAddExpenseTransaction() throws {
        openAddTransaction()
        helper.enterAmount("50")
        app.buttons["保存"].tap()

        XCTAssertTrue(app.staticTexts["流水已保存"].waitForExistence(timeout: 5))
        app.buttons["流水"].tap()
        XCTAssertTrue(amountText(containing: "50").waitForExistence(timeout: 5))
    }

    func testAddIncomeTransaction() throws {
        openAddTransaction()
        app.buttons["收入"].tap()
        helper.enterAmount("5000")
        app.buttons["保存"].tap()

        XCTAssertTrue(app.staticTexts["流水已保存"].waitForExistence(timeout: 5))
        app.buttons["流水"].tap()
        XCTAssertTrue(amountText(containing: "5,000").waitForExistence(timeout: 5))
    }

    func testAddTransferTransaction() throws {
        openAddTransaction()
        app.buttons["转账"].tap()
        helper.enterAmount("100")

        let destination = app.buttons["transaction.selection.转入账户"]
        XCTAssertTrue(destination.waitForExistence(timeout: 3))
        destination.tap()
        let destinationAccount = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "account.picker.")
        ).firstMatch
        XCTAssertTrue(destinationAccount.waitForExistence(timeout: 3))
        destinationAccount.tap()

        app.buttons["保存"].tap()
        XCTAssertTrue(app.staticTexts["流水已保存"].waitForExistence(timeout: 5))
        app.buttons["流水"].tap()
        XCTAssertTrue(app.staticTexts["转账"].waitForExistence(timeout: 5))
        XCTAssertTrue(amountText(containing: "100").exists)
    }

    func testEditTransaction() throws {
        createExpense(amount: "42")
        openNewestTransaction()
        XCTAssertTrue(app.staticTexts["交易详情"].waitForExistence(timeout: 3))

        app.buttons["编辑"].tap()
        let amount = app.textFields["transaction.amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 3))
        amount.tap()
        let clearAmount = app.buttons["transaction.amount.clear"]
        XCTAssertTrue(clearAmount.waitForExistence(timeout: 3))
        clearAmount.tap()
        let amountIsEmpty = NSPredicate { _, _ in
            guard let value = amount.value as? String else { return true }
            return value.isEmpty || value == "0"
        }
        expectation(for: amountIsEmpty, evaluatedWith: amount)
        waitForExpectations(timeout: 3)
        amount.typeText("84")
        XCTAssertEqual(amount.value as? String, "84")
        dismissAmountKeyboard()
        app.buttons["确认修改"].tap()

        XCTAssertTrue(amountText(containing: "84").waitForExistence(timeout: 5))
    }

    func testDeleteAndUndoTransaction() throws {
        createExpense(amount: "36")
        openNewestTransaction()
        app.buttons["删除交易"].tap()
        XCTAssertTrue(app.alerts["确认删除"].waitForExistence(timeout: 3))
        app.alerts["确认删除"].buttons["删除"].tap()

        XCTAssertTrue(app.staticTexts["流水已删除"].waitForExistence(timeout: 5))
        app.buttons["撤销"].tap()
        XCTAssertTrue(amountText(containing: "36").waitForExistence(timeout: 5))
    }

    func testCategorySelection() throws {
        openAddTransaction()
        let category = app.buttons["transaction.selection.分类"]
        XCTAssertTrue(category.waitForExistence(timeout: 3))
        category.tap()

        XCTAssertTrue(app.staticTexts["选择分类"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["午餐"].waitForExistence(timeout: 3))
        app.buttons["午餐"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "午餐")).firstMatch.waitForExistence(timeout: 3))
    }

    func testDateSelectionPage() throws {
        openAddTransaction()
        app.buttons["更多字段"].tap()
        let date = app.buttons["transaction.selection.日期"]
        XCTAssertTrue(date.waitForExistence(timeout: 3))
        date.tap()
        XCTAssertTrue(app.navigationBars["选择日期"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.datePickers.firstMatch.exists)
    }

    func testNoteInput() throws {
        openAddTransaction()
        app.buttons["更多字段"].tap()
        let note = app.buttons["transaction.selection.备注"]
        XCTAssertTrue(note.waitForExistence(timeout: 3))
        note.tap()

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.typeText("UI自动化备注")
        app.buttons["完成"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "UI自动化备注")).firstMatch.waitForExistence(timeout: 3))
    }

    private func openAddTransaction() {
        let add = app.buttons["tab.addTransaction"]
        XCTAssertTrue(add.waitForExistence(timeout: 3))
        add.tap()
        XCTAssertTrue(app.textFields["transaction.amount"].waitForExistence(timeout: 3))
    }

    private func createExpense(amount: String) {
        openAddTransaction()
        helper.enterAmount(amount)
        app.buttons["保存"].tap()
        XCTAssertTrue(app.staticTexts["流水已保存"].waitForExistence(timeout: 5))
        app.buttons["流水"].tap()
        XCTAssertTrue(amountText(containing: amount).waitForExistence(timeout: 5))
    }

    private func openNewestTransaction() {
        let row = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "transaction.row.")
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        row.tap()
    }

    private func amountText(containing value: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", value)).firstMatch
    }

    private func dismissAmountKeyboard() {
        let done = app.buttons["transaction.amount.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 2))
        done.tap()
    }
}
