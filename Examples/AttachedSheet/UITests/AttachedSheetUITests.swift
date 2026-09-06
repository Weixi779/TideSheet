//
//  AttachedSheetUITests.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import XCTest

final nonisolated class AttachedSheetUITests: XCTestCase {
    @MainActor
    func testInternalSelectionAndRepeatedDismissal() {
        let app = openExample("Internal selection")
        app.buttons["Open sheet"].tap()
        let handle = app.descendants(matching: .any)["Resize sheet"].firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        let initialY = handle.frame.minY
        capture("Internal selection - compact", app: app)
        app.buttons["Maximum"].tap()
        XCTAssertTrue(wait { handle.frame.minY < initialY - 100 })
        capture("Internal selection - maximum", app: app)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(wait { abs(handle.frame.minY - initialY) < 3 })
        app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 2"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testBindingAndDynamicMeasurements() {
        let app = openExample("External selection")
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(app.buttons["Maximum"].waitForExistence(timeout: 5))
        app.buttons["Maximum"].tap()
        XCTAssertTrue(app.staticTexts["Selection: maximum"].waitForExistence(timeout: 5))
        app.buttons["Select half through binding"].tap()
        XCTAssertTrue(app.staticTexts["Selection: half"].waitForExistence(timeout: 5))
        app.buttons["Content"].tap()
        let handle = app.descendants(matching: .any)["Resize sheet"].firstMatch
        let before = handle.frame.minY
        app.buttons["Resize content"].tap()
        XCTAssertTrue(wait { handle.frame.minY < before - 60 })
        capture("Fitting content after resize", app: app)
        app.buttons["Maximum"].tap()
        let fullHeightY = handle.frame.minY
        app.buttons["Resize host"].tap()
        XCTAssertTrue(wait { handle.frame.minY > fullHeightY + 100 })
        XCTAssertTrue(app.staticTexts["Selection: maximum"].exists)
    }

    @MainActor
    func testSameItemUpdatesAndReplacement() {
        let app = openExample("Item and initial selection")
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(app.buttons["Count 0"].waitForExistence(timeout: 5))
        app.buttons["Count 0"].tap()
        app.buttons["Update item"].tap()
        XCTAssertTrue(app.staticTexts["Updated item"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Count 1"].exists)
        app.buttons["Replace item"].tap()
        XCTAssertTrue(app.staticTexts["Item 2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Count 0"].exists)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 2"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAttachedStateSurvivesNavigation() {
        let app = openExample("Item and external selection")
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(app.buttons["Maximum"].waitForExistence(timeout: 5))
        app.buttons["Maximum"].tap()
        app.buttons["Count 0"].tap()
        app.buttons["Push next page"].tap()
        XCTAssertTrue(app.staticTexts["An independent route"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Close"].isHittable)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Count 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Selection: maximum"].exists)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testGrabberDragAndInteractiveDismissal() {
        let app = openExample("External selection")
        app.buttons["Open sheet"].tap()
        let handle = app.descendants(matching: .any)["Resize sheet"].firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        let initialY = handle.frame.minY
        let start = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -350)))
        XCTAssertTrue(app.staticTexts["Selection: maximum"].waitForExistence(timeout: 5))
        app.buttons["Fixed"].tap()
        XCTAssertTrue(wait { abs(handle.frame.minY - initialY) < 2 })
        let down = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        down.press(forDuration: 0.1, thenDragTo: down.withOffset(CGVector(dx: 0, dy: 300)))
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testModalFromSmallViewAndRepeatedDismissal() {
        let app = openExample("Modal internal selection")
        app.buttons["Open modal"].tap()
        let handle = app.descendants(matching: .any)["Resize sheet"].firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(handle.frame.width, app.frame.width - 5)
        XCTAssertFalse(app.buttons["Open modal"].isHittable)
        let initialY = handle.frame.minY
        capture("Modal from a small button", app: app)
        app.buttons["Maximum"].tap()
        XCTAssertTrue(wait { handle.frame.minY < initialY - 100 })
        app.buttons["Close modal"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Open modal"].isHittable)
        app.buttons["Open modal"].tap()
        XCTAssertTrue(wait { abs(handle.frame.minY - initialY) < 3 })
        app.buttons["Close externally"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 2"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testModalBindingAndDragDismissal() {
        let app = openExample("Modal external selection")
        app.buttons["Open modal"].tap()
        XCTAssertTrue(app.buttons["Maximum"].waitForExistence(timeout: 5))
        app.buttons["Maximum"].tap()
        XCTAssertTrue(app.staticTexts["Selection: maximum"].waitForExistence(timeout: 5))
        app.buttons["Select half through binding"].tap()
        XCTAssertTrue(app.staticTexts["Selection: half"].waitForExistence(timeout: 5))
        let handle = app.descendants(matching: .any)["Resize sheet"].firstMatch
        let start = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 350)))
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testModalItemUpdateAndReplacement() {
        let app = openExample("Modal item and initial selection")
        app.buttons["Open modal"].tap()
        XCTAssertTrue(app.buttons["Count 0"].waitForExistence(timeout: 5))
        app.buttons["Count 0"].tap()
        app.buttons["Update modal item"].tap()
        XCTAssertTrue(app.staticTexts["Updated modal item"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Count 1"].exists)
        app.buttons["Replace modal item"].tap()
        XCTAssertTrue(app.staticTexts["Modal item 2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Count 0"].exists)
        app.buttons["Close modal"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 2"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testModalStaysAboveUnderlyingNavigation() {
        let app = openExample("Modal item and external selection")
        app.buttons["Open modal"].tap()
        XCTAssertTrue(app.buttons["Count 0"].waitForExistence(timeout: 5))
        app.buttons["Count 0"].tap()
        app.buttons["Push behind modal"].tap()
        XCTAssertTrue(app.buttons["Close modal"].isHittable)
        XCTAssertTrue(app.buttons["Count 1"].exists)
        capture("Modal above the pushed route", app: app)
        app.buttons["Close modal"].tap()
        XCTAssertTrue(app.staticTexts["An independent route"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testModalSystemDismissAndNavigationAfterCompletion() {
        let app = openExample("Modal internal selection")
        app.buttons["Open modal"].tap()
        XCTAssertTrue(app.buttons["System dismiss"].waitForExistence(timeout: 5))
        app.buttons["System dismiss"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
        app.buttons["Open modal"].tap()
        XCTAssertTrue(app.buttons["Close then navigate"].waitForExistence(timeout: 5))
        app.buttons["Close then navigate"].tap()
        XCTAssertTrue(app.staticTexts["An independent route"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 2"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func openExample(_ name: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        app.buttons[name].tap()
        return app
    }

    @MainActor
    private func wait(_ condition: @escaping () -> Bool) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
        return XCTWaiter.wait(for: [expectation], timeout: 5) == .completed
    }
}
