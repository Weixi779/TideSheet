//
//  View+AttachedSheet.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import Combine
import SwiftUI
import TideSheet

public extension View {
    /// Attaches a sheet to this view's bounds and lifetime, with internally owned selection.
    ///
    /// `initialDetent` is applied once per presentation. Content and container updates
    /// preserve selection. Removing the selected detent falls back to `initialDetent`.
    /// Detents must be nonempty, have unique IDs, and contain the initial ID.
    /// `onDismiss` runs once after dismissal or when the host's state is released.
    func attachedSheet(
        isPresented: Binding<Bool>,
        detents: Set<TideSheetDetent>,
        initialDetent: TideSheetDetent.Id,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> some View,
    ) -> some View {
        attachedSheet(
            item: booleanSheetItem(isPresented),
            detents: detents,
            initialDetent: initialDetent,
            onDismiss: onDismiss,
            content: { _ in content() },
        )
    }

    /// Attaches a sheet whose current detent is owned by the caller.
    ///
    /// The binding supplies both initial and subsequent selection. Dragging and
    /// environment actions write back to it. Its value must belong to `detents`.
    func attachedSheet(
        isPresented: Binding<Bool>,
        detents: Set<TideSheetDetent>,
        selectedDetent: Binding<TideSheetDetent.Id>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> some View,
    ) -> some View {
        attachedSheet(
            item: booleanSheetItem(isPresented),
            detents: detents,
            selectedDetent: selectedDetent,
            onDismiss: onDismiss,
            content: { _ in content() },
        )
    }

    /// Attaches item-driven content with internally owned detent selection.
    ///
    /// The same item ID updates content in place. A different ID dismisses the old
    /// presentation before starting a new one. Dismissal never clears a newer item.
    func attachedSheet<Item: Identifiable>(
        item: Binding<Item?>,
        detents: Set<TideSheetDetent>,
        initialDetent: TideSheetDetent.Id,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> some View,
    ) -> some View {
        overlay {
            AttachedSheetHost(
                input: SheetPresentationInput(item: item, detents: detents, selection: .initial(initialDetent), onDismiss: onDismiss),
                sheetContent: content,
            )
        }
    }

    /// Attaches item-driven content with externally owned detent selection.
    func attachedSheet<Item: Identifiable>(
        item: Binding<Item?>,
        detents: Set<TideSheetDetent>,
        selectedDetent: Binding<TideSheetDetent.Id>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> some View,
    ) -> some View {
        overlay {
            AttachedSheetHost(
                input: SheetPresentationInput(item: item, detents: detents, selection: .bound(selectedDetent), onDismiss: onDismiss),
                sheetContent: content,
            )
        }
    }
}

private struct AttachedSheetHost<Item: Identifiable, SheetContent: View>: View {
    let input: SheetPresentationInput<Item>
    let sheetContent: (Item) -> SheetContent
    @State private var state = SheetPresentationState<Item>()

    var body: some View {
        GeometryReader { geometry in
            if let presentation = state.presentation {
                SheetPresentationContent(
                    input: input,
                    state: state,
                    presentation: presentation,
                    availableHeight: geometry.size.height,
                    onDismissed: { state.finishDismissal(presentation.id) },
                    sheetContent: sheetContent,
                )
                .id(presentation.id)
            }
        }
        // Item need not be Equatable. Refresh input snapshots without publishing
        // payload-only changes back into SwiftUI and causing an update loop.
        .onReceive(Just((input.item.wrappedValue, input.selection.value))) { _ in state.update(input) }
    }
}
