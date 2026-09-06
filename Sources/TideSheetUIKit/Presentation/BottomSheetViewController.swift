//
//  BottomSheetViewController.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import TideSheet
import UIKit

/// A single native surface reused by modal presentation and child containment.
final class BottomSheetViewController: UIViewController {
    enum Metrics {
        static let heightEpsilon: CGFloat = 0.5
        static let grabberHitAreaHeight: CGFloat = 44
        static let grabberContentInset: CGFloat = 28
        static let grabberHandleSize = CGSize(width: 36, height: 5)
        static let detentAnimationDuration: TimeInterval = 0.35
    }

    let contentViewController: UIViewController
    let configuration: BottomSheetConfiguration
    let dismissalGate: BottomSheetDismissalGate
    weak var presentationContext: (any BottomSheetPresentationContext)?

    var selectedDetent: TideSheetDetent.Id
    var onSelectedDetentChange: ((TideSheetDetent.Id) -> Void)?
    var lastReportedDetent: TideSheetDetent.Id
    var detentAnimator: UIViewPropertyAnimator?
    var dragOrigin: TideSheetDetent.Id?
    var dragStartHeight: CGFloat = 0
    var interactiveHeightOverride: CGFloat?
    private(set) var presentationContainerBounds: CGRect = .zero
    private(set) var presentationTopSafeAreaInset: CGFloat = 0
    private(set) var isDismissalInFlight = false

    let surfaceView = UIView()
    let grabberAreaView = BottomSheetGrabberView()
    let grabberHandleView = UIView()
    private lazy var storedHandler = BottomSheetHandler(viewController: self)
    var handler: BottomSheetHandler {
        storedHandler
    }

    private var isHeightInvalidationScheduled = false
    private var pendingHeightInvalidationAnimated = false
    private var dismissalCompletions: [() -> Void] = []
    private var contentMeasurement: (width: CGFloat, height: CGFloat)?

    init(contentViewController: UIViewController, configuration: BottomSheetConfiguration, onDismiss: (() -> Void)? = nil) {
        precondition(contentViewController.parent == nil && contentViewController.presentingViewController == nil,
                     "Sheet content must not already belong to another controller.")
        self.contentViewController = contentViewController
        self.configuration = configuration
        selectedDetent = configuration.initialDetent
        lastReportedDetent = configuration.initialDetent
        dismissalGate = BottomSheetDismissalGate(handler: onDismiss)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        surfaceView.backgroundColor = configuration.surfaceColor
        surfaceView.clipsToBounds = true
        surfaceView.layer.cornerRadius = configuration.cornerRadius
        surfaceView.layer.cornerCurve = .continuous
        surfaceView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view = surfaceView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHierarchy()
        setupInteraction()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        invalidateContentSize(animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Normally the presentation context notifies after teardown. This only
        // covers a surface removed without its original presentation owner.
        if presentationContext == nil, presentingViewController == nil, parent == nil {
            notifyDismissIfNeeded()
        }
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        guard let child = container as? UIViewController, child === contentViewController else { return }
        invalidateContentSize(animated: true)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        invalidateContentSize(animated: false)
    }

    override func accessibilityPerformEscape() -> Bool {
        guard configuration.dismissesOnDimmingViewTap || configuration.dismissesOnSwipe else { return false }
        dismissSheet(animated: true, completion: nil)
        return true
    }

    override var childForStatusBarStyle: UIViewController? {
        contentViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        contentViewController
    }

    override var childForHomeIndicatorAutoHidden: UIViewController? {
        contentViewController
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        contentViewController.supportedInterfaceOrientations
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        contentViewController.preferredInterfaceOrientationForPresentation
    }

    override var shouldAutorotate: Bool {
        contentViewController.shouldAutorotate
    }

    func invalidateContentSize(animated: Bool) {
        guard !isDismissalInFlight, !dismissalGate.didNotify else { return }
        contentMeasurement = nil
        pendingHeightInvalidationAnimated = pendingHeightInvalidationAnimated || animated
        guard !isHeightInvalidationScheduled else { return }
        isHeightInvalidationScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            isHeightInvalidationScheduled = false
            let animated = pendingHeightInvalidationAnimated
            pendingHeightInvalidationAnimated = false
            guard !isDismissalInFlight, !dismissalGate.didNotify else { return }
            presentationContext?.invalidateLayout(animated: animated)
        }
    }

    func dismissSheet(animated: Bool, completion: (() -> Void)?) {
        guard !dismissalGate.didNotify else { completion?(); return }
        if let completion { dismissalCompletions.append(completion) }
        guard !isDismissalInFlight else { return }
        isDismissalInFlight = true
        dragOrigin = nil
        cancelDetentAnimationAtCurrentHeight()
        let completion = { [weak self] in
            guard let self else { return }
            let completions = dismissalCompletions
            dismissalCompletions.removeAll()
            completions.forEach { $0() }
        }
        if let presentationContext {
            presentationContext.dismissSheet(animated: animated, completion: completion)
        } else {
            BottomSheetDismissalCoordinator.dismiss(viewController: self, dismissalGate: dismissalGate,
                                                    animated: animated, completion: completion)
        }
    }

    func requestDismissFromDimmingView() {
        guard configuration.dismissesOnDimmingViewTap else { return }
        dismissSheet(animated: true, completion: nil)
    }

    func notifyDismissIfNeeded() {
        onSelectedDetentChange = nil
        detentAnimator?.stopAnimation(true)
        detentAnimator = nil
        dismissalGate.notifyIfNeeded()
    }

    func updatePresentationLayoutContext(containerBounds: CGRect, topSafeAreaInset: CGFloat) {
        let changed = presentationContainerBounds.size != containerBounds.size || presentationTopSafeAreaInset != topSafeAreaInset
        presentationContainerBounds = containerBounds
        presentationTopSafeAreaInset = topSafeAreaInset
        if changed { cancelDetentAnimationForLayoutChange() }
    }

    func resolvedLayout(containerBounds: CGRect, topSafeAreaInset: CGFloat) -> TideSheetDetentLayout? {
        let needsMeasurement = configuration.detents.contains { if case .content = $0.height { true } else { false } }
        let height = needsMeasurement ? measureContentHeight(width: containerBounds.width) : nil
        return TideSheetDetentLayout(
            detents: configuration.detents.sorted { $0.id.rawValue < $1.id.rawValue },
            availableHeight: BottomSheetGeometry.availableHeight(in: containerBounds, topSafeAreaInset: topSafeAreaInset),
            contentFittingSheetHeight: height,
        )
    }

    var currentLayout: TideSheetDetentLayout? {
        resolvedLayout(containerBounds: presentationContainerBounds, topSafeAreaInset: presentationTopSafeAreaInset)
    }

    func resolvedHeight(containerBounds: CGRect, topSafeAreaInset: CGFloat) -> CGFloat {
        if let interactiveHeightOverride {
            return min(max(0, interactiveHeightOverride), BottomSheetGeometry.availableHeight(in: containerBounds, topSafeAreaInset: topSafeAreaInset))
        }
        return resolvedLayout(containerBounds: containerBounds, topSafeAreaInset: topSafeAreaInset)?.restingPoint(for: selectedDetent)?.height ?? 0
    }

    private func setupHierarchy() {
        addChild(contentViewController)
        let content = contentViewController.view!
        content.translatesAutoresizingMaskIntoConstraints = false
        surfaceView.addSubview(content)
        grabberAreaView.translatesAutoresizingMaskIntoConstraints = false
        grabberHandleView.translatesAutoresizingMaskIntoConstraints = false
        surfaceView.addSubview(grabberAreaView)
        grabberAreaView.addSubview(grabberHandleView)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: surfaceView.topAnchor, constant: configuration.contentTopInset),
            content.leadingAnchor.constraint(equalTo: surfaceView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: surfaceView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: surfaceView.bottomAnchor),
            grabberAreaView.topAnchor.constraint(equalTo: surfaceView.topAnchor),
            grabberAreaView.leadingAnchor.constraint(equalTo: surfaceView.leadingAnchor),
            grabberAreaView.trailingAnchor.constraint(equalTo: surfaceView.trailingAnchor),
            grabberAreaView.heightAnchor.constraint(equalToConstant: Metrics.grabberContentInset),
            grabberHandleView.topAnchor.constraint(equalTo: grabberAreaView.topAnchor, constant: 8),
            grabberHandleView.centerXAnchor.constraint(equalTo: grabberAreaView.centerXAnchor),
            grabberHandleView.widthAnchor.constraint(equalToConstant: Metrics.grabberHandleSize.width),
            grabberHandleView.heightAnchor.constraint(equalToConstant: Metrics.grabberHandleSize.height),
        ])
        contentViewController.didMove(toParent: self)
    }

    private func measureContentHeight(width: CGFloat) -> CGFloat? {
        guard width.isFinite, width > 0 else { return nil }
        if let contentMeasurement, contentMeasurement.width == width { return contentMeasurement.height }
        contentViewController.loadViewIfNeeded()
        let preferred = contentViewController.preferredContentSize.height
        let measured: CGFloat = if preferred.isFinite, preferred > 0 {
            preferred
        } else {
            contentViewController.view.systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel,
            ).height
        }
        guard measured.isFinite, measured >= 0 else { return nil }
        let height = measured + configuration.contentTopInset
        guard height > 0 else { return nil }
        contentMeasurement = (width, height)
        return height
    }
}
