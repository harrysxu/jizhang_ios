//
//  UITestHelpers.swift
//  jizhangUITests
//
//  Created by Test Suite on 2026/1/31.
//

import XCTest

/// UI测试辅助工具类
class UITestHelpers {
    
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    // MARK: - App Launch
    
    /// 启动应用（重置状态）
    func launchApp(resetState: Bool = true) {
        if resetState {
            app.launchArguments = ["--uitesting", "--reset"]
        }
        app.launch()
    }
    
    // MARK: - Navigation
    
    /// 切换到指定Tab
    func switchToTab(_ tabName: String) {
        let tabBar = app.tabBars.firstMatch
        let tab = tabBar.buttons[tabName]
        
        if tab.exists {
            tab.tap()
        }
    }
    
    /// 点击导航栏按钮
    func tapNavigationButton(_ title: String) {
        let button = app.navigationBars.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "导航按钮 '\(title)' 不存在")
        button.tap()
    }
    
    /// 返回上一页
    func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
    
    // MARK: - Input
    
    /// 输入文本
    func enterText(_ text: String, inField fieldIdentifier: String) {
        let textField = app.textFields[fieldIdentifier]
        XCTAssertTrue(textField.waitForExistence(timeout: 3), "文本框 '\(fieldIdentifier)' 不存在")
        
        textField.tap()
        textField.typeText(text)
    }
    
    /// 输入金额
    func enterAmount(_ amount: String) {
        // 假设金额输入框有特定的标识符
        let amountField = app.textFields["AmountInput"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 3), "金额输入框不存在")
        
        amountField.tap()
        
        // 逐个输入数字
        for char in amount {
            if char == "." {
                app.buttons["小数点"].tap()
            } else if let digit = Int(String(char)) {
                app.buttons[String(digit)].tap()
            }
        }
    }
    
    // MARK: - Buttons
    
    /// 点击按钮
    func tapButton(_ title: String) {
        let button = app.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: 3), "按钮 '\(title)' 不存在")
        button.tap()
    }
    
    /// 点击第一个匹配的按钮
    func tapFirstButton(containing text: String) {
        let button = app.buttons.containing(.any, identifier: text).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 3), "包含 '\(text)' 的按钮不存在")
        button.tap()
    }
    
    // MARK: - Alerts
    
    /// 确认弹窗
    func confirmAlert(timeout: TimeInterval = 3) {
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: timeout), "弹窗不存在")
        
        let confirmButton = alert.buttons["确定"].firstMatch
        if confirmButton.exists {
            confirmButton.tap()
        } else {
            alert.buttons.element(boundBy: 1).tap()
        }
    }
    
    /// 取消弹窗
    func cancelAlert(timeout: TimeInterval = 3) {
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: timeout), "弹窗不存在")
        
        let cancelButton = alert.buttons["取消"].firstMatch
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            alert.buttons.element(boundBy: 0).tap()
        }
    }
    
    // MARK: - Lists
    
    /// 滚动到指定元素
    func scrollTo(_ element: XCUIElement, in scrollView: XCUIElement? = nil) {
        let targetScrollView = scrollView ?? app.scrollViews.firstMatch
        
        var attempts = 0
        let maxAttempts = 10
        
        while !element.isHittable && attempts < maxAttempts {
            targetScrollView.swipeUp()
            attempts += 1
        }
        
        XCTAssertTrue(element.isHittable, "无法滚动到目标元素")
    }
    
    /// 选择列表项
    func selectListItem(_ title: String) {
        let cell = app.cells.containing(.any, identifier: title).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 3), "列表项 '\(title)' 不存在")
        cell.tap()
    }
    
    // MARK: - Sheets & Pickers
    
    /// 关闭Sheet
    func dismissSheet() {
        // 向下滑动关闭
        let sheet = app.sheets.firstMatch
        if sheet.exists {
            sheet.swipeDown()
        }
    }
    
    /// 选择Picker值
    func selectPickerValue(_ value: String) {
        let picker = app.pickers.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 3), "选择器不存在")
        
        let pickerWheel = picker.pickerWheels.firstMatch
        pickerWheel.adjust(toPickerWheelValue: value)
    }
    
    // MARK: - Wait & Verify
    
    /// 等待元素出现
    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    /// 等待文本出现
    @discardableResult
    func waitForText(_ text: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        let element = app.staticTexts.containing(predicate).firstMatch
        return element.waitForExistence(timeout: timeout)
    }
    
    /// 验证文本存在
    func verifyTextExists(_ text: String, timeout: TimeInterval = 3) {
        XCTAssertTrue(
            waitForText(text, timeout: timeout),
            "文本 '\(text)' 不存在"
        )
    }
    
    /// 验证元素不存在
    func verifyElementDoesNotExist(_ element: XCUIElement, timeout: TimeInterval = 1) {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertFalse(exists, "元素不应该存在")
    }
    
    // MARK: - Transaction Helpers
    
    /// 添加交易（简化流程）
    func addExpense(amount: String, category: String, account: String = "现金") {
        // 点击添加按钮
        tapButton("添加")
        
        // 选择交易类型
        tapButton("支出")
        
        // 输入金额
        enterAmount(amount)
        
        // 选择分类
        tapButton("选择分类")
        selectListItem(category)
        
        // 选择账户
        tapButton("选择账户")
        selectListItem(account)
        
        // 保存
        tapButton("保存")
    }
    
    // MARK: - Screenshot
    
    /// 截图（用于调试）
    func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "截图: \(name)") { activity in
            activity.add(attachment)
        }
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// 强制点击（即使不可见）
    func forceTap() {
        if isHittable {
            tap()
        } else {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
    
    /// 清除文本
    func clearText() {
        guard let stringValue = value as? String else {
            return
        }
        
        tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
