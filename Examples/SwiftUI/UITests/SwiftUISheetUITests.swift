//
//  SwiftUISheetUITests.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import XCTest

final nonisolated class SwiftUISheetUITests: XCTestCase {
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
        XCTAssertTrue(waitForStableFrame(handle))
        let fullHeightY = handle.frame.minY
        app.buttons["Resize source"].tap()
        XCTAssertTrue(waitForStableFrame(handle))
        XCTAssertEqual(handle.frame.minY, fullHeightY, accuracy: 2)
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
        app.buttons["Update modal item"].tap()
        XCTAssertTrue(app.staticTexts["Updated modal item"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Count 1"].exists)
        app.buttons["Replace modal item"].tap()
        XCTAssertTrue(app.staticTexts["Modal item 2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Count 0"].exists)
        app.buttons["Close modal"].tap()
        XCTAssertTrue(app.staticTexts["An independent route"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 2"].waitForExistence(timeout: 5))
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
    func testUIKitContentInSwiftUIModal() {
        exerciseControllerContent(isAttached: false)
    }

    @MainActor
    func testUIKitContentInSwiftUIAttachment() {
        exerciseControllerContent(isAttached: true)
    }

    @MainActor
    private func exerciseControllerContent(isAttached: Bool) {
        let app = openExample(isAttached ? "UIKit content · Attached" : "UIKit content · Modal")
        app.buttons["Open UIKit content"].tap()
        XCTAssertTrue(app.buttons["Controller count 0"].waitForExistence(timeout: 5))
        app.buttons["Controller count 0"].tap()
        app.buttons["Content"].tap()
        let grabber = app.descendants(matching: .any)["Resize sheet"].firstMatch
        XCTAssertTrue(wait { grabber.value as? String == "content" })
        let initialY = grabber.frame.minY
        app.buttons["Resize controller"].tap()
        XCTAssertTrue(wait { grabber.frame.minY < initialY - 60 })
        app.buttons["Update controller item"].tap()
        XCTAssertTrue(app.staticTexts["Updated controller item"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Controller count 1"].exists)
        capture(isAttached ? "UIKit content in SwiftUI attachment" : "UIKit content in SwiftUI modal", app: app)
        app.buttons["Maximum"].tap()
        XCTAssertTrue(wait { grabber.value as? String == "maximum" })
        app.buttons["Push from controller"].tap()
        if isAttached {
            XCTAssertTrue(app.staticTexts["An independent route"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["Close controller"].isHittable)
            app.navigationBars.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(app.buttons["Controller count 1"].waitForExistence(timeout: 5))
            XCTAssertEqual(grabber.value as? String, "maximum")
        } else {
            XCTAssertTrue(app.buttons["Close controller"].isHittable)
        }
        app.buttons["Replace controller item"].tap()
        XCTAssertTrue(app.staticTexts["Controller item 2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Controller count 0"].exists)
        app.buttons["Close controller"].tap()
        if !isAttached {
            XCTAssertTrue(app.staticTexts["An independent route"].waitForExistence(timeout: 5))
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        XCTAssertTrue(app.staticTexts["Dismissals: 2"].waitForExistence(timeout: 5))
        app.buttons["Open UIKit content"].tap()
        XCTAssertTrue(app.buttons["Controller count 0"].waitForExistence(timeout: 5))
        app.buttons["Close controller"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 3"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAttachedCoversNavigationAndBottomFromSmallControl() {
        let app = openExample("Choose presentation")
        let backPosition = app.navigationBars.buttons.element(boundBy: 0).frame
        let sourcePosition = app.buttons["Open chosen sheet"].frame
        app.buttons["Open chosen sheet"].tap()
        XCTAssertTrue(app.buttons["Close chosen sheet"].waitForExistence(timeout: 5))
        let container = app.descendants(matching: .any)["TideSheet.AttachedContainer"].firstMatch
        XCTAssertTrue(container.exists)
        XCTAssertEqual(container.frame.minY, app.frame.minY, accuracy: 1)
        XCTAssertEqual(container.frame.maxY, app.frame.maxY, accuracy: 1)
        XCTAssertEqual(container.frame.width, app.frame.width, accuracy: 1)
        capture("Attached mask covers navigation and bottom", app: app)
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: backPosition.midX, dy: backPosition.midY)).tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Open chosen sheet"].isHittable)
        app.buttons["Open chosen sheet"].tap()
        XCTAssertTrue(app.buttons["Close chosen sheet"].waitForExistence(timeout: 5))
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: sourcePosition.midX, dy: sourcePosition.midY)).tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 2"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPresentationChoiceAppliesAfterDismissal() {
        let app = openExample("Choose presentation")
        app.buttons["Open chosen sheet"].tap()
        XCTAssertTrue(app.buttons["Count 0"].waitForExistence(timeout: 5))
        app.buttons["Count 0"].tap()
        app.buttons["Change next presentation"].tap()
        XCTAssertTrue(app.buttons["Count 1"].exists)
        app.buttons["Push next page"].tap()
        XCTAssertTrue(app.staticTexts["An independent route"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Close chosen sheet"].isHittable)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Count 1"].waitForExistence(timeout: 5))
        app.buttons["Close chosen sheet"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
        app.buttons["Open chosen sheet"].tap()
        XCTAssertTrue(app.buttons["Count 0"].waitForExistence(timeout: 5))
        app.buttons["Push next page"].tap()
        XCTAssertTrue(app.buttons["Close chosen sheet"].isHittable)
        app.buttons["Close chosen sheet"].tap()
        XCTAssertTrue(app.staticTexts["An independent route"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 2"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAttachedInteractiveReturnAndCancellation() {
        let app = openExample("Item and external selection")
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(app.buttons["Count 0"].waitForExistence(timeout: 5))
        app.buttons["Count 0"].tap()
        app.buttons["Maximum"].tap()
        XCTAssertTrue(waitForStableFrame(app.buttons["Push next page"]))
        app.buttons["Push next page"].tap()
        XCTAssertTrue(app.staticTexts["An independent route"].waitForExistence(timeout: 5))
        let edge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.002, dy: 0.5))
        edge.press(forDuration: 0.1,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.16, dy: 0.5)),
                   withVelocity: .slow, thenHoldForDuration: 1)
        XCTAssertTrue(app.staticTexts["An independent route"].isHittable)
        XCTAssertFalse(app.buttons["Close"].isHittable)
        edge.press(forDuration: 0.1,
                   thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)),
                   withVelocity: .slow, thenHoldForDuration: 0.2)
        XCTAssertTrue(app.buttons["Count 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Selection: maximum"].exists)
        capture("Attached content after interactive return", app: app)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAttachedSurvivesNativePresentation() {
        let app = openExample("Choose presentation")
        app.buttons["Open chosen sheet"].tap()
        XCTAssertTrue(app.buttons["Count 0"].waitForExistence(timeout: 5))
        app.buttons["Count 0"].tap()
        app.buttons["Native sheet"].tap()
        XCTAssertTrue(app.buttons["Close native sheet"].waitForExistence(timeout: 5))
        app.buttons["Close native sheet"].tap()
        XCTAssertTrue(app.buttons["Count 1"].waitForExistence(timeout: 5))
        app.buttons["Close chosen sheet"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAttachedContainerFollowsRotation() {
        let app = openExample("Internal selection")
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(app.buttons["Count 0"].waitForExistence(timeout: 5))
        app.buttons["Count 0"].tap()
        app.buttons["Maximum"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        XCTAssertTrue(wait { app.frame.width > app.frame.height })
        XCTAssertTrue(wait { app.buttons["Close"].isHittable && app.buttons["Count 1"].isHittable })
        let container = app.descendants(matching: .any)["TideSheet.AttachedContainer"].firstMatch
        XCTAssertEqual(container.frame.width, app.frame.width, accuracy: 1)
        XCTAssertEqual(container.frame.height, app.frame.height, accuracy: 1)
        XCTAssertTrue(app.buttons["Count 1"].exists)
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "Attached container in landscape"
        landscape.lifetime = .keepAlways
        add(landscape)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(wait { app.frame.height > app.frame.width })
        XCTAssertTrue(app.buttons["Count 1"].exists)
        XCTAssertEqual(app.descendants(matching: .any)["Resize sheet"].firstMatch.value as? String, "maximum")
        app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLeavingDeclaringPageRemovesAttachedCarrier() {
        let app = openExample("Choose presentation")
        app.buttons["Open chosen sheet"].tap()
        XCTAssertTrue(app.buttons["Leave declaring page"].waitForExistence(timeout: 5))
        app.buttons["Leave declaring page"].tap()
        XCTAssertTrue(app.buttons["Choose presentation"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Close chosen sheet"].exists)
        XCTAssertTrue(app.staticTexts["Ended sheets: 1"].waitForExistence(timeout: 5))
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
        for _ in 0 ..< 3 where !app.buttons[name].exists || !app.buttons[name].isHittable {
            app.swipeUp()
        }
        app.buttons[name].tap()
        return app
    }

    @MainActor
    private func waitForStableFrame(_ element: XCUIElement) -> Bool {
        var frame = element.frame
        var lastChange = Date()
        return wait {
            if abs(element.frame.minY - frame.minY) > 0.5 {
                frame = element.frame
                lastChange = Date()
            }
            return Date().timeIntervalSince(lastChange) > 0.3
        }
    }

    @MainActor
    private func wait(_ condition: @escaping () -> Bool) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
        return XCTWaiter.wait(for: [expectation], timeout: 5) == .completed
    }
}
