//
//  SheetActions.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import SwiftUI
import TideSheet

/// Operations on the sheet that supplied this environment value.
///
/// Read this value inside sheet content. Outside a TideSheet, and after that
/// presentation ends, its actions do nothing.
public struct SheetActions: Sendable {
    private let dismissAction: @MainActor @Sendable () -> Void
    private let selectAction: @MainActor @Sendable (TideSheetDetent.Id) -> Void

    nonisolated init(
        dismiss: @escaping @MainActor @Sendable () -> Void,
        selectDetent: @escaping @MainActor @Sendable (TideSheetDetent.Id) -> Void,
    ) {
        dismissAction = dismiss
        selectAction = selectDetent
    }

    /// Requests dismissal, including writing back the presentation binding.
    public func dismiss() {
        dismissAction()
    }

    /// Selects a configured detent. An unknown identifier is ignored.
    public func selectDetent(_ id: TideSheetDetent.Id) {
        selectAction(id)
    }
}

public extension EnvironmentValues {
    @Entry var sheet: SheetActions = .init(dismiss: {}, selectDetent: { _ in })
}
