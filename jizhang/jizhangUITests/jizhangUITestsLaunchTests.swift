//
//  jizhangUITestsLaunchTests.swift
//  jizhangUITests
//
//  Created by 徐晓龙 on 2026/1/24.
//

import XCTest

final class jizhangUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset", "--existing-user", "--skip-update-summary"]
        app.launch()

        XCTAssertTrue(app.staticTexts["今日状态"].waitForExistence(timeout: 8))

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
