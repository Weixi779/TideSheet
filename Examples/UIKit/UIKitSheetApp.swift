//
//  UIKitSheetApp.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import TideSheet
import TideSheetUIKit
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, configurationForConnecting session: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: session.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UINavigationController(rootViewController: Catalog())
        self.window = window
        window.makeKeyAndVisible()
    }
}

private enum Mode: String, CaseIterable {
    case modal = "Modal"
    case attached = "Attached"
    case custom = "Custom backdrop"
    case scrolling = "Scrolling content"
    case immediateModal = "Immediate modal dismissal"
    case immediateAttached = "Immediate attached dismissal"
    case swiftUIModal = "SwiftUI content · Modal"
    case swiftUIAttached = "SwiftUI content · Attached"

    var isAttached: Bool {
        self == .attached || self == .immediateAttached
    }

    var closesImmediately: Bool {
        self == .immediateModal || self == .immediateAttached
    }
}

private final class Catalog: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TideSheet UIKit"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "mode")
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        Mode.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mode", for: indexPath)
        var configuration = cell.defaultContentConfiguration()
        configuration.text = Mode.allCases[indexPath.row].rawValue
        cell.contentConfiguration = configuration
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mode = Mode.allCases[indexPath.row]
        let controller: UIViewController = switch mode {
        case .swiftUIModal: SwiftUIContentExample(isAttached: false)
        case .swiftUIAttached: SwiftUIContentExample(isAttached: true)
        default: Host(mode: mode)
        }
        navigationController?.pushViewController(controller, animated: true)
    }
}

private enum Detents {
    static let compact = TideSheetDetent(id: .init(rawValue: "compact"), height: .fixed(520))
    static let content = TideSheetDetent(id: .init(rawValue: "content"), height: .content())
    static let half = TideSheetDetent(id: .init(rawValue: "half"), height: .fraction(0.5))
    static let maximum = TideSheetDetent(id: .init(rawValue: "maximum"), height: .maximum)
    static let all: Set<TideSheetDetent> = [compact, content, half, maximum]
}

private final class Host: UIViewController {
    let mode: Mode
    private let status = UILabel()
    private var dismissals = 0
    private var completions = 0

    init(mode: Mode) {
        self.mode = mode; super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = mode.rawValue
        view.backgroundColor = .systemGroupedBackground
        status.textAlignment = .center
        status.numberOfLines = 0
        updateStatus()
        let stack = vertical([status, button("Open sheet") { [weak self] in self?.openSheet() }])
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func openSheet() {
        let content: UIViewController
        let scrolling = mode == .scrolling
        if scrolling { content = ScrollingContent() }
        else {
            let sheetContent = SheetContent()
            sheetContent.closesModalChain = !mode.isAttached
            content = sheetContent
        }
        let backdrop: BottomSheetDimmingBackground = mode == .custom ? .custom {
            let effect = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
            effect.alpha = 0.8
            return effect
        } : .color(.black.withAlphaComponent(0.28))
        let configuration = BottomSheetConfiguration(
            detents: scrolling ? [Detents.compact, Detents.maximum] : Detents.all,
            initialDetent: Detents.compact.id,
            dimmingBackground: backdrop,
        )
        let onDismiss = { [weak self] in
            guard let self else { return }
            dismissals += 1
            updateStatus()
        }
        let handler = presentBottomSheet(content, presentation: mode.isAttached ? .attached : .modal,
                                         configuration: configuration, onDismiss: onDismiss)
        if let content = content as? SheetContent {
            content.handler = handler
            content.onNavigate = { [weak self] in self?.pushDetail() }
            content.onDismissCompletion = { [weak self] in
                guard let self else { return }
                completions += 1
                updateStatus()
            }
        }
        if mode.closesImmediately { handler.dismiss() }
    }

    private func updateStatus() {
        status.text = "Dismissals: \(dismissals)\nCompletions: \(completions)"
    }

    private func pushDetail() {
        let controller = UIViewController()
        controller.view.backgroundColor = .systemTeal
        controller.title = "Route detail"
        navigationController?.pushViewController(controller, animated: true)
    }
}

private final class SheetContent: UIViewController {
    var handler: BottomSheetHandler? {
        didSet {
            handler?.onSelectedDetentChange = { [weak self] id in self?.selection.text = "Selection: \(id.rawValue)" }
        }
    }

    var onNavigate: (() -> Void)?
    var onDismissCompletion: (() -> Void)?
    var closesModalChain = false
    private let selection = UILabel()
    private var count = 0
    private var countButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        preferredContentSize = CGSize(width: 0, height: 480)
        selection.text = "Selection: compact"
        selection.textAlignment = .center
        countButton = button("Count 0") { [weak self] in
            guard let self else { return }
            count += 1
            countButton.setTitle("Count \(count)", for: .normal)
        }
        let positions = horizontal([
            button("Fixed") { [weak self] in self?.handler?.selectDetent(Detents.compact.id) },
            button("Content") { [weak self] in self?.handler?.selectDetent(Detents.content.id) },
            button("Half") { [weak self] in self?.handler?.selectDetent(Detents.half.id) },
            button("Maximum") { [weak self] in self?.handler?.selectDetent(Detents.maximum.id) },
        ])
        let stack = vertical([
            selection, positions, countButton,
            button("Resize content") { [weak self] in self?.preferredContentSize.height += 90 },
            button("Push behind sheet") { [weak self] in self?.onNavigate?() },
            button("Present child modal") { [weak self] in self?.presentChild() },
            horizontal([
                button("Close sheet") { [weak self] in self?.handler?.dismiss() },
                button("Close twice") { [weak self] in
                    guard let self else { return }
                    handler?.dismiss(completion: onDismissCompletion)
                    handler?.dismiss(completion: onDismissCompletion)
                },
            ]),
            button("Close then navigate") { [weak self] in
                guard let self else { return }
                handler?.dismiss(completion: onNavigate)
            },
        ])
        view.addSubview(stack)
        let input = UITextField()
        input.placeholder = "Type here"
        input.borderStyle = .roundedRect
        input.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(input)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            input.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            input.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            input.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -8),
            input.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func presentChild() {
        let child = UIViewController()
        child.view.backgroundColor = .systemIndigo
        child.modalPresentationStyle = .fullScreen
        // A modal sheet owns its descendant presentation chain. Attached content
        // returns through native navigation before closing its local surface.
        let close = closesModalChain
            ? button("Close whole sheet") { [handler] in handler?.dismiss() }
            : button("Back to sheet") { [weak child] in child?.dismiss(animated: true) }
        child.view.addSubview(close)
        NSLayoutConstraint.activate([
            close.centerXAnchor.constraint(equalTo: child.view.centerXAnchor),
            close.centerYAnchor.constraint(equalTo: child.view.centerYAnchor),
        ])
        present(child, animated: true)
    }
}

private final class ScrollingContent: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "Sheet rows"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "row")
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        80
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "row", for: indexPath)
        var configuration = cell.defaultContentConfiguration()
        configuration.text = "Row \(indexPath.row)"
        cell.contentConfiguration = configuration
        return cell
    }
}

private func button(_ title: String, action: @escaping () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(title, for: .normal)
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    button.heightAnchor.constraint(greaterThanOrEqualToConstant: 32).isActive = true
    return button
}

private func vertical(_ views: [UIView]) -> UIStackView {
    let stack = UIStackView(arrangedSubviews: views)
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
}

private func horizontal(_ views: [UIView]) -> UIStackView {
    let stack = UIStackView(arrangedSubviews: views)
    stack.axis = .horizontal
    stack.distribution = .fillEqually
    stack.spacing = 8
    return stack
}
