//
//  BottomSheetGeometry.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import TideSheet
import UIKit

enum BottomSheetGeometry {
    static func frame(height: CGFloat, in bounds: CGRect) -> CGRect {
        CGRect(x: bounds.minX, y: bounds.maxY - height, width: bounds.width, height: height)
    }

    static func availableHeight(in bounds: CGRect, topSafeAreaInset: CGFloat) -> CGFloat {
        max(0, bounds.height - max(0, topSafeAreaInset))
    }
}

enum BottomSheetDetentMotion {
    static func destination(
        currentHeight: CGFloat,
        velocityY: CGFloat,
        movingDown: Bool,
        layout: TideSheetDetentLayout,
        selectedDetent: TideSheetDetent.Id,
        allowsDismissal: Bool,
    ) -> TideSheetDetent.Id? {
        guard let lowest = layout.restingPoints.first else { return selectedDetent }
        let projectedHeight = currentHeight - velocityY * 0.2
        if allowsDismissal, movingDown, projectedHeight < lowest.height * 0.6 { return nil }
        let closest = layout.restingPoints.min { abs($0.height - projectedHeight) < abs($1.height - projectedHeight) }!
        return closest.detentIds.contains(selectedDetent) ? selectedDetent : closest.detentIds[0]
    }
}
