//
//  SwiftUIContentExample.swift
//  TideSheet
//
//  Created by weixi on 2026/9/7.
//

import Observation
import SwiftUI
import TideSheet
import TideSheetUIKit
import UIKit

/// Application-owned bridge using UIHostingController and the existing VC API.
final class SwiftUIContentExample: UIViewController {
    private let isAttached: Bool
    private let status = UILabel()
    private var dismissals = 0
    private var lastHandler: BottomSheetHandler?

    init(isAttached: Bool) {
        self.isAttached = isAttached
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = isAttached ? "SwiftUI in attached UIKit" : "SwiftUI in modal UIKit"
        view.backgroundColor = .systemGroupedBackground
        status.text = "Dismissals: 0"
        status.textAlignment = .center
        let open = UIButton(type: .system)
        open.setTitle("Open SwiftUI content", for: .normal)
        open.addAction(UIAction { [weak self] _ in self?.openSheet() }, for: .touchUpInside)
        let oldAction = UIButton(type: .system)
        oldAction.setTitle("Dismiss old presentation", for: .normal)
        oldAction.addAction(UIAction { [weak self] _ in self?.lastHandler?.dismiss() }, for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [status, open, oldAction])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func openSheet() {
        let model = HostedContentModel()
        let controller = UIHostingController(rootView: HostedContent(model: model))
        controller.view.backgroundColor = .clear
        // Measure this content's intrinsic body at its actual SwiftUI width.
        // The outer hosting view continues to fill the UIKit content area.
        model.onSizeChange = { [weak controller] size in
            guard controller?.preferredContentSize != size else { return }
            controller?.preferredContentSize = size
        }
        model.onNavigate = { [weak self] in
            let detail = UIViewController()
            detail.title = "Bridge detail"
            detail.view.backgroundColor = .systemTeal
            self?.navigationController?.pushViewController(detail, animated: true)
        }
        let configuration = BottomSheetConfiguration(
            detents: BridgeDetents.all,
            initialDetent: BridgeDetents.compact.id,
        )
        let onDismiss = { [weak self] in
            guard let self else { return }
            dismissals += 1
            status.text = "Dismissals: \(dismissals)"
        }
        let handler = presentBottomSheet(controller, presentation: isAttached ? .attached : .modal,
                                         configuration: configuration, onDismiss: onDismiss)
        model.handler = handler
        model.selection = handler.selectedDetent?.rawValue ?? "compact"
        handler.onSelectedDetentChange = { [weak model] id in model?.selection = id.rawValue }
        lastHandler = handler
    }
}

private enum BridgeDetents {
    static let compact = TideSheetDetent(id: .init(rawValue: "compact"), height: .fixed(520))
    static let content = TideSheetDetent(id: .init(rawValue: "content"), height: .content())
    static let maximum = TideSheetDetent(id: .init(rawValue: "maximum"), height: .maximum)
    static let all: Set<TideSheetDetent> = [compact, content, maximum]
}

@Observable
private final class HostedContentModel {
    var selection = "compact"
    var title = "Hosted SwiftUI content"
    var handler: BottomSheetHandler?
    var onNavigate: (() -> Void)?
    var onSizeChange: ((CGSize) -> Void)?
}

private struct HostedContent: View {
    let model: HostedContentModel
    @State private var count = 0
    @State private var expandedContent = false

    var body: some View {
        VStack(spacing: 12) {
            Text(model.title).font(.headline)
            Text("Selection: \(model.selection)")
            HStack {
                Button("Content") { model.handler?.selectDetent(BridgeDetents.content.id) }
                Button("Maximum") { model.handler?.selectDetent(BridgeDetents.maximum.id) }
            }
            Button("Hosted count \(count)") { count += 1 }
            Button("Update title") { model.title = "Updated hosted title" }
            Button("Resize hosted content") { expandedContent.toggle() }
            if expandedContent {
                Text("This SwiftUI content measures its intrinsic body at the available width and reports that size through preferredContentSize.")
                    .frame(height: 110)
            }
            Button("Push from hosted content") { model.onNavigate?() }
            Button("Close hosted content") { model.handler?.dismiss() }
            Button("Close hosted then navigate") {
                model.handler?.dismiss(completion: model.onNavigate)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGSize.self, of: { $0.size }) { model.onSizeChange?($0) }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .buttonStyle(.bordered)
    }
}
