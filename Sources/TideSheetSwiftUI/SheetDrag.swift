//
//  SheetDrag.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import Foundation
import TideSheet

struct SheetDrag {
    let startingHeight: CGFloat
    var translation: CGFloat

    func height(maximum: CGFloat) -> CGFloat {
        min(maximum, max(0, startingHeight - translation))
    }

    /// Nil means dismissal. Equal physical heights retain the logical selection.
    func destination(
        predictedTranslation: CGFloat,
        layout: TideSheetDetentLayout,
        selectedDetent: TideSheetDetent.Id,
    ) -> TideSheetDetent.Id? {
        let projectedHeight = startingHeight - predictedTranslation
        guard let lowest = layout.restingPoints.first else { return selectedDetent }
        if translation > 0, projectedHeight < lowest.height * 0.6 { return nil }
        let closest = layout.restingPoints.min {
            abs($0.height - projectedHeight) < abs($1.height - projectedHeight)
        }!
        return closest.detentIds.contains(selectedDetent) ? selectedDetent : closest.detentIds[0]
    }
}
