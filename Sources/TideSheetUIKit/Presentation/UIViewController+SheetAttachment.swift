//
//  UIViewController+SheetAttachment.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import UIKit

@MainActor
extension UIViewController {
    /// 将已经完成内容装配的 sheet 附着到当前页面。
    func attachBottomSheetViewController(
        _ sheet: BottomSheetViewController,
        animated: Bool,
        completion: (() -> Void)?,
    ) -> BottomSheetHandler {
        let attachment = BottomSheetAttachmentViewController(sheetViewController: sheet)
        let forwardsInitialAppearance = viewIfLoaded?.window != nil && transitionCoordinator == nil
        addChild(attachment)
        attachment.view.frame = view.bounds
        attachment.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        attachment.prepareForPresentation(
            forwardsInitialAppearance: forwardsInitialAppearance,
            animated: animated,
        )
        view.addSubview(attachment.view)
        attachment.didMove(toParent: self)
        attachment.startPresentation(animated: animated, completion: completion)
        return sheet.handler
    }
}
