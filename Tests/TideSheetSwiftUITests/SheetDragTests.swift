//
//  SheetDragTests.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import Foundation
import Testing
import TideSheet
@testable import TideSheetSwiftUI

@Suite("Sheet drag settlement")
struct SheetDragTests {
    @Test(arguments: [(CGFloat(-320), CGFloat(-380), "large"), (CGFloat(25), CGFloat(40), "small")])
    func `Settles to the nearest projected resting point`(translation: CGFloat, projected: CGFloat, expected: String) throws {
        let small = TideSheetDetent.Id(rawValue: "small")
        let large = TideSheetDetent.Id(rawValue: "large")
        let layout = try #require(TideSheetDetentLayout(
            detents: [.init(id: small, height: .fixed(200)), .init(id: large, height: .fixed(600))],
            availableHeight: 800,
        ))
        let drag = SheetDrag(startingHeight: 200, translation: translation)
        #expect(drag.destination(predictedTranslation: projected, layout: layout, selectedDetent: small)?.rawValue == expected)
    }

    @Test
    func `Dragging below the lowest point can dismiss without creating a hidden detent`() throws {
        let id = TideSheetDetent.Id(rawValue: "small")
        let layout = try #require(TideSheetDetentLayout(detents: [.init(id: id, height: .fixed(200))], availableHeight: 800))
        let drag = SheetDrag(startingHeight: 200, translation: 120)
        #expect(drag.destination(predictedTranslation: 180, layout: layout, selectedDetent: id) == nil)
        #expect(drag.height(maximum: 800) == 80)
    }

    @Test
    func `Coalesced points preserve the selected logical identity`() throws {
        let fixed = TideSheetDetent.Id(rawValue: "fixed")
        let maximum = TideSheetDetent.Id(rawValue: "maximum")
        let detents = [TideSheetDetent(id: fixed, height: .fixed(700)), .init(id: maximum, height: .maximum)]
        let small = try #require(TideSheetDetentLayout(detents: detents, availableHeight: 600))
        let drag = SheetDrag(startingHeight: 600, translation: 20)
        let selected = try #require(drag.destination(predictedTranslation: 20, layout: small, selectedDetent: maximum))
        #expect(selected == maximum)
        let large = try #require(TideSheetDetentLayout(detents: detents, availableHeight: 900))
        #expect(large.restingPoint(for: selected)?.height == 900)
    }

    @Test
    func `Visual drag stays within the container`() {
        #expect(SheetDrag(startingHeight: 600, translation: -300).height(maximum: 700) == 700)
        #expect(SheetDrag(startingHeight: 200, translation: 400).height(maximum: 700) == 0)
    }
}
