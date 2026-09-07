//
//  UIKitSheetUITests.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import XCTest

final nonisolated class UIKitSheetUITests: XCTestCase {
    @MainActor
    func testSwiftUIContentInUIKitModal() {
        exerciseHostedContent(isAttached: false)
    }

    @MainActor
    func testSwiftUIContentInUIKitAttachment() {
        exerciseHostedContent(isAttached: true)
    }

    @MainActor
    private func exerciseHostedContent(isAttached: Bool) {
        let app = open(isAttached ? "SwiftUI content · Attached" : "SwiftUI content · Modal")
        app.buttons["Open SwiftUI content"].tap()
        XCTAssertTrue(app.buttons["Hosted count 0"].waitForExistence(timeout: 5))
        app.buttons["Hosted count 0"].tap()
        app.buttons["Content"].tap()
        XCTAssertTrue(app.staticTexts["Selection: content"].waitForExistence(timeout: 5))
        let grabber = handle(in: app)
        let initialY = grabber.frame.minY
        app.buttons["Resize hosted content"].tap()
        XCTAssertTrue(wait { grabber.frame.minY < initialY - 80 })
        app.buttons["Update title"].tap()
        XCTAssertTrue(app.staticTexts["Updated hosted title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Hosted count 1"].exists)
        capture(isAttached ? "SwiftUI content in UIKit attachment" : "SwiftUI content in UIKit modal", app)
        app.buttons["Maximum"].tap()
        XCTAssertTrue(app.staticTexts["Selection: maximum"].waitForExistence(timeout: 5))
        app.buttons["Push from hosted content"].tap()
        if isAttached {
            XCTAssertTrue(app.navigationBars["Bridge detail"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["Close hosted content"].isHittable)
            app.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(app.buttons["Hosted count 1"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["Selection: maximum"].exists)
        } else {
            XCTAssertTrue(app.buttons["Close hosted content"].isHittable)
            XCTAssertTrue(app.buttons["Hosted count 1"].exists)
        }
        app.buttons["Close hosted content"].tap()
        if !isAttached {
            XCTAssertTrue(app.navigationBars["Bridge detail"].waitForExistence(timeout: 5))
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
        app.buttons["Dismiss old presentation"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].exists)
        app.buttons["Open SwiftUI content"].tap()
        XCTAssertTrue(app.buttons["Hosted count 0"].waitForExistence(timeout: 5))
        app.buttons["Close hosted then navigate"].tap()
        XCTAssertTrue(app.navigationBars["Bridge detail"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 2"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testModalSelectionMeasurementAndRepeatedDismissal() {
        let app = open("Modal")
        app.buttons["Open sheet"].tap()
        let handle = handle(in: app)
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        let initialY = handle.frame.minY
        app.buttons["Maximum"].tap()
        XCTAssertTrue(app.staticTexts["Selection: maximum"].waitForExistence(timeout: 5))
        XCTAssertLessThan(handle.frame.minY, initialY - 100)
        app.buttons["Content"].tap()
        XCTAssertTrue(app.staticTexts["Selection: content"].waitForExistence(timeout: 5))
        let fittingY = handle.frame.minY
        app.buttons["Resize content"].tap()
        XCTAssertTrue(wait { handle.frame.minY < fittingY - 60 })
        capture("UIKit content fitting detent", app)
        app.buttons["Close twice"].tap()
        XCTAssertTrue(status("Dismissals: 1", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(status("Completions: 2", in: app).exists)
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(wait { abs(handle.frame.minY - initialY) < 3 })
        app.buttons["Close sheet"].tap()
        XCTAssertTrue(status("Dismissals: 2", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testAttachedRetainsContentAndSelectionAcrossPushPop() {
        let app = open("Attached")
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(app.buttons["Count 0"].waitForExistence(timeout: 5))
        app.buttons["Maximum"].tap()
        app.buttons["Count 0"].tap()
        app.buttons["Push behind sheet"].tap()
        XCTAssertTrue(app.navigationBars["Route detail"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Close sheet"].isHittable)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Count 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Selection: maximum"].exists)
        app.buttons["Close sheet"].tap()
        XCTAssertTrue(status("Dismissals: 1", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testModalStaysAboveUnderlyingPush() {
        let app = open("Modal")
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(app.buttons["Count 0"].waitForExistence(timeout: 5))
        app.buttons["Count 0"].tap()
        app.buttons["Push behind sheet"].tap()
        XCTAssertTrue(app.buttons["Close sheet"].isHittable)
        XCTAssertTrue(app.buttons["Count 1"].exists)
        capture("UIKit modal above pushed route", app)
        app.buttons["Close sheet"].tap()
        XCTAssertTrue(app.navigationBars["Route detail"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(status("Dismissals: 1", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testKeyboardLayoutIsOwnedByContent() {
        let app = open("Modal")
        app.buttons["Open sheet"].tap()
        let input = app.textFields["Type here"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        let initialY = handle(in: app).frame.minY
        input.tap()
        input.typeText("Native keyboard layout")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(handle(in: app).frame.minY, initialY, accuracy: 3)
        XCTAssertLessThanOrEqual(input.frame.maxY, app.keyboards.firstMatch.frame.minY)
        capture("UIKit content owns keyboard layout", app)
    }

    @MainActor
    func testScrollingDoesNotResizeSheetAndIndicatorCanDismiss() {
        let app = open("Scrolling content")
        app.buttons["Open sheet"].tap()
        let table = app.tables["Sheet rows"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        let handle = handle(in: app)
        let initialY = handle.frame.minY
        table.swipeUp()
        XCTAssertFalse(table.cells.staticTexts["Row 0"].isHittable)
        XCTAssertEqual(handle.frame.minY, initialY, accuracy: 3)
        let start = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 350)))
        XCTAssertTrue(status("Dismissals: 1", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testClosingSheetAlsoClosesItsDescendantModal() {
        let app = open("Modal")
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(app.buttons["Present child modal"].waitForExistence(timeout: 5))
        app.buttons["Present child modal"].tap()
        XCTAssertTrue(app.buttons["Close whole sheet"].waitForExistence(timeout: 5))
        app.buttons["Close whole sheet"].tap()
        XCTAssertTrue(status("Dismissals: 1", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Close sheet"].exists)
        XCTAssertTrue(app.buttons["Open sheet"].isHittable)
    }

    @MainActor
    func testAttachedRetainsContentAfterReturningFromNativeModal() {
        let app = open("Attached")
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(app.buttons["Count 0"].waitForExistence(timeout: 5))
        app.buttons["Count 0"].tap()
        app.buttons["Maximum"].tap()
        app.buttons["Present child modal"].tap()
        XCTAssertTrue(app.buttons["Back to sheet"].waitForExistence(timeout: 5))
        app.buttons["Back to sheet"].tap()
        XCTAssertTrue(app.buttons["Count 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Selection: maximum"].exists)
        app.buttons["Close sheet"].tap()
        XCTAssertTrue(status("Dismissals: 1", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testCloseCompletionCanNavigate() {
        let app = open("Modal")
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(app.buttons["Close then navigate"].waitForExistence(timeout: 5))
        app.buttons["Close then navigate"].tap()
        XCTAssertTrue(app.navigationBars["Route detail"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(status("Dismissals: 1", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testImmediateModalDismissal() {
        let app = open("Immediate modal dismissal")
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(status("Dismissals: 1", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Open sheet"].isHittable)
    }

    @MainActor
    func testImmediateAttachedDismissal() {
        let app = open("Immediate attached dismissal")
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(status("Dismissals: 1", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Open sheet"].isHittable)
    }

    @MainActor
    private func open(_ mode: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        app.tables.cells.staticTexts[mode].tap()
        return app
    }

    @MainActor
    private func handle(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["Resize sheet"].firstMatch
    }

    @MainActor
    private func status(_ value: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", value)).firstMatch
    }

    @MainActor
    private func wait(_ condition: @escaping () -> Bool) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
        return XCTWaiter.wait(for: [expectation], timeout: 5) == .completed
    }

    @MainActor
    private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
