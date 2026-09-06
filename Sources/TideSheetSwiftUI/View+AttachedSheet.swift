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
                input: AttachedSheetInput(item: item, detents: detents, selection: .initial(initialDetent), onDismiss: onDismiss),
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
                input: AttachedSheetInput(item: item, detents: detents, selection: .bound(selectedDetent), onDismiss: onDismiss),
                sheetContent: content,
            )
        }
    }
}

private struct BooleanSheetItem: Identifiable {
    let id = true
}

private func booleanSheetItem(_ binding: Binding<Bool>) -> Binding<BooleanSheetItem?> {
    Binding(
        get: { binding.wrappedValue ? BooleanSheetItem() : nil },
        set: { binding.wrappedValue = $0 != nil },
    )
}

private struct AttachedSheetHost<Item: Identifiable, SheetContent: View>: View {
    let input: AttachedSheetInput<Item>
    let sheetContent: (Item) -> SheetContent
    @State private var state = AttachedSheetState<Item>()

    var body: some View {
        // Read the bindings in body so external changes invalidate this host.
        let item = input.item.wrappedValue
        let selection = input.selection.value
        GeometryReader { geometry in
            if let presentation = state.presentation {
                let currentItem = item.flatMap {
                    !presentation.isDismissing && $0.id == presentation.item.id ? $0 : nil
                } ?? presentation.item
                let activeInput = presentation.isDismissing ? presentation.input : input
                let selectedId = if case .bound = activeInput.selection {
                    presentation.isDismissing ? presentation.selectedDetent : selection
                } else {
                    activeInput.detents.contains { $0.id == presentation.internalSelection }
                        ? presentation.internalSelection : activeInput.selection.value
                }
                SheetSurface(
                    detents: activeInput.detents,
                    selectedDetent: selectedId,
                    availableHeight: geometry.size.height,
                    isDismissing: presentation.isDismissing,
                    actions: state.actions(for: presentation.id),
                    onDismissed: { state.finishDismissal(presentation.id) },
                    content: { sheetContent(currentItem) },
                )
                .id(presentation.id)
            }
        }
        // Item need not be Equatable. Refresh input snapshots without publishing
        // payload-only changes back into SwiftUI and causing an update loop.
        .onReceive(Just(input)) { state.update($0) }
    }
}
