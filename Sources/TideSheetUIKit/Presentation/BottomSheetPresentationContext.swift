//
//  BottomSheetPresentationContext.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import UIKit

/// 为同一套 sheet surface 提供 modal 或 route-attached 的容器能力。
@MainActor
protocol BottomSheetPresentationContext: AnyObject {
    func invalidateLayout(animated: Bool)
    func applyCurrentFrame()
    func setDimmingProgress(_ progress: CGFloat)
    func dismissSheet(animated: Bool, completion: (() -> Void)?)
}
