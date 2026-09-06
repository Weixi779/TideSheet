//
//  BottomSheetLifecycle.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import UIKit

/// 汇总所有关闭出口，保证回调只执行一次。
@MainActor
final class BottomSheetDismissalGate {
    private(set) var didNotify = false
    private var handler: (() -> Void)?

    init(handler: (() -> Void)?) {
        self.handler = handler
    }

    var onDismiss: (() -> Void)? {
        get { handler }
        set {
            guard !didNotify else { return }
            handler = newValue
        }
    }

    func notifyIfNeeded() {
        guard !didNotify else { return }
        didNotify = true
        let handler = handler
        self.handler = nil
        handler?()
    }
}

/// 从 sheet 的 presenter 发起关闭，确保同时移除 sheet 上方的 descendant modal。
@MainActor
enum BottomSheetDismissalCoordinator {
    static func dismiss(
        viewController: BottomSheetViewController,
        dismissalGate: BottomSheetDismissalGate,
        animated: Bool,
        completion: (() -> Void)?,
    ) {
        guard let presentingViewController = viewController.presentingViewController else {
            dismissalGate.notifyIfNeeded()
            completion?()
            return
        }

        presentingViewController.dismiss(animated: animated) {
            dismissalGate.notifyIfNeeded()
            completion?()
        }
    }
}
