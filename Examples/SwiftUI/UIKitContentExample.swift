//
//  UIKitContentExample.swift
//  TideSheet
//
//  Created by weixi on 2026/9/7.
//

import SwiftUI
import TideSheet
import TideSheetSwiftUI
import UIKit

struct UIKitContentExample: View {
    let isAttached: Bool
    let onNavigate: () -> Void
    @State private var item: ControllerItem?
    @State private var dismissals = 0

    var body: some View {
        presentation
            .navigationTitle("UIKit in SwiftUI")
            .navigationBarTitleDisplayMode(.inline)
    }

    private var host: some View {
        VStack(spacing: 20) {
            Text("Dismissals: \(dismissals)")
            Button("Open UIKit content") { item = ControllerItem(id: 1, title: "Controller item 1") }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.blue.opacity(0.06))
    }

    private var presentation: some View {
        host.bottomSheet(item: $item, presentation: isAttached ? .attached : .modal,
                         detents: ControllerDetents.all, initialDetent: ControllerDetents.compact.id,
                         onDismiss: { dismissals += 1 }, content: content)
    }

    private func content(_ item: ControllerItem) -> some View {
        ControllerContent(
            title: item.title,
            updateItem: { self.item?.title = "Updated controller item" },
            replaceItem: { self.item = ControllerItem(id: 2, title: "Controller item 2") },
            onNavigate: onNavigate,
        )
    }
}

private struct ControllerItem: Identifiable {
    let id: Int
    var title: String
}

private enum ControllerDetents {
    static let compact = TideSheetDetent(id: .init(rawValue: "compact"), height: .fixed(520))
    static let content = TideSheetDetent(id: .init(rawValue: "content"), height: .content())
    static let maximum = TideSheetDetent(id: .init(rawValue: "maximum"), height: .maximum)
    static let all: Set<TideSheetDetent> = [compact, content, maximum]
}

/// This concrete content reports its preferred height into SwiftUI layout.
private struct ControllerContent: View {
    let title: String
    let updateItem: () -> Void
    let replaceItem: () -> Void
    let onNavigate: () -> Void
    @Environment(\.sheet) private var sheet
    @State private var preferredHeight: CGFloat = 350

    var body: some View {
        ControllerRepresentable(
            title: title,
            sheet: sheet,
            onHeightChange: { preferredHeight = $0 },
            updateItem: updateItem,
            replaceItem: replaceItem,
            onNavigate: onNavigate,
        )
        .frame(height: preferredHeight)
    }
}

private struct ControllerRepresentable: UIViewControllerRepresentable {
    let title: String
    let sheet: SheetActions
    let onHeightChange: (CGFloat) -> Void
    let updateItem: () -> Void
    let replaceItem: () -> Void
    let onNavigate: () -> Void

    func makeUIViewController(context _: Context) -> ControllerBody {
        ControllerBody()
    }

    func updateUIViewController(_ controller: ControllerBody, context _: Context) {
        controller.configure(title: title, close: { sheet.dismiss() },
                             select: { sheet.selectDetent($0) },
                             onHeightChange: onHeightChange, updateItem: updateItem,
                             replaceItem: replaceItem, onNavigate: onNavigate)
    }

    static func dismantleUIViewController(_ controller: ControllerBody, coordinator _: ()) {
        controller.clearActions()
    }
}

private final class ControllerBody: UIViewController {
    private let titleLabel = UILabel()
    private var count = 0
    private var countButton: UIButton!
    private var close: (() -> Void)?
    private var select: ((TideSheetDetent.Id) -> Void)?
    private var onHeightChange: ((CGFloat) -> Void)?
    private var updateItem: (() -> Void)?
    private var replaceItem: (() -> Void)?
    private var onNavigate: (() -> Void)?
    private let extra = UILabel()

    override var preferredContentSize: CGSize {
        didSet {
            guard preferredContentSize.height != oldValue.height else { return }
            onHeightChange?(preferredContentSize.height)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        preferredContentSize = CGSize(width: 0, height: 350)
        titleLabel.textAlignment = .center
        countButton = button("Controller count 0") { [weak self] in
            guard let self else { return }
            count += 1
            countButton.setTitle("Controller count \(count)", for: .normal)
        }
        extra.text = "UIKit changed its preferred content height."
        extra.numberOfLines = 0
        extra.isHidden = true
        extra.heightAnchor.constraint(equalToConstant: 90).isActive = true
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            button("Content") { [weak self] in self?.select?(ControllerDetents.content.id) },
            button("Maximum") { [weak self] in self?.select?(ControllerDetents.maximum.id) },
            countButton,
            button("Resize controller") { [weak self] in
                guard let self else { return }
                extra.isHidden.toggle()
                preferredContentSize.height = extra.isHidden ? 350 : 440
            },
            extra,
            button("Update controller item") { [weak self] in self?.updateItem?() },
            button("Replace controller item") { [weak self] in self?.replaceItem?() },
            button("Push from controller") { [weak self] in self?.onNavigate?() },
            button("Close controller") { [weak self] in self?.close?() },
        ])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])
    }

    func configure(title: String, close: @escaping () -> Void,
                   select: @escaping (TideSheetDetent.Id) -> Void,
                   onHeightChange: @escaping (CGFloat) -> Void,
                   updateItem: @escaping () -> Void, replaceItem: @escaping () -> Void,
                   onNavigate: @escaping () -> Void)
    {
        loadViewIfNeeded()
        titleLabel.text = title
        self.close = close
        self.select = select
        self.onHeightChange = onHeightChange
        self.updateItem = updateItem
        self.replaceItem = replaceItem
        self.onNavigate = onNavigate
    }

    func clearActions() {
        close = nil
        select = nil
        onHeightChange = nil
        updateItem = nil
        replaceItem = nil
        onNavigate = nil
    }

    private func button(_ title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }
}
