//
//  AttachedSheetHost.swift
//  TideSheet
//
//  Created by weixi on 2026/9/7.
//

import Combine
import SwiftUI
import UIKit

struct AttachedSheetHost<Item: Identifiable, SheetContent: View>: View {
    let input: SheetPresentationInput<Item>
    let state: SheetPresentationState<Item>
    let sheetContent: (Item) -> SheetContent

    var body: some View {
        SheetAttachmentAnchor(isPresented: state.presentation != nil) {
            GeometryReader { geometry in
                if let presentation = state.presentation {
                    let safeArea = geometry.safeAreaInsets
                    SheetPresentationContent(
                        input: input,
                        state: state,
                        presentation: presentation,
                        availableHeight: geometry.size.height + safeArea.bottom,
                        onDismissed: { state.finishDismissal(presentation.id) },
                        sheetContent: sheetContent,
                    )
                    .frame(
                        width: geometry.size.width + safeArea.leading + safeArea.trailing,
                        height: geometry.size.height + safeArea.top + safeArea.bottom,
                    )
                    .offset(x: -safeArea.leading, y: -safeArea.top)
                    .id(presentation.id)
                }
            }
            .onReceive(Just((input.item.wrappedValue, input.selection.value))) { _ in state.update(input) }
        }
    }
}

/// The anchor stays in the declaring page. Only the rendering container sits
/// above navigation chrome; it never presents a modal or replaces a navigation delegate.
private struct SheetAttachmentAnchor<Content: View>: UIViewControllerRepresentable {
    let isPresented: Bool
    @ViewBuilder let content: () -> Content

    func makeUIViewController(context: Context) -> SheetAttachmentController<Content> {
        SheetAttachmentController(root: SheetAttachmentRoot(content: content(), values: context.environment))
    }

    func updateUIViewController(_ controller: SheetAttachmentController<Content>, context: Context) {
        controller.update(
            root: SheetAttachmentRoot(content: content(), values: context.environment),
            isPresented: isPresented,
        )
    }

    static func dismantleUIViewController(_ controller: SheetAttachmentController<Content>, coordinator _: ()) {
        controller.detach()
    }
}

private struct SheetAttachmentRoot<Content: View>: View {
    let content: Content
    let values: EnvironmentValues

    var body: some View {
        content.environment(\.self, values)
    }
}

private final class SheetAttachmentController<Content: View>: UIViewController {
    private var root: SheetAttachmentRoot<Content>
    private var hosting: UIHostingController<SheetAttachmentRoot<Content>>?
    private var canvas: SheetAttachmentCanvas?
    private weak var owner: UIViewController?
    private weak var rootController: UIViewController?
    private weak var area: UIView?
    private var isPresented = false
    private var transitionRevision = 0
    private var isForwardingAppearance = false

    init(root: SheetAttachmentRoot<Content>) {
        self.root = root
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }

    func update(root: SheetAttachmentRoot<Content>, isPresented: Bool) {
        self.root = root
        self.isPresented = isPresented
        hosting?.rootView = root
        if isPresented {
            mountIfNeeded()
        } else {
            detach()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mountIfNeeded()
        followPage(appearing: true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mountIfNeeded()
        settleVisibility()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        followPage(appearing: false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        settleVisibility()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutCarrier()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.layoutCarrier()
        }, completion: { [weak self] _ in
            self?.layoutCarrier()
        })
    }

    private func mountIfNeeded() {
        guard isPresented, hosting == nil, viewIfLoaded?.window != nil,
              var page = parent else { return }
        // Resolve only this anchor's own containment chain, never another scene,
        // a presented controller, or a global "top-most" presenter.
        while let container = page.parent,
              !(container is UINavigationController), !(container is UITabBarController)
        {
            page = container
        }
        owner = page
        // UINavigationController treats direct children as navigation entries.
        // Render beside the local root, constrained to this navigation area.
        let navigation = page.navigationController
        let area = navigation?.view ?? page.view!
        // SwiftUI exclusively manages the contents of its hosting view. Render
        // beside that view in its existing UIKit superview, as a locally owned
        // carrier, rather than inserting a foreign subview into SwiftUI's tree.
        var rootController = page
        while let parent = rootController.parent {
            rootController = parent
        }
        guard let superview = rootController.view.superview else { return }
        self.rootController = rootController
        self.area = area
        let canvas = SheetAttachmentCanvas()
        self.canvas = canvas
        let hosting = UIHostingController(rootView: root)
        hosting.view.backgroundColor = .clear
        hosting.view.accessibilityIdentifier = "TideSheet.AttachedContainer"
        hosting.view.accessibilityViewIsModal = true
        self.hosting = hosting
        // This is a sibling of the root view, so it has no parent controller.
        // The page anchor retains it and explicitly forwards appearance/teardown.
        hosting.beginAppearanceTransition(true, animated: false)
        superview.addSubview(canvas)
        canvas.addSubview(hosting.view)
        layoutCarrier()
        hosting.endAppearanceTransition()
        settleVisibility()
    }

    private func layoutCarrier() {
        guard let hosting, let canvas, let rootController, let area else { return }
        let rootView = rootController.view!
        // Root view transforms carry interface rotation. Cross-tree constraints
        // alone give the right size but leave the sibling surface unrotated.
        canvas.bounds = rootView.bounds
        canvas.center = rootView.center
        canvas.transform = rootView.transform
        hosting.view.frame = rootView.convert(area.bounds, from: area)
    }

    private var isPageVisible: Bool {
        guard let owner else { return false }
        if let navigation = owner.navigationController {
            return navigation.topViewController === owner
        }
        return viewIfLoaded?.window != nil
    }

    private func followPage(appearing: Bool, animated: Bool) {
        guard let hosting else { return }
        // Modal presentation of the page does not change its position in navigation.
        guard let coordinator = transitionCoordinator,
              let owner,
              let navigation = owner.navigationController,
              let from = coordinator.viewController(forKey: .from),
              let to = coordinator.viewController(forKey: .to),
              from === owner || to === owner,
              from.parent === navigation || to.parent === navigation,
              !from.isBeingPresented, !to.isBeingPresented,
              !from.isBeingDismissed, !to.isBeingDismissed else { return }

        transitionRevision += 1
        let revision = transitionRevision
        finishAppearance()
        hosting.beginAppearanceTransition(appearing, animated: animated)
        isForwardingAppearance = true
        hosting.view.isHidden = false
        canvas?.isHidden = false
        hosting.view.isUserInteractionEnabled = false
        if appearing {
            hosting.view.alpha = 0
            if let canvas { canvas.superview?.bringSubviewToFront(canvas) }
        }
        coordinator.animateAlongsideTransition(in: hosting.view, animation: { _ in
            hosting.view.alpha = appearing ? 1 : 0
        }, completion: { [weak self] _ in
            guard let self, revision == transitionRevision else { return }
            finishAppearance()
            settleVisibility()
        })
    }

    private func settleVisibility() {
        guard let hosting else { return }
        let visible = isPageVisible
        hosting.view.isHidden = !visible
        canvas?.isHidden = !visible
        hosting.view.alpha = visible ? 1 : 0
        hosting.view.isUserInteractionEnabled = visible
        if visible, let canvas { canvas.superview?.bringSubviewToFront(canvas) }
    }

    private func finishAppearance() {
        guard isForwardingAppearance else { return }
        hosting?.endAppearanceTransition()
        isForwardingAppearance = false
    }

    func detach() {
        transitionRevision += 1
        finishAppearance()
        guard let hosting else { return }
        hosting.beginAppearanceTransition(false, animated: false)
        hosting.view.removeFromSuperview()
        canvas?.removeFromSuperview()
        hosting.endAppearanceTransition()
        self.hosting = nil
        canvas = nil
        owner = nil
        rootController = nil
        area = nil
    }
}

private final class SheetAttachmentCanvas: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }
}
