//
//  UIViewController+BottomSheet.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import TideSheet
import UIKit

@MainActor
public extension UIViewController {
    /// 以 bottom sheet 展示一个内容视图控制器。
    ///
    /// 默认 `.modal` 独立展示；`.attached` 随当前宿主页面离屏与恢复。
    /// 内容根视图会铺满 sheet 内容区域；内容自行决定哪些子视图使用 safe-area 或 keyboard layout guide。
    @discardableResult
    func presentBottomSheet(
        _ contentViewController: UIViewController,
        presentation: SheetPresentation = .modal,
        configuration: BottomSheetConfiguration,
        animated: Bool = true,
        onDismiss: (() -> Void)? = nil,
        completion: (() -> Void)? = nil,
    ) -> BottomSheetHandler {
        let sheet = BottomSheetViewController(
            contentViewController: contentViewController,
            configuration: configuration,
            onDismiss: onDismiss,
        )
        switch presentation {
        case .modal:
            present(sheet, animated: animated, completion: completion)
        case .attached:
            return attachBottomSheetViewController(sheet, animated: animated, completion: completion)
        }
        return sheet.handler
    }
}
