//
//  XCUIElementExtensions.swift
//  jizhangUITests
//
//  Created by Test Suite on 2026/1/31.
//

import XCTest

extension XCUIElement {
    
    // MARK: - Existence & Visibility
    
    /// 是否存在且可见
    var isVisible: Bool {
        exists && isHittable
    }
    
    /// 等待元素可见
    @discardableResult
    func waitForVisibility(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /// 等待元素消失
    @discardableResult
    func waitForDisappearance(timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    // MARK: - Tap Actions
    
    /// 安全点击（等待可见后再点击）
    func safeTap(timeout: TimeInterval = 3) {
        _ = waitForVisibility(timeout: timeout)
        if isHittable {
            tap()
        } else {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
    
    /// 双击
    func doubleTapElement() {
        doubleTap()
    }
    
    /// 长按
    func longPressElement(duration: TimeInterval = 1.0) {
        press(forDuration: duration)
    }
    
    // MARK: - Text Input
    
    /// 设置文本（清除后输入）
    func setText(_ text: String) {
        clearText()
        typeText(text)
    }
    
    /// 追加文本
    func appendText(_ text: String) {
        tap()
        typeText(text)
    }
    
    /// 获取文本值
    var textValue: String {
        if let value = value as? String {
            return value
        }
        return label
    }
    
    // MARK: - Scroll Actions
    
    /// 向上滚动
    func scrollUp(velocity: XCUIGestureVelocity = .default) {
        swipeUp(velocity: velocity)
    }
    
    /// 向下滚动
    func scrollDown(velocity: XCUIGestureVelocity = .default) {
        swipeDown(velocity: velocity)
    }
    
    /// 滚动到顶部
    func scrollToTop() {
        let topCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let bottomCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        
        for _ in 0..<5 {
            bottomCoordinate.press(forDuration: 0.1, thenDragTo: topCoordinate)
        }
    }
    
    /// 滚动到底部
    func scrollToBottom() {
        let topCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let bottomCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        
        for _ in 0..<5 {
            topCoordinate.press(forDuration: 0.1, thenDragTo: bottomCoordinate)
        }
    }
    
    // MARK: - Swipe Actions
    
    /// 向左滑动删除
    func swipeToDelete() {
        swipeLeft()
        
        // 点击删除按钮
        let deleteButton = buttons["删除"]
        if deleteButton.waitForExistence(timeout: 2) {
            deleteButton.tap()
        }
    }
    
    // MARK: - Query Helpers
    
    /// 查找子元素（按类型和标识符）
    func child(type: XCUIElement.ElementType, identifier: String) -> XCUIElement {
        return descendants(matching: type)[identifier]
    }
    
    /// 查找所有包含文本的子元素
    func childrenContaining(text: String, type: XCUIElement.ElementType = .any) -> XCUIElementQuery {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        return descendants(matching: type).containing(predicate)
    }
}

// MARK: - XCUIApplication Extensions

extension XCUIApplication {
    
    /// 重启应用
    func restart() {
        terminate()
        launch()
    }
    
    /// 后台运行一段时间后返回
    func runInBackground(duration: TimeInterval) {
        XCUIDevice.shared.press(.home)
        sleep(UInt32(duration))
        activate()
    }
}

// MARK: - XCUIElementQuery Extensions

extension XCUIElementQuery {
    
    /// 获取第一个包含指定文本的元素
    func containing(text: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        return containing(predicate).firstMatch
    }
    
    /// 获取所有可见元素
    var visibleElements: [XCUIElement] {
        return allElementsBoundByIndex.filter { $0.isVisible }
    }
}
