//
//  View+BottomSheet.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import Combine
import SwiftUI
import TideSheet

public extension View {
    /// Shows a custom sheet, independently by default or attached to its page.
    ///
    /// Both styles cover the page's presentation container, including navigation
    /// chrome. The style is captured when a presentation starts; changing it
    /// while open takes effect on the next presentation. `initialDetent` also
    /// initializes selection once per presentation. `onDismiss` runs after closing.
    func bottomSheet(
        isPresented: Binding<Bool>,
        presentation: SheetPresentation = .modal,
        detents: Set<TideSheetDetent>,
        initialDetent: TideSheetDetent.Id,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> some View,
    ) -> some View {
        bottomSheet(
            item: booleanSheetItem(isPresented),
            presentation: presentation,
            detents: detents,
            initialDetent: initialDetent,
            onDismiss: onDismiss,
            content: { _ in content() },
        )
    }

    /// Shows a sheet whose current detent is owned by the caller.
    func bottomSheet(
        isPresented: Binding<Bool>,
        presentation: SheetPresentation = .modal,
        detents: Set<TideSheetDetent>,
        selectedDetent: Binding<TideSheetDetent.Id>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> some View,
    ) -> some View {
        bottomSheet(
            item: booleanSheetItem(isPresented),
            presentation: presentation,
            detents: detents,
            selectedDetent: selectedDetent,
            onDismiss: onDismiss,
            content: { _ in content() },
        )
    }

    /// Shows item-driven content with internally owned selection.
    ///
    /// Same-ID updates retain content state. A different ID waits for the old
    /// surface and its carrier to close before opening the replacement.
    func bottomSheet<Item: Identifiable>(
        item: Binding<Item?>,
        presentation: SheetPresentation = .modal,
        detents: Set<TideSheetDetent>,
        initialDetent: TideSheetDetent.Id,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> some View,
    ) -> some View {
        background {
            BottomSheetHost(
                input: SheetPresentationInput(item: item, detents: detents, selection: .initial(initialDetent), onDismiss: onDismiss, style: presentation),
                sheetContent: content,
            )
        }
    }

    /// Shows item-driven content with externally owned selection.
    func bottomSheet<Item: Identifiable>(
        item: Binding<Item?>,
        presentation: SheetPresentation = .modal,
        detents: Set<TideSheetDetent>,
        selectedDetent: Binding<TideSheetDetent.Id>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> some View,
    ) -> some View {
        background {
            BottomSheetHost(
                input: SheetPresentationInput(item: item, detents: detents, selection: .bound(selectedDetent), onDismiss: onDismiss, style: presentation),
                sheetContent: content,
            )
        }
    }
}

private struct BottomSheetHost<Item: Identifiable, SheetContent: View>: View {
    let input: SheetPresentationInput<Item>
    let sheetContent: (Item) -> SheetContent
    @State private var state = SheetPresentationState<Item>()

    var body: some View {
        Group {
            switch state.presentation?.style ?? input.style {
            case .modal:
                ModalSheetHost(input: input, state: state, sheetContent: sheetContent)
            case .attached:
                AttachedSheetHost(input: input, state: state, sheetContent: sheetContent)
            }
        }
        .frame(width: 0, height: 0)
        .onReceive(Just((input.item.wrappedValue, input.selection.value))) { _ in state.update(input) }
    }
}
