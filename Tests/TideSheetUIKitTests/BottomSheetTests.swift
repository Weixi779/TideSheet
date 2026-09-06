//
//  BottomSheetTests.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import Testing
import TideSheet
@testable import TideSheetUIKit
import UIKit

@Suite("UIKit sheet geometry and ownership")
struct BottomSheetTests {
    private let compact = TideSheetDetent(id: .init(rawValue: "compact"), height: .fixed(300))
    private let maximum = TideSheetDetent(id: .init(rawValue: "maximum"), height: .maximum)
    private let fitting = TideSheetDetent(id: .init(rawValue: "content"), height: .content())
    private let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)

    @Test
    func `Fixed detents do not read or measure content`() {
        let content = MeasuredContent(preferredHeight: 150)
        let sheet = makeSheet(content, detents: [compact], initial: compact.id)
        sheet.loadViewIfNeeded()
        content.preferredReads = 0
        #expect(sheet.resolvedHeight(containerBounds: bounds, topSafeAreaInset: 44) == 300)
        #expect(content.preferredReads == 0)
        #expect(content.measuredView.widths.isEmpty)
    }

    @Test
    func `Content measurement includes chrome but no added safe area`() {
        let content = MeasuredContent(preferredHeight: 150)
        let sheet = makeSheet(content, detents: [fitting], initial: fitting.id)
        #expect(sheet.resolvedHeight(containerBounds: bounds, topSafeAreaInset: 44) == 178)
        #expect(content.measuredView.widths.isEmpty)
        content.preferredHeight = 210
        sheet.invalidateContentSize(animated: false)
        #expect(sheet.resolvedHeight(containerBounds: bounds, topSafeAreaInset: 44) == 238)
    }

    @Test
    func `Auto Layout measurement uses container width and remeasures on invalidation`() {
        let content = MeasuredContent(preferredHeight: 0)
        let sheet = makeSheet(content, detents: [fitting], initial: fitting.id)
        #expect(sheet.resolvedHeight(containerBounds: bounds, topSafeAreaInset: 44) == 218)
        #expect(content.measuredView.widths == [390])
        _ = sheet.resolvedHeight(containerBounds: bounds, topSafeAreaInset: 44)
        #expect(content.measuredView.widths == [390])
        let narrow = CGRect(x: 0, y: 0, width: 320, height: 600)
        #expect(sheet.resolvedHeight(containerBounds: narrow, topSafeAreaInset: 0) == 148)
        #expect(content.measuredView.widths == [390, 320])
        sheet.invalidateContentSize(animated: false)
        _ = sheet.resolvedHeight(containerBounds: narrow, topSafeAreaInset: 0)
        #expect(content.measuredView.widths == [390, 320, 320])
    }

    @Test
    func `Real Auto Layout content fits at the available width after containment`() {
        let content = UIViewController()
        let label = UILabel()
        label.text = String(repeating: "Content owns its layout. ", count: 12)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        content.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: content.view.topAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: content.view.bottomAnchor, constant: -20),
            label.leadingAnchor.constraint(equalTo: content.view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: content.view.trailingAnchor, constant: -20),
        ])
        let sheet = makeSheet(content, detents: [fitting], initial: fitting.id)
        sheet.loadViewIfNeeded()
        let height = sheet.resolvedHeight(containerBounds: bounds, topSafeAreaInset: 44)
        let expected = label.sizeThatFits(CGSize(width: 350, height: CGFloat.greatestFiniteMagnitude)).height + 40 + 28
        #expect(abs(height - expected) < 1)
    }

    @Test
    func `Selection survives coalesced heights and container changes`() {
        let sheet = makeSheet(UIViewController(), detents: [compact, maximum], initial: maximum.id)
        let small = CGRect(x: 0, y: 0, width: 390, height: 344)
        sheet.updatePresentationLayoutContext(containerBounds: small, topSafeAreaInset: 44)
        #expect(sheet.currentLayout?.restingPoints.count == 1)
        #expect(sheet.handler.selectedDetent == maximum.id)
        sheet.updatePresentationLayoutContext(containerBounds: bounds, topSafeAreaInset: 44)
        #expect(sheet.currentLayout?.restingPoints.count == 2)
        #expect(sheet.resolvedHeight(containerBounds: bounds, topSafeAreaInset: 44) == 800)
        #expect(sheet.handler.selectedDetent == maximum.id)
    }

    @Test
    func `Content can fill the surface and owns its safe area`() {
        let content = UIViewController()
        let sheet = BottomSheetViewController(contentViewController: content, configuration: .init(
            detents: [compact], initialDetent: compact.id, contentTopInset: 0,
        ))
        sheet.view.frame = CGRect(x: 0, y: 0, width: 390, height: 300)
        sheet.view.layoutIfNeeded()
        #expect(content.parent === sheet)
        #expect(content.view.frame == sheet.view.bounds)
        #expect(content.additionalSafeAreaInsets == .zero)
        #expect(sheet.additionalSafeAreaInsets == .zero)
    }

    @Test
    func `Unknown IDs and ended presentation actions cannot change selection`() {
        var dismissals = 0
        var changes: [TideSheetDetent.Id] = []
        let sheet = makeSheet(UIViewController(), detents: [compact, maximum], initial: compact.id, onDismiss: { dismissals += 1 })
        let handler = sheet.handler
        handler.onSelectedDetentChange = { changes.append($0) }
        handler.selectDetent(.init(rawValue: "missing"), animated: false)
        #expect(handler.selectedDetent == compact.id)
        handler.selectDetent(maximum.id, animated: false)
        handler.selectDetent(maximum.id, animated: false)
        #expect(changes == [maximum.id])
        sheet.notifyDismissIfNeeded()
        sheet.notifyDismissIfNeeded()
        handler.selectDetent(compact.id, animated: false)
        var completions = 0
        handler.dismiss(animated: false) { completions += 1 }
        #expect(handler.selectedDetent == nil)
        #expect(sheet.selectedDetent == maximum.id)
        #expect(dismissals == 1)
        #expect(completions == 1)
    }

    @Test
    func `Handler does not retain its sheet`() throws {
        var sheet: BottomSheetViewController? = makeSheet(UIViewController(), detents: [compact], initial: compact.id)
        let handler = try #require(sheet?.handler)
        weak var weakSheet = sheet
        sheet = nil
        #expect(weakSheet == nil)
        #expect(handler.selectedDetent == nil)
        var completed = false
        handler.dismiss { completed = true }
        #expect(completed)
    }

    @Test
    func `Drag chooses physical positions and keeps coalesced logical identity`() throws {
        let alias = TideSheetDetent(id: .init(rawValue: "alias"), height: .fixed(300))
        let third = TideSheetDetent(id: .init(rawValue: "third"), height: .fixed(500))
        let layout = try #require(TideSheetDetentLayout(detents: [alias, compact, third, maximum], availableHeight: 800))
        #expect(BottomSheetDetentMotion.destination(currentHeight: 300, velocityY: 0, movingDown: false,
                                                    layout: layout, selectedDetent: compact.id, allowsDismissal: true) == compact.id)
        #expect(BottomSheetDetentMotion.destination(currentHeight: 490, velocityY: 0, movingDown: false,
                                                    layout: layout, selectedDetent: compact.id, allowsDismissal: true) == third.id)
        #expect(BottomSheetDetentMotion.destination(currentHeight: 100, velocityY: 100, movingDown: true,
                                                    layout: layout, selectedDetent: compact.id, allowsDismissal: true) == nil)
        #expect(BottomSheetDetentMotion.destination(currentHeight: 100, velocityY: 100, movingDown: true,
                                                    layout: layout, selectedDetent: compact.id, allowsDismissal: false) == compact.id)
    }

    @Test
    func `Attached content receives appearance and is removed before dismissal notification`() throws {
        let host = UIViewController()
        host.view.frame = bounds
        let content = AppearanceContent()
        var dismissals = 0
        let handler = host.attachBottomSheet(content, configuration: .init(detents: [compact, maximum], initialDetent: compact.id), animated: false) {
            #expect(host.children.isEmpty)
            dismissals += 1
        }
        let attachment = try #require(host.children.first as? BottomSheetAttachmentViewController)
        attachment.beginAppearanceTransition(true, animated: false)
        attachment.endAppearanceTransition()
        #expect(content.events == ["willAppear", "didAppear"])
        handler.selectDetent(maximum.id, animated: false)
        #expect(attachment.sheetViewController.view.bounds.height == 844)
        handler.dismiss(animated: false)
        #expect(content.events.suffix(2) == ["willDisappear", "didDisappear"])
        #expect(attachment.parent == nil)
        #expect(attachment.sheetViewController.parent == nil)
        #expect(dismissals == 1)
    }

    @Test(arguments: [false, true])
    func `Custom backdrop opacity remains content owned`(attached: Bool) throws {
        let custom = UIView()
        custom.alpha = 0.7
        let configuration = BottomSheetConfiguration(detents: [compact], initialDetent: compact.id, dimmingBackground: .custom { custom })
        let host = UIViewController()
        host.view.frame = bounds
        if attached {
            let handler = host.attachBottomSheet(UIViewController(), configuration: configuration, animated: false)
            let attachment = try #require(host.children.first as? BottomSheetAttachmentViewController)
            attachment.setDimmingProgress(0.2)
            #expect(abs(custom.alpha - 0.7) < 0.0001)
            handler.dismiss(animated: false)
            #expect(attachment.view.superview == nil)
        } else {
            let sheet = BottomSheetViewController(contentViewController: UIViewController(), configuration: configuration)
            let controller = BottomSheetPresentationController(presentedViewController: sheet, presenting: host)
            controller.setDimmingProgress(0.2)
            #expect(abs(custom.alpha - 0.7) < 0.0001)
            controller.presentationTransitionDidEnd(false)
            #expect(custom.superview == nil)
        }
    }

    private func makeSheet(_ content: UIViewController, detents: Set<TideSheetDetent>, initial: TideSheetDetent.Id, onDismiss: (() -> Void)? = nil) -> BottomSheetViewController {
        BottomSheetViewController(contentViewController: content, configuration: .init(detents: detents, initialDetent: initial), onDismiss: onDismiss)
    }
}

private final class MeasuredContent: UIViewController {
    var preferredHeight: CGFloat
    var preferredReads = 0
    let measuredView = MeasuredView()

    init(preferredHeight: CGFloat) {
        self.preferredHeight = preferredHeight
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredContentSize: CGSize {
        get { preferredReads += 1; return CGSize(width: 0, height: preferredHeight) }
        set {}
    }

    override func loadView() {
        view = measuredView
    }
}

private final class MeasuredView: UIView {
    var widths: [CGFloat] = []
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority _: UILayoutPriority, verticalFittingPriority _: UILayoutPriority) -> CGSize {
        widths.append(targetSize.width)
        return CGSize(width: targetSize.width, height: targetSize.width - 200)
    }
}

private final class AppearanceContent: UIViewController {
    var events: [String] = []
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated); events.append("willAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated); events.append("didAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated); events.append("willDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated); events.append("didDisappear")
    }
}
