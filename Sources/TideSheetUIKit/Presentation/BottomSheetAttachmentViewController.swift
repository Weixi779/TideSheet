//
//  BottomSheetAttachmentViewController.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import UIKit

/// 将 sheet 作为当前 route 的 child surface 承载，使其随宿主一起进入和退出导航栈。
@MainActor
final class BottomSheetAttachmentViewController: UIViewController, BottomSheetPresentationContext {
    private enum Phase: Equatable {
        case idle
        case presenting
        case presented
        case dismissing
        case dismissed
    }

    private enum AppearanceState: Equatable {
        case notVisible
        case appearing
        case visible
        case disappearing
    }

    let sheetViewController: BottomSheetViewController
    let dimmingView = UIView()
    let dimmingContentView: UIView
    let dimmingInteractionView = UIControl()

    private let allowsDimmingDismissal: Bool
    private let managesDimmingProgress: Bool
    private var dimmingProgress: CGFloat = 1
    private var phase: Phase = .idle
    private var forwardsInitialAppearance = false
    private var appearanceState: AppearanceState = .notVisible
    private var isRemovingFromHost = false
    private var isAwaitingHostExitTransition = false
    private var presentationCompletion: (() -> Void)?
    private var pendingDismissal: (animated: Bool, completion: (() -> Void)?)?

    init(sheetViewController: BottomSheetViewController) {
        self.sheetViewController = sheetViewController
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
        super.init(nibName: nil, bundle: nil)

        sheetViewController.presentationContext = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .clear
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDimmingView()
        setupSheetViewController()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        dimmingView.frame = view.bounds
        dimmingContentView.frame = dimmingView.bounds
        dimmingInteractionView.frame = dimmingView.bounds
        applyCurrentFrame()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appearanceState = .appearing
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appearanceState = .visible
        performPendingDismissalIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appearanceState = .disappearing
        guard phase != .dismissing,
              phase != .dismissed,
              isHostLeavingHierarchy,
              let transitionCoordinator else { return }

        isAwaitingHostExitTransition = true
        transitionCoordinator.animate(alongsideTransition: nil) { [weak self] context in
            guard let self else { return }
            isAwaitingHostExitTransition = false
            guard !context.isCancelled else { return }
            removeForHostExitIfNeeded()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        appearanceState = .notVisible
        if isHostLeavingHierarchy {
            if !isAwaitingHostExitTransition {
                removeForHostExitIfNeeded()
            }
            return
        }
        performPendingDismissalIfNeeded()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        guard parent == nil, !isRemovingFromHost else { return }
        removeForExternalDetachmentIfNeeded()
    }

    /// 在加入宿主视图前建立动态 child 所需的首次 appearance transition。
    func prepareForPresentation(forwardsInitialAppearance: Bool, animated: Bool) {
        loadViewIfNeeded()
        applyCurrentFrame()
        self.forwardsInitialAppearance = forwardsInitialAppearance
        if forwardsInitialAppearance {
            beginAppearanceTransition(true, animated: animated)
        }
    }

    /// 在 attachment 已加入宿主层级后执行入场动画。
    func startPresentation(animated: Bool, completion: (() -> Void)?) {
        guard phase == .idle else {
            completion?()
            return
        }
        phase = .presenting
        presentationCompletion = completion
        loadViewIfNeeded()
        applyCurrentFrame()
        if !sheetViewController.view.bounds.isEmpty {
            view.layoutIfNeeded()
        }

        if managesDimmingProgress {
            dimmingContentView.alpha = 0
        }
        dimmingInteractionView.isUserInteractionEnabled = false
        sheetViewController.view.isUserInteractionEnabled = false
        sheetViewController.view.transform = CGAffineTransform(
            translationX: 0,
            y: offscreenTranslation,
        )

        let animations = { [self] in
            sheetViewController.view.transform = .identity
            applyDimmingProgress()
        }
        let didFinish = { [weak self] in
            self?.finishPresentation()
        }

        guard animated, !UIAccessibility.isReduceMotionEnabled, view.window != nil else {
            animations()
            didFinish()
            return
        }
        UIView.animate(
            withDuration: BottomSheetTransition.presentationDuration,
            delay: 0,
            options: [.curveEaseOut],
            animations: animations,
            completion: { _ in didFinish() },
        )
    }

    /// 内容尺寸变化后重新求解并应用 sheet frame。
    func invalidateLayout(animated: Bool) {
        guard isViewLoaded, !view.bounds.isEmpty else { return }
        let targetFrame = targetFrame()
        let hasMeaningfulChange = abs(sheetViewController.view.bounds.height - targetFrame.height)
            > BottomSheetViewController.Metrics.heightEpsilon
            || abs(sheetViewController.view.bounds.width - targetFrame.width)
            > BottomSheetViewController.Metrics.heightEpsilon
        guard hasMeaningfulChange else { return }

        let updates = { [self] in
            apply(frame: targetFrame)
        }
        if animated, !UIAccessibility.isReduceMotionEnabled, view.window != nil {
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

    /// 将当前 controller state 对应的最终 frame 立即应用到 sheet view。
    func applyCurrentFrame() {
        guard isViewLoaded, !view.bounds.isEmpty else { return }
        apply(frame: targetFrame())
    }

    /// 拖拽期间同步组件管理的纯色遮罩进度。
    func setDimmingProgress(_ progress: CGFloat) {
        dimmingProgress = min(max(progress, 0), 1)
        applyDimmingProgress()
    }

    /// 只移除当前 route 持有的 attached surface，不改变导航栈。
    func dismissSheet(animated: Bool, completion: (() -> Void)?) {
        switch phase {
        case .idle, .presenting:
            pendingDismissal = (animated, completion)
            return
        case .presented:
            guard appearanceState != .appearing, appearanceState != .disappearing else {
                pendingDismissal = (animated, completion)
                return
            }
        case .dismissing:
            return
        case .dismissed:
            completion?()
            return
        }

        phase = .dismissing
        sheetViewController.view.endEditing(true)
        dimmingInteractionView.isUserInteractionEnabled = false
        sheetViewController.view.isUserInteractionEnabled = false
        let accessibilityReturnView = parent?.view
        let forwardsDismissalAppearance = appearanceState == .visible
        if forwardsDismissalAppearance {
            beginAppearanceTransition(false, animated: animated)
        }

        let animations = { [self] in
            sheetViewController.view.transform = CGAffineTransform(
                translationX: 0,
                y: offscreenTranslation,
            )
            if managesDimmingProgress {
                dimmingContentView.alpha = 0
            }
        }
        let didFinish = { [weak self] in
            guard let self else {
                completion?()
                return
            }
            if forwardsDismissalAppearance {
                endAppearanceTransition()
            }
            removeFromHost()
            phase = .dismissed
            sheetViewController.notifyDismissIfNeeded()
            UIAccessibility.post(notification: .screenChanged, argument: accessibilityReturnView)
            completion?()
        }

        guard animated, !UIAccessibility.isReduceMotionEnabled, view.window != nil else {
            animations()
            didFinish()
            return
        }
        UIView.animate(
            withDuration: BottomSheetTransition.dismissalDuration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseIn],
            animations: animations,
            completion: { _ in didFinish() },
        )
    }

    private var offscreenTranslation: CGFloat {
        let untransformedMinY = sheetViewController.view.frame.minY - sheetViewController.view.transform.ty
        return max(view.bounds.maxY - untransformedMinY, 0) + BottomSheetTransition.offscreenSpacing
    }

    private var isHostLeavingHierarchy: Bool {
        var ancestor = parent
        while let viewController = ancestor {
            if viewController.isMovingFromParent || viewController.isBeingDismissed {
                return true
            }
            ancestor = viewController.parent
        }
        return false
    }

    private func finishPresentation() {
        guard phase == .presenting else { return }
        if forwardsInitialAppearance {
            endAppearanceTransition()
            forwardsInitialAppearance = false
        }
        phase = .presented
        dimmingInteractionView.isUserInteractionEnabled = allowsDimmingDismissal
        sheetViewController.view.isUserInteractionEnabled = true
        view.accessibilityElements = allowsDimmingDismissal
            ? [sheetViewController.view as Any, dimmingInteractionView]
            : [sheetViewController.view as Any]
        UIAccessibility.post(notification: .screenChanged, argument: sheetViewController.view)

        let completion = presentationCompletion
        presentationCompletion = nil
        completion?()
        performPendingDismissalIfNeeded()
    }

    private func performPendingDismissalIfNeeded() {
        guard phase == .presented,
              appearanceState != .appearing,
              appearanceState != .disappearing,
              let pendingDismissal else { return }

        self.pendingDismissal = nil
        dismissSheet(animated: pendingDismissal.animated, completion: pendingDismissal.completion)
    }

    private func removeForHostExitIfNeeded() {
        guard phase != .dismissing, phase != .dismissed else { return }

        let presentationCompletion = presentationCompletion
        let dismissalCompletion = pendingDismissal?.completion
        self.presentationCompletion = nil
        pendingDismissal = nil
        if forwardsInitialAppearance {
            endAppearanceTransition()
        }
        phase = .dismissed
        forwardsInitialAppearance = false
        removeFromHost()
        sheetViewController.notifyDismissIfNeeded()
        presentationCompletion?()
        dismissalCompletion?()
    }

    private func removeForExternalDetachmentIfNeeded() {
        guard phase != .dismissed else { return }
        let presentationCompletion = presentationCompletion
        let dismissalCompletion = pendingDismissal?.completion
        self.presentationCompletion = nil
        pendingDismissal = nil
        if forwardsInitialAppearance {
            endAppearanceTransition()
            forwardsInitialAppearance = false
        }
        phase = .dismissed
        sheetViewController.presentationContext = nil
        sheetViewController.notifyDismissIfNeeded()
        presentationCompletion?()
        dismissalCompletion?()
    }

    private func setupDimmingView() {
        dimmingView.frame = view.bounds
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

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
        view.addSubview(dimmingView)
        view.accessibilityViewIsModal = true
    }

    private func setupSheetViewController() {
        addChild(sheetViewController)
        view.addSubview(sheetViewController.view)
        sheetViewController.didMove(toParent: self)
    }

    private func targetFrame() -> CGRect {
        let bounds = view.bounds
        let topSafeAreaInset = view.safeAreaInsets.top
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
        sheetViewController.view.bounds = CGRect(origin: .zero, size: frame.size)
        sheetViewController.view.center = CGPoint(x: frame.midX, y: frame.midY)
        sheetViewController.view.setNeedsLayout()
        sheetViewController.view.layoutIfNeeded()
    }

    private func applyDimmingProgress() {
        guard managesDimmingProgress else { return }
        dimmingContentView.alpha = dimmingProgress
    }

    private func removeFromHost() {
        isRemovingFromHost = true
        sheetViewController.presentationContext = nil
        sheetViewController.willMove(toParent: nil)
        sheetViewController.view.removeFromSuperview()
        sheetViewController.removeFromParent()

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
        isRemovingFromHost = false
    }

    @objc
    private func didTapDimmingView() {
        sheetViewController.requestDismissFromDimmingView()
    }
}
