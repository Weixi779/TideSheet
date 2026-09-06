//
//  BottomSheetInteraction.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import TideSheet
import UIKit

extension BottomSheetViewController {
    func setupInteraction() {
        grabberAreaView.accessibilityLabel = "Resize sheet"
        grabberAreaView.onIncrement = { [weak self] in self?.adjustSelection(by: 1) }
        grabberAreaView.onDecrement = { [weak self] in self?.adjustSelection(by: -1) }
        grabberHandleView.backgroundColor = configuration.grabberColor
        grabberHandleView.layer.cornerRadius = Metrics.grabberHandleSize.height / 2
        grabberHandleView.isUserInteractionEnabled = false
        grabberAreaView.accessibilityValue = selectedDetent.rawValue
        let pan = UIPanGestureRecognizer(target: self, action: #selector(didPanDetents(_:)))
        pan.delegate = self
        surfaceView.addGestureRecognizer(pan)
    }

    func selectDetent(_ id: TideSheetDetent.Id, animated: Bool) {
        guard !isDismissalInFlight, !dismissalGate.didNotify,
              configuration.detents.contains(where: { $0.id == id }), selectedDetent != id else { return }
        settleDetent(to: id, animated: animated)
    }

    func settleDetent(to id: TideSheetDetent.Id, animated: Bool) {
        cancelDetentAnimationAtCurrentHeight()
        selectedDetent = id
        dragOrigin = nil
        guard let target = currentLayout?.restingPoint(for: id)?.height else {
            interactiveHeightOverride = nil
            completeDetentSelection(id)
            return
        }
        interactiveHeightOverride = target
        let updates = { [self] in
            presentationContext?.applyCurrentFrame()
            presentationContext?.setDimmingProgress(1)
        }
        guard animated, !UIAccessibility.isReduceMotionEnabled, view.window != nil, presentationContext != nil else {
            updates()
            interactiveHeightOverride = nil
            presentationContext?.applyCurrentFrame()
            completeDetentSelection(id)
            return
        }
        let animator = UIViewPropertyAnimator(duration: Metrics.detentAnimationDuration, dampingRatio: 0.9, animations: updates)
        detentAnimator = animator
        animator.addCompletion { [weak self, weak animator] position in
            guard let self, let animator, detentAnimator === animator else { return }
            detentAnimator = nil
            guard position == .end else { return }
            interactiveHeightOverride = nil
            presentationContext?.applyCurrentFrame()
            completeDetentSelection(id)
        }
        animator.startAnimation()
    }

    @discardableResult
    func cancelDetentAnimationAtCurrentHeight() -> CGFloat {
        let visibleHeight = view.layer.presentation()?.bounds.height ?? view.bounds.height
        guard let animator = detentAnimator else { return visibleHeight }
        animator.stopAnimation(true)
        detentAnimator = nil
        interactiveHeightOverride = visibleHeight
        presentationContext?.applyCurrentFrame()
        return visibleHeight
    }

    func cancelDetentAnimationForLayoutChange() {
        detentAnimator?.stopAnimation(true)
        detentAnimator = nil
        interactiveHeightOverride = nil
        dragOrigin = nil
        completeDetentSelection(selectedDetent)
    }

    private func completeDetentSelection(_ id: TideSheetDetent.Id) {
        grabberAreaView.accessibilityValue = id.rawValue
        guard !isDismissalInFlight, !dismissalGate.didNotify, lastReportedDetent != id else { return }
        lastReportedDetent = id
        onSelectedDetentChange?(id)
    }

    private func adjustSelection(by step: Int) {
        guard let layout = currentLayout,
              let index = layout.restingPoints.firstIndex(where: { $0.detentIds.contains(selectedDetent) }),
              layout.restingPoints.indices.contains(index + step) else { return }
        selectDetent(layout.restingPoints[index + step].detentIds[0], animated: true)
    }

    @objc
    private func didPanDetents(_ recognizer: UIPanGestureRecognizer) {
        guard !isDismissalInFlight, !dismissalGate.didNotify, let layout = currentLayout,
              let lowest = layout.restingPoints.first, let highest = layout.restingPoints.last else { return }
        // The sheet moves during a drag, so translation is measured in its window.
        let translation = recognizer.translation(in: view.window).y
        switch recognizer.state {
        case .began:
            dragOrigin = selectedDetent
            dragStartHeight = cancelDetentAnimationAtCurrentHeight()
        case .changed:
            guard dragOrigin != nil else { return }
            let minimum = configuration.dismissesOnSwipe ? 0 : lowest.height
            let height = min(highest.height, max(minimum, dragStartHeight - translation))
            interactiveHeightOverride = height
            presentationContext?.applyCurrentFrame()
            presentationContext?.setDimmingProgress(min(1, height / lowest.height))
        case .ended:
            guard dragOrigin != nil else { return }
            let destination = BottomSheetDetentMotion.destination(
                currentHeight: interactiveHeightOverride ?? view.bounds.height,
                velocityY: recognizer.velocity(in: view.window).y,
                movingDown: translation > 0,
                layout: layout,
                selectedDetent: selectedDetent,
                allowsDismissal: configuration.dismissesOnSwipe,
            )
            if let destination { settleDetent(to: destination, animated: true) }
            else { dismissSheet(animated: true, completion: nil) }
        case .cancelled, .failed:
            guard let dragOrigin else { return }
            settleDetent(to: dragOrigin, animated: true)
        default:
            break
        }
    }
}

extension BottomSheetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touch.location(in: surfaceView).y <= Metrics.grabberHitAreaHeight
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !isDismissalInFlight, !dismissalGate.didNotify,
              let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = pan.velocity(in: view.window)
        return abs(velocity.y) > abs(velocity.x)
    }
}

final class BottomSheetGrabberView: UIView {
    var onIncrement: (() -> Void)?
    var onDecrement: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityTraits = .adjustable
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func accessibilityIncrement() {
        onIncrement?()
    }

    override func accessibilityDecrement() {
        onDecrement?()
    }
}
