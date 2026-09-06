//
//  BottomSheetTransition.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import UIKit

enum BottomSheetTransition {
    static let presentationDuration: TimeInterval = 0.3
    static let dismissalDuration: TimeInterval = 0.25
    static let heightUpdateDuration: TimeInterval = 0.25
    static let offscreenSpacing: CGFloat = 20
}

@MainActor
final class BottomSheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    enum Operation {
        case present
        case dismiss
    }

    private let operation: Operation

    init(operation: Operation) {
        self.operation = operation
        super.init()
    }

    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        if UIAccessibility.isReduceMotionEnabled { return 0 }
        return duration
    }

    private var duration: TimeInterval {
        switch operation {
        case .present:
            BottomSheetTransition.presentationDuration
        case .dismiss:
            BottomSheetTransition.dismissalDuration
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch operation {
        case .present:
            animatePresentation(using: transitionContext)
        case .dismiss:
            animateDismissal(using: transitionContext)
        }
    }

    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let viewController = transitionContext.viewController(forKey: .to),
              let presentedView = transitionContext.view(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: viewController)
        apply(frame: finalFrame, to: presentedView)
        if presentedView.superview == nil {
            containerView.addSubview(presentedView)
        }
        presentedView.layoutIfNeeded()
        presentedView.transform = CGAffineTransform(
            translationX: 0,
            y: offscreenTranslation(for: presentedView, in: containerView),
        )

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                presentedView.transform = .identity
            },
            completion: { finished in
                let completed = finished && !transitionContext.transitionWasCancelled
                if !completed {
                    presentedView.removeFromSuperview()
                }
                transitionContext.completeTransition(completed)
            },
        )
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        let targetTranslation = offscreenTranslation(
            for: presentedView,
            in: transitionContext.containerView,
        )
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseIn],
            animations: {
                presentedView.transform = CGAffineTransform(translationX: 0, y: targetTranslation)
            },
            completion: { finished in
                let completed = finished && !transitionContext.transitionWasCancelled
                if completed {
                    presentedView.removeFromSuperview()
                } else {
                    presentedView.transform = .identity
                }
                transitionContext.completeTransition(completed)
            },
        )
    }

    private func apply(frame: CGRect, to view: UIView) {
        view.transform = .identity
        view.bounds = CGRect(origin: .zero, size: frame.size)
        view.center = CGPoint(x: frame.midX, y: frame.midY)
    }

    private func offscreenTranslation(for presentedView: UIView, in containerView: UIView) -> CGFloat {
        let untransformedMinY = presentedView.frame.minY - presentedView.transform.ty
        return max(containerView.bounds.maxY - untransformedMinY, 0) + BottomSheetTransition.offscreenSpacing
    }
}

extension BottomSheetViewController: UIViewControllerTransitioningDelegate {
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source _: UIViewController,
    ) -> UIPresentationController? {
        let presentationController = BottomSheetPresentationController(
            presentedViewController: presented,
            presenting: presenting,
        )
        presentationContext = presentationController
        return presentationController
    }

    func animationController(
        forPresented _: UIViewController,
        presenting _: UIViewController,
        source _: UIViewController,
    ) -> UIViewControllerAnimatedTransitioning? {
        BottomSheetAnimator(operation: .present)
    }

    func animationController(forDismissed _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        BottomSheetAnimator(operation: .dismiss)
    }
}
