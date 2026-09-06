//
//  BottomSheetHandler.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import TideSheet

/// Weak presentation controls that can be retained safely by content.
public final class BottomSheetHandler {
    private weak var viewController: BottomSheetViewController?

    /// The logical selection, or nil after the presentation ends.
    public var selectedDetent: TideSheetDetent.Id? {
        guard let viewController, !viewController.dismissalGate.didNotify else { return nil }
        return viewController.selectedDetent
    }

    /// Reports committed selection changes from actions, gestures, and accessibility.
    public var onSelectedDetentChange: ((TideSheetDetent.Id) -> Void)? {
        get { viewController?.onSelectedDetentChange }
        set { viewController?.onSelectedDetentChange = newValue }
    }

    init(viewController: BottomSheetViewController) {
        self.viewController = viewController
    }

    /// Closes the sheet through its modal or attached owner.
    public func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let viewController else { completion?(); return }
        viewController.dismissSheet(animated: animated, completion: completion)
    }

    /// Remeasures content detents after application content changes.
    public func invalidateContentSize(animated: Bool = true) {
        viewController?.invalidateContentSize(animated: animated)
    }

    /// Selects a declared ID. Unknown IDs and actions on an ending sheet are ignored.
    public func selectDetent(_ id: TideSheetDetent.Id, animated: Bool = true) {
        viewController?.selectDetent(id, animated: animated)
    }
}
