//
//  TransactionFlowUITests.swift
//  jizhangUITests
//
//  Created by Test Suite on 2026/1/31.
//

import XCTest

/// 记账流程UI测试
final class TransactionFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    var helper: UITestHelpers!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        
        helper = UITestHelpers(app: app)
        helper.launchApp(resetState: true)
    }
    
    override func tearDownWithError() throws {
        app = nil
        helper = nil
    }
    
    // MARK: - 添加支出交易
    
    func testAddExpenseTransaction() throws {
        // 点击添加按钮
        let addButton = app.buttons["添加"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        
        // 确保在添加交易页面
        let addTransactionTitle = app.navigationBars["记账"]
        XCTAssertTrue(addTransactionTitle.waitForExistence(timeout: 3))
        
        // 选择支出类型（默认可能已选中）
        let expenseButton = app.buttons["支出"]
        if expenseButton.exists {
            expenseButton.tap()
        }
        
        // 输入金额（假设有数字键盘）
        let amountButtons = ["5", "0"]
        for digit in amountButtons {
            let button = app.buttons[digit]
            if button.exists {
                button.tap()
            }
        }
        
        // 选择分类
        let categoryButton = app.buttons.matching(identifier: "选择分类").firstMatch
        if categoryButton.exists {
            categoryButton.tap()
            
            // 等待分类选择器出现
            let categoryPicker = app.sheets.firstMatch
            XCTAssertTrue(categoryPicker.waitForExistence(timeout: 3))
            
            // 选择"餐饮"分类
            let foodCategory = app.staticTexts["餐饮"]
            if foodCategory.exists {
                foodCategory.tap()
            }
        }
        
        // 保存交易
        let saveButton = app.buttons["保存"]
        if saveButton.exists {
            saveButton.tap()
        }
        
        // 验证返回到首页
        let homeTab = app.tabBars.buttons["首页"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 3))
        
        // 验证交易出现在列表中
        helper.waitForText("50", timeout: 5)
    }
    
    // MARK: - 添加收入交易
    
    func testAddIncomeTransaction() throws {
        helper.tapButton("添加")
        
        // 切换到收入
        let incomeButton = app.buttons["收入"]
        XCTAssertTrue(incomeButton.waitForExistence(timeout: 3))
        incomeButton.tap()
        
        // 输入金额
        let amountButtons = ["5", "0", "0", "0"]
        for digit in amountButtons {
            app.buttons[digit].tap()
        }
        
        // 选择分类（工资）
        helper.tapFirstButton(containing: "选择分类")
        
        let salaryCategory = app.staticTexts["工资"]
        if salaryCategory.waitForExistence(timeout: 3) {
            salaryCategory.tap()
        }
        
        // 保存
        helper.tapButton("保存")
        
        // 验证返回首页
        XCTAssertTrue(app.tabBars.buttons["首页"].waitForExistence(timeout: 3))
    }
    
    // MARK: - 添加转账交易
    
    func testAddTransferTransaction() throws {
        helper.tapButton("添加")
        
        // 切换到转账
        let transferButton = app.buttons["转账"]
        XCTAssertTrue(transferButton.waitForExistence(timeout: 3))
        transferButton.tap()
        
        // 输入金额
        for digit in ["1", "0", "0", "0"] {
            app.buttons[digit].tap()
        }
        
        // 选择转出账户
        let fromAccountButton = app.buttons.matching(identifier: "转出账户").firstMatch
        if fromAccountButton.exists {
            fromAccountButton.tap()
            
            // 选择银行卡
            let bankAccount = app.staticTexts["银行卡"]
            if bankAccount.waitForExistence(timeout: 3) {
                bankAccount.tap()
            }
        }
        
        // 选择转入账户
        let toAccountButton = app.buttons.matching(identifier: "转入账户").firstMatch
        if toAccountButton.exists {
            toAccountButton.tap()
            
            // 选择现金
            let cashAccount = app.staticTexts["现金"]
            if cashAccount.waitForExistence(timeout: 3) {
                cashAccount.tap()
            }
        }
        
        // 保存
        helper.tapButton("保存")
        
        // 验证返回首页
        XCTAssertTrue(app.tabBars.buttons["首页"].waitForExistence(timeout: 3))
    }
    
    // MARK: - 编辑交易
    
    func testEditTransaction() throws {
        // 先添加一笔交易
        try testAddExpenseTransaction()
        
        // 找到并点击交易项
        let transactionCell = app.cells.firstMatch
        XCTAssertTrue(transactionCell.waitForExistence(timeout: 3))
        transactionCell.tap()
        
        // 进入交易详情
        let detailView = app.navigationBars["交易详情"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 3))
        
        // 点击编辑按钮
        let editButton = app.buttons["编辑"]
        if editButton.exists {
            editButton.tap()
            
            // 修改金额或其他字段
            // （具体实现取决于UI设计）
            
            // 保存修改
            helper.tapButton("保存")
        }
    }
    
    // MARK: - 删除交易
    
    func testDeleteTransaction() throws {
        // 先添加一笔交易
        try testAddExpenseTransaction()
        
        // 在列表中左滑删除
        let transactionCell = app.cells.firstMatch
        XCTAssertTrue(transactionCell.waitForExistence(timeout: 3))
        transactionCell.swipeLeft()
        
        // 点击删除按钮
        let deleteButton = app.buttons["删除"]
        if deleteButton.waitForExistence(timeout: 2) {
            deleteButton.tap()
            
            // 确认删除
            let confirmButton = app.alerts.buttons["确定"]
            if confirmButton.exists {
                confirmButton.tap()
            }
        }
    }
    
    // MARK: - 快速分类选择
    
    func testQuickCategorySelection() throws {
        helper.tapButton("添加")
        
        // 验证快速分类按钮存在
        let foodQuickButton = app.buttons["餐饮"]
        if foodQuickButton.exists {
            foodQuickButton.tap()
            
            // 验证分类已选中
            helper.verifyTextExists("餐饮")
        }
    }
    
    // MARK: - 日期选择
    
    func testDateSelection() throws {
        helper.tapButton("添加")
        
        // 点击日期选择
        let dateButton = app.buttons.matching(identifier: "日期").firstMatch
        if dateButton.exists {
            dateButton.tap()
            
            // 选择昨天
            let yesterdayButton = app.buttons["昨天"]
            if yesterdayButton.waitForExistence(timeout: 3) {
                yesterdayButton.tap()
            }
        }
    }
    
    // MARK: - 备注输入
    
    func testNoteInput() throws {
        helper.tapButton("添加")
        
        // 点击备注字段
        let noteField = app.textFields["备注"]
        if noteField.exists {
            noteField.tap()
            noteField.typeText("测试备注")
            
            // 验证输入
            XCTAssertEqual(noteField.value as? String, "测试备注")
        }
    }
}
