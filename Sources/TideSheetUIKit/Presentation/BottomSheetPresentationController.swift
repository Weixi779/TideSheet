//
//  BottomSheetPresentationController.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import UIKit

/// 管理 modal 容器中的 dimming、sheet frame 与关闭生命周期。
@MainActor
final class BottomSheetPresentationController: UIPresentationController, BottomSheetPresentationContext {
    let dimmingView = UIView()
    let dimmingContentView: UIView
    let dimmingInteractionView = UIControl()

    private let allowsDimmingDismissal: Bool
    private let managesDimmingProgress: Bool
    private var dimmingProgress: CGFloat = 1

    private var sheetViewController: BottomSheetViewController? {
        presentedViewController as? BottomSheetViewController
    }

    override init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?,
    ) {
        if let sheetViewController = presentedViewController as? BottomSheetViewController {
            switch sheetViewController.configuration.dimmingBackground {
            case let .color(color):
                let view = UIView()
                view.backgroundColor = color
                dimmingContentView = view
                managesDimmingProgress = true
            case let .custom(provider):
                dimmingContentView = provider()
                managesDimmingProgress = false
            }
            allowsDimmingDismissal = sheetViewController.configuration.dismissesOnDimmingViewTap
        } else {
            dimmingContentView = UIView()
            allowsDimmingDismissal = false
            managesDimmingProgress = true
        }
        super.init(
            presentedViewController: presentedViewController,
            presenting: presentingViewController,
        )

        dimmingContentView.frame = dimmingView.bounds
        dimmingContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimmingView.addSubview(dimmingContentView)

        dimmingInteractionView.frame = dimmingView.bounds
        dimmingInteractionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimmingInteractionView.isUserInteractionEnabled = allowsDimmingDismissal
        dimmingInteractionView.isAccessibilityElement = allowsDimmingDismissal
        dimmingInteractionView.accessibilityLabel = allowsDimmingDismissal ? "Dismiss sheet" : nil
        dimmingInteractionView.accessibilityTraits = allowsDimmingDismissal ? .button : []
        dimmingInteractionView.addTarget(self, action: #selector(didTapDimmingView), for: .touchUpInside)
        dimmingView.addSubview(dimmingInteractionView)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        targetFrame()
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView else { return }

        dimmingView.frame = containerView.bounds
        if managesDimmingProgress {
            dimmingContentView.alpha = 0
        }
        dimmingInteractionView.isUserInteractionEnabled = false
        sheetViewController?.view.isUserInteractionEnabled = false
        containerView.insertSubview(dimmingView, at: 0)
        containerView.accessibilityViewIsModal = true

        let animations = { [self] in
            applyDimmingProgress()
        }
        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { _ in animations() })
        } else {
            animations()
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        guard completed else {
            containerView?.accessibilityElements = nil
            containerView?.accessibilityViewIsModal = false
            removeDimmingViews()
            sheetViewController?.view.isUserInteractionEnabled = true
            sheetViewController?.notifyDismissIfNeeded()
            return
        }

        dimmingInteractionView.isUserInteractionEnabled = allowsDimmingDismissal
        sheetViewController?.view.isUserInteractionEnabled = true
        if let containerView, let presentedView {
            containerView.accessibilityElements = allowsDimmingDismissal
                ? [presentedView, dimmingInteractionView]
                : [presentedView]
        }
        UIAccessibility.post(notification: .screenChanged, argument: presentedView)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        sheetViewController?.view.endEditing(true)
        dimmingInteractionView.isUserInteractionEnabled = false
        sheetViewController?.view.isUserInteractionEnabled = false

        let animations = { [self] in
            if managesDimmingProgress {
                dimmingContentView.alpha = 0
            }
        }
        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { _ in animations() })
        } else {
            animations()
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        guard completed else {
            applyDimmingProgress()
            dimmingInteractionView.isUserInteractionEnabled = allowsDimmingDismissal
            sheetViewController?.view.isUserInteractionEnabled = true
            return
        }

        containerView?.accessibilityElements = nil
        containerView?.accessibilityViewIsModal = false
        removeDimmingViews()
        sheetViewController?.notifyDismissIfNeeded()
        UIAccessibility.post(notification: .screenChanged, argument: presentingViewController.view)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        guard let containerView else { return }

        dimmingView.frame = containerView.bounds
        dimmingContentView.frame = dimmingView.bounds
        dimmingInteractionView.frame = dimmingView.bounds
        applyCurrentFrame()
    }

    /// 内容尺寸变化后重新求解并应用 sheet frame。
    func invalidateLayout(animated: Bool) {
        guard let presentedView, containerView != nil else { return }
        let targetFrame = targetFrame()
        let hasMeaningfulChange = abs(presentedView.bounds.height - targetFrame.height)
            > BottomSheetViewController.Metrics.heightEpsilon
            || abs(presentedView.bounds.width - targetFrame.width)
            > BottomSheetViewController.Metrics.heightEpsilon
        guard hasMeaningfulChange else { return }

        let updates = { [self] in
            apply(frame: targetFrame)
        }
        if animated, !UIAccessibility.isReduceMotionEnabled, presentedView.window != nil {
            UIView.animate(
                withDuration: BottomSheetTransition.heightUpdateDuration,
                delay: 0,
                options: [.beginFromCurrentState, .curveEaseInOut, .allowUserInteraction],
                animations: updates,
            )
        } else {
            updates()
        }
    }

    /// 将当前 controller state 对应的最终 frame 立即应用到 presented view。
    func applyCurrentFrame() {
        guard containerView != nil else { return }
        apply(frame: targetFrame())
    }

    /// 拖拽期间同步 dimming 的可见进度。
    func setDimmingProgress(_ progress: CGFloat) {
        dimmingProgress = min(max(progress, 0), 1)
        applyDimmingProgress()
    }

    /// 由 modal presenter 关闭整条 descendant presentation 链。
    func dismissSheet(animated: Bool, completion: (() -> Void)?) {
        guard let sheetViewController else {
            completion?()
            return
        }
        BottomSheetDismissalCoordinator.dismiss(
            viewController: sheetViewController,
            dismissalGate: sheetViewController.dismissalGate,
            animated: animated,
            completion: completion,
        )
    }

    private func applyDimmingProgress() {
        guard managesDimmingProgress else { return }
        dimmingContentView.alpha = dimmingProgress
    }

    private func removeDimmingViews() {
        dimmingContentView.removeFromSuperview()
        dimmingInteractionView.removeFromSuperview()
        dimmingView.removeFromSuperview()
    }

    private func targetFrame() -> CGRect {
        guard let containerView, let sheetViewController else { return .zero }

        let bounds = containerView.bounds
        let topSafeAreaInset = containerView.safeAreaInsets.top
        sheetViewController.updatePresentationLayoutContext(
            containerBounds: bounds,
            topSafeAreaInset: topSafeAreaInset,
        )
        let height = sheetViewController.resolvedHeight(
            containerBounds: bounds,
            topSafeAreaInset: topSafeAreaInset,
        )
        return BottomSheetGeometry.frame(height: height, in: bounds)
    }

    private func apply(frame: CGRect) {
        guard let presentedView else { return }

        presentedView.bounds = CGRect(origin: .zero, size: frame.size)
        presentedView.center = CGPoint(x: frame.midX, y: frame.midY)
        presentedView.setNeedsLayout()
        presentedView.layoutIfNeeded()
    }

    @objc
    private func didTapDimmingView() {
        sheetViewController?.requestDismissFromDimmingView()
    }
}
