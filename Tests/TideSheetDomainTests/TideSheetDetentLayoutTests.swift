//
//  TideSheetDetentLayoutTests.swift
//  TideSheet
//
//  Created by weixi on 2026/8/28.
//

import Foundation
import Testing
import TideSheetDomain

@Suite("TideSheet detent layout")
struct TideSheetDetentLayoutTests {
    @Test(
        arguments: [
            (TideSheetDetent.Height.content(maximum: nil), CGFloat(360)),
            (.content(maximum: 300), CGFloat(300)),
            (.fixed(240), CGFloat(240)),
            (.fraction(0.5), CGFloat(400)),
            (.maximum, CGFloat(800)),
        ],
    )
    func `Resolves supported height policies`(
        _ height: TideSheetDetent.Height,
        expectedHeight: CGFloat,
    ) throws {
        let detentId = TideSheetDetent.Id(rawValue: "subject")
        let layout = try #require(TideSheetDetentLayout(
            detents: [TideSheetDetent(id: detentId, height: height)],
            availableHeight: 800,
            contentFittingSheetHeight: 360,
        ))

        let restingPoint = try #require(layout.restingPoint(for: detentId))
        #expect(restingPoint.detentIds == [detentId])
        #expect(restingPoint.height == expectedHeight)
    }

    @Test(
        arguments: [
            (TideSheetDetent.Height.content(maximum: nil), CGFloat(600)),
            (.content(maximum: 480), CGFloat(480)),
            (.fixed(900), CGFloat(600)),
        ],
    )
    func `Clamps valid heights to the available height`(
        _ height: TideSheetDetent.Height,
        expectedHeight: CGFloat,
    ) throws {
        let detentId = TideSheetDetent.Id(rawValue: "subject")
        let layout = try #require(TideSheetDetentLayout(
            detents: [TideSheetDetent(id: detentId, height: height)],
            availableHeight: 600,
            contentFittingSheetHeight: 900,
        ))

        let restingPoint = try #require(layout.restingPoint(for: detentId))
        #expect(restingPoint.height == expectedHeight)
    }

    @Test
    func `Orders resting points by their concrete heights`() throws {
        let maximumId = TideSheetDetent.Id(rawValue: "maximum")
        let halfId = TideSheetDetent.Id(rawValue: "half")
        let compactId = TideSheetDetent.Id(rawValue: "compact")
        let contentId = TideSheetDetent.Id(rawValue: "content")
        let layout = try #require(TideSheetDetentLayout(
            detents: [
                TideSheetDetent(id: maximumId, height: .maximum),
                TideSheetDetent(id: halfId, height: .fraction(0.5)),
                TideSheetDetent(id: compactId, height: .fixed(200)),
                TideSheetDetent(id: contentId, height: .content()),
            ],
            availableHeight: 800,
            contentFittingSheetHeight: 350,
        ))

        #expect(layout.restingPoints.map(\.detentIds) == [[compactId], [contentId], [halfId], [maximumId]])
        #expect(layout.restingPoints.map(\.height) == [200, 350, 400, 800])
    }

    @Test
    func `Coalesces equal heights into one resting point`() throws {
        let halfId = TideSheetDetent.Id(rawValue: "half")
        let fixedId = TideSheetDetent.Id(rawValue: "fixed")
        let layout = try #require(TideSheetDetentLayout(
            detents: [
                TideSheetDetent(id: halfId, height: .fraction(0.5)),
                TideSheetDetent(id: fixedId, height: .fixed(400)),
            ],
            availableHeight: 800,
        ))

        let halfRestingPoint = try #require(layout.restingPoint(for: halfId))
        let fixedRestingPoint = try #require(layout.restingPoint(for: fixedId))
        #expect(layout.restingPoints.count == 1)
        #expect(halfRestingPoint.detentIds == [halfId, fixedId])
        #expect(fixedRestingPoint == halfRestingPoint)
        #expect(fixedRestingPoint.height == 400)
    }

    @Test
    func `Preserves identities when equal heights separate`() throws {
        let fixedId = TideSheetDetent.Id(rawValue: "fixed")
        let maximumId = TideSheetDetent.Id(rawValue: "maximum")
        let detents = [
            TideSheetDetent(id: fixedId, height: .fixed(700)),
            TideSheetDetent(id: maximumId, height: .maximum),
        ]
        let compactLayout = try #require(TideSheetDetentLayout(
            detents: detents,
            availableHeight: 600,
        ))
        let expandedLayout = try #require(TideSheetDetentLayout(
            detents: detents,
            availableHeight: 800,
        ))

        let compactMaximumPoint = try #require(compactLayout.restingPoint(for: maximumId))
        let expandedFixedPoint = try #require(expandedLayout.restingPoint(for: fixedId))
        let expandedMaximumPoint = try #require(expandedLayout.restingPoint(for: maximumId))
        #expect(compactMaximumPoint.detentIds == [fixedId, maximumId])
        #expect(expandedFixedPoint.detentIds == [fixedId])
        #expect(expandedFixedPoint.height == 700)
        #expect(expandedMaximumPoint.detentIds == [maximumId])
        #expect(expandedMaximumPoint.height == 800)
    }

    @Test
    func `Returns nil for an unknown detent identifier`() throws {
        let knownId = TideSheetDetent.Id(rawValue: "known")
        let unknownId = TideSheetDetent.Id(rawValue: "unknown")
        let layout = try #require(TideSheetDetentLayout(
            detents: [TideSheetDetent(id: knownId, height: .fixed(240))],
            availableHeight: 800,
        ))

        #expect(layout.restingPoint(for: unknownId) == nil)
    }

    @Test
    func `Uses the latest content measurement`() throws {
        let contentId = TideSheetDetent.Id(rawValue: "content")
        let fixedId = TideSheetDetent.Id(rawValue: "fixed")
        let detents = [
            TideSheetDetent(id: contentId, height: .content()),
            TideSheetDetent(id: fixedId, height: .fixed(320)),
        ]

        let compactLayout = try #require(TideSheetDetentLayout(
            detents: detents,
            availableHeight: 600,
            contentFittingSheetHeight: 220,
        ))
        let expandedLayout = try #require(TideSheetDetentLayout(
            detents: detents,
            availableHeight: 600,
            contentFittingSheetHeight: 480,
        ))

        let compactContentPoint = try #require(compactLayout.restingPoint(for: contentId))
        let expandedContentPoint = try #require(expandedLayout.restingPoint(for: contentId))
        let compactFixedPoint = try #require(compactLayout.restingPoint(for: fixedId))
        let expandedFixedPoint = try #require(expandedLayout.restingPoint(for: fixedId))
        #expect(compactContentPoint.height == 220)
        #expect(expandedContentPoint.height == 480)
        #expect(compactFixedPoint.height == 320)
        #expect(expandedFixedPoint.height == 320)
    }

    @Test
    func `Waits for a content fitting Sheet measurement`() {
        let contentId = TideSheetDetent.Id(rawValue: "content")

        let layout = TideSheetDetentLayout(
            detents: [TideSheetDetent(id: contentId, height: .content())],
            availableHeight: 600,
        )

        #expect(layout == nil)
    }
}
