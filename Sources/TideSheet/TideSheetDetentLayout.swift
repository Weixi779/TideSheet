//
//  TideSheetDetentLayout.swift
//  TideSheet
//
//  Created by weixi on 2026/8/28.
//

import Foundation

package struct TideSheetDetentLayout: Equatable {
    package struct RestingPoint: Equatable {
        /// Stable detent identities that currently share this physical resting height.
        package let detentIds: [TideSheetDetent.Id]
        package let height: CGFloat

        fileprivate init(detentIds: [TideSheetDetent.Id], height: CGFloat) {
            self.detentIds = detentIds
            self.height = height
        }
    }

    package let restingPoints: [RestingPoint]

    private let restingPointsByDetentId: [TideSheetDetent.Id: RestingPoint]

    /// Creates concrete resting points from measurements normalized by a renderer.
    ///
    /// `availableHeight` is the maximum outer Sheet height after host constraints are applied.
    /// `contentFittingSheetHeight` is the measured outer Sheet height, including its chrome,
    /// where a positive value means the measurement is ready and `nil` or zero means it is not.
    package init?(
        detents: [TideSheetDetent],
        availableHeight: CGFloat,
        contentFittingSheetHeight: CGFloat? = nil,
    ) {
        precondition(!detents.isEmpty, "A TideSheet detent layout requires at least one detent.")
        precondition(
            availableHeight.isFinite && availableHeight >= 0,
            "availableHeight must be finite and nonnegative.",
        )
        precondition(
            Set(detents.map(\.id)).count == detents.count,
            "TideSheet detent identifiers must be unique.",
        )
        detents.forEach { Self.validate(height: $0.height) }
        if let contentFittingSheetHeight {
            precondition(
                contentFittingSheetHeight.isFinite && contentFittingSheetHeight >= 0,
                "contentFittingSheetHeight must be finite and nonnegative.",
            )
        }

        guard availableHeight > 0 else { return nil }

        let needsContentFittingSheetHeight = detents.contains {
            if case .content = $0.height { true } else { false }
        }
        let measuredContentFittingSheetHeight: CGFloat
        if needsContentFittingSheetHeight {
            guard let contentFittingSheetHeight, contentFittingSheetHeight > 0 else { return nil }
            measuredContentFittingSheetHeight = contentFittingSheetHeight
        } else {
            measuredContentFittingSheetHeight = 0
        }

        let candidates = detents.enumerated().map {
            Candidate(
                declarationIndex: $0.offset,
                detentId: $0.element.id,
                height: Self.height(
                    for: $0.element.height,
                    availableHeight: availableHeight,
                    contentFittingSheetHeight: measuredContentFittingSheetHeight,
                ),
            )
        }
        .sorted {
            if $0.height == $1.height {
                return $0.declarationIndex < $1.declarationIndex
            }
            return $0.height < $1.height
        }

        var restingPoints: [RestingPoint] = []
        for candidate in candidates {
            if let previousRestingPoint = restingPoints.last,
               previousRestingPoint.height == candidate.height
            {
                restingPoints[restingPoints.endIndex - 1] = RestingPoint(
                    detentIds: previousRestingPoint.detentIds + [candidate.detentId],
                    height: previousRestingPoint.height,
                )
            } else {
                restingPoints.append(
                    RestingPoint(detentIds: [candidate.detentId], height: candidate.height),
                )
            }
        }

        self.restingPoints = restingPoints
        restingPointsByDetentId = Dictionary(
            uniqueKeysWithValues: restingPoints.flatMap { restingPoint in
                restingPoint.detentIds.map { ($0, restingPoint) }
            },
        )
    }

    package func restingPoint(for detentId: TideSheetDetent.Id) -> RestingPoint? {
        restingPointsByDetentId[detentId]
    }
}

private extension TideSheetDetentLayout {
    struct Candidate {
        let declarationIndex: Int
        let detentId: TideSheetDetent.Id
        let height: CGFloat
    }

    static func height(
        for height: TideSheetDetent.Height,
        availableHeight: CGFloat,
        contentFittingSheetHeight: CGFloat,
    ) -> CGFloat {
        switch height {
        case let .content(maximumHeight):
            if let maximumHeight {
                return min(contentFittingSheetHeight, min(maximumHeight, availableHeight))
            }
            return min(contentFittingSheetHeight, availableHeight)
        case let .fixed(height):
            return min(height, availableHeight)
        case let .fraction(fraction):
            return availableHeight * fraction
        case .maximum:
            return availableHeight
        }
    }

    static func validate(height: TideSheetDetent.Height) {
        switch height {
        case let .content(maximumHeight):
            if let maximumHeight {
                precondition(
                    maximumHeight.isFinite && maximumHeight > 0,
                    "A content detent maximum height must be finite and greater than zero.",
                )
            }
        case let .fixed(height):
            precondition(
                height.isFinite && height > 0,
                "A fixed detent height must be finite and greater than zero.",
            )
        case let .fraction(fraction):
            precondition(
                fraction.isFinite && fraction > 0 && fraction <= 1,
                "A detent fraction must be finite, greater than zero, and no greater than one.",
            )
        case .maximum:
            break
        }
    }
}
