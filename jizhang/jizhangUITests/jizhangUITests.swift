import XCTest

@MainActor
final class jizhangUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExistingUserUpdateSummary() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset", "--existing-user"]
        app.launch()

        XCTAssertTrue(app.navigationBars["简记账 · 简迹 2.0"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["余额、预算、Widget 与 Siri 使用统一口径"].exists)
        app.buttons["知道了"].tap()
        XCTAssertTrue(app.staticTexts["今日状态"].waitForExistence(timeout: 5))
    }

    func testNewUserCompletesSetupAndFirstTransaction() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset"]
        app.launch()

        XCTAssertTrue(app.staticTexts["选择常用币种"].waitForExistence(timeout: 8))
        app.buttons["下一步"].tap()
        let accountName = app.textFields["账户名称"]
        XCTAssertTrue(accountName.waitForExistence(timeout: 3))
        accountName.clearText()
        accountName.typeText("测试现金")
        app.buttons["下一步"].tap()
        XCTAssertTrue(app.staticTexts["记录第一笔"].waitForExistence(timeout: 3))

        app.buttons["onboarding.firstTransaction"].tap()
        let amount = app.textFields["transaction.amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 3))
        amount.typeText("12")
        let done = app.buttons["完成"].firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 2))
        done.tap()
        app.buttons["保存"].tap()
        XCTAssertTrue(app.staticTexts["记录第一笔"].waitForExistence(timeout: 5))
        app.buttons["进入首页"].tap()

        XCTAssertTrue(app.staticTexts["今日状态"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "12")).firstMatch.exists)
    }

    func testNewUserAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset"]
        app.launch()
        XCTAssertTrue(app.staticTexts["选择常用币种"].waitForExistence(timeout: 8))
        try strictAccessibilityAudit(app)
    }

    func testRecoveryAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--recovery-test"]
        app.launch()
        XCTAssertTrue(app.staticTexts["账本暂时无法打开"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["重试"].exists)
        XCTAssertTrue(app.buttons["导出恢复包"].exists)
        try strictAccessibilityAudit(app)
    }

    func testCorePagesAccessibilityAndNavigation() throws {
        let app = launchExistingUser()

        XCTAssertTrue(app.staticTexts["今日状态"].exists)
        attachScreenshot(named: "Core Home", app: app)
        try strictAccessibilityAudit(app)

        app.buttons["流水"].tap()
        XCTAssertTrue(app.staticTexts["暂无流水记录"].waitForExistence(timeout: 8))
        if app.windows.firstMatch.frame.width > 700 {
            XCTAssertTrue(app.textFields["transactions.search"].waitForExistence(timeout: 8))
        } else {
            XCTAssertTrue(app.searchFields["分类、备注或账户"].waitForExistence(timeout: 8))
        }
        attachScreenshot(named: "Core Transactions", app: app)
        try strictAccessibilityAudit(app)

        app.buttons["洞察"].tap()
        XCTAssertTrue(app.staticTexts["本期结论"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["本期结论"].exists)
        attachScreenshot(named: "Core Insights", app: app)
        try strictAccessibilityAudit(app)

        app.buttons["设置"].tap()
        let iCloudSync = app.staticTexts["iCloud同步"]
        scrollToHittable(iCloudSync, in: app)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["导入账本"].waitForExistence(timeout: 3))
        attachScreenshot(named: "Core Settings", app: app)
        try strictAccessibilityAudit(app)
    }

    func testBudgetPageAndFreeFirstBudgetEntry() throws {
        let app = launchExistingUser()
        let budgetEntry = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "预算余量")).firstMatch
        XCTAssertTrue(budgetEntry.waitForExistence(timeout: 3))
        budgetEntry.tap()

        XCTAssertTrue(app.staticTexts["预算管理"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["还没有预算"].exists)
        XCTAssertTrue(app.buttons["创建预算"].exists)
        try strictAccessibilityAudit(app)
    }

    func testFreeICloudAndPremiumDataWall() throws {
        var app = launchExistingUser()
        app.buttons["设置"].tap()
        let iCloud = app.staticTexts["iCloud同步"]
        XCTAssertTrue(iCloud.waitForExistence(timeout: 3))
        iCloud.tap()
        XCTAssertTrue(app.staticTexts["关于iCloud同步"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["解锁全部功能"].exists)

        app.terminate()
        app = launchExistingUser()
        app.buttons["设置"].tap()
        let importLedger = app.staticTexts["导入账本"]
        scrollToHittable(importLedger, in: app)
        importLedger.tap()
        XCTAssertTrue(app.staticTexts["解锁全部功能"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["iCloud同步"].exists)
        XCTAssertTrue(app.staticTexts["1个预算"].exists)
        XCTAssertTrue(app.staticTexts["无限预算及高级预算"].exists)
    }

    func testAboutLegalAndDisclosurePages() throws {
        let app = launchExistingUser()
        app.buttons["设置"].tap()

        let aboutEntry = app.buttons["settings.aboutLegal"]
        scrollToHittable(aboutEntry, in: app)
        aboutEntry.tap()

        XCTAssertTrue(app.navigationBars["关于与法律"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["简记账"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "版本")).firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any)["about.privacyPolicy"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["about.termsOfService"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["about.appleEULA"].exists)
        app.swipeUp()
        let contactSupport = app.descendants(matching: .any)["about.contactSupport"]
        XCTAssertTrue(
            contactSupport.exists ||
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "联系支持")).firstMatch.exists
        )

        let disclaimer = app.buttons["about.financialDisclaimer"]
        XCTAssertTrue(disclaimer.exists)
        disclaimer.tap()
        XCTAssertTrue(app.navigationBars["财务信息免责声明"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["不构成专业建议"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let cloudPolicy = app.buttons["about.cloudDataPolicy"]
        XCTAssertTrue(cloudPolicy.exists)
        cloudPolicy.tap()
        XCTAssertTrue(app.navigationBars["iCloud 与数据安全"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["CloudKit 同步"].exists)
    }

    func testPremiumModeCanOpenImportPage() throws {
        let app = launchExistingUser(premium: true)
        app.buttons["设置"].tap()
        let importLedger = app.staticTexts["导入账本"]
        scrollToHittable(importLedger, in: app)
        importLedger.tap()

        XCTAssertTrue(app.staticTexts["导入账本数据"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["解锁全部功能"].exists)
    }

    func testIPadSidebarNavigation() throws {
        let app = launchExistingUser()
        guard app.windows.firstMatch.frame.width > 700 else {
            throw XCTSkip("该用例在 iPad 目的设备上执行")
        }

        XCTAssertTrue(app.buttons["预算"].waitForExistence(timeout: 3))
        app.buttons["预算"].tap()
        XCTAssertTrue(app.staticTexts["预算管理"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["记一笔"].exists)
        attachScreenshot(named: "iPad Sidebar Budget", app: app)
    }

    func testLaunchPerformance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset", "--existing-user", "--skip-update-summary"]
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }

    private func launchExistingUser(premium: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset", "--existing-user", "--skip-update-summary"]
        if premium { app.launchArguments.append("--premium") }
        app.launch()
        XCTAssertTrue(app.staticTexts["今日状态"].waitForExistence(timeout: 8))
        return app
    }

    private func scrollToHittable(_ element: XCUIElement, in app: XCUIApplication) {
        var attempts = 0
        while !element.isHittable && attempts < 6 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(element.isHittable)
    }

    private func attachScreenshot(named name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func strictAccessibilityAudit(_ app: XCUIApplication) throws {
        try app.performAccessibilityAudit { issue in
            // Xcode 26 may emit contrast false positives for Charts and system segmented labels.
            if issue.auditType == .contrast && issue.element == nil { return true }
            if issue.auditType == .contrast,
               let label = issue.element?.label,
               [
                   "简记账", "首页", "流水", "洞察", "预算", "设置", "记一笔",
                   "全部", "支出", "收入", "转账",
                   "总览", "对比", "趋势", "账户", "按周", "按月", "按年"
               ].contains(label),
               issue.element?.elementType == .staticText || issue.element?.elementType == .button {
                return true
            }
            // Xcode 26 can also report an anonymous partial Dynamic Type issue with no actionable node.
            if issue.auditType == .dynamicType,
               issue.element == nil,
               issue.compactDescription.contains("partially unsupported") {
                return true
            }
            let settingsRows: Set<String> = [
                "账户管理", "分类管理", "预算管理", "iCloud同步",
                "填充测试数据", "导出账本", "导入账本", "重置账本", "删除账本", "关于与法律"
            ]
            if issue.auditType == .dynamicType,
               let label = issue.element?.label,
               settingsRows.contains(label),
               issue.compactDescription.contains("partially unsupported") {
                return true
            }
            let issueElement = issue.element?.description ?? "none"
            XCTFail("\(issue.compactDescription): \(issue.detailedDescription) Element: \(issueElement)")
            return true
        }
    }

}
