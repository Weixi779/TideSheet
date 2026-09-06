//
//  View+BottomSheet.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import SwiftUI
import TideSheet

public extension View {
    /// Presents a custom sheet in an independent SwiftUI modal context.
    ///
    /// Unlike `attachedSheet`, this presentation is not bounded by the modified
    /// view. `initialDetent` initializes selection once per presentation.
    /// `onDismiss` runs after the surface and its modal carrier have both closed.
    func bottomSheet(
        isPresented: Binding<Bool>,
        detents: Set<TideSheetDetent>,
        initialDetent: TideSheetDetent.Id,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> some View,
    ) -> some View {
        bottomSheet(
            item: booleanSheetItem(isPresented),
            detents: detents,
            initialDetent: initialDetent,
            onDismiss: onDismiss,
            content: { _ in content() },
        )
    }

    /// Presents a custom modal sheet whose selection is owned by the caller.
    func bottomSheet(
        isPresented: Binding<Bool>,
        detents: Set<TideSheetDetent>,
        selectedDetent: Binding<TideSheetDetent.Id>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> some View,
    ) -> some View {
        bottomSheet(
            item: booleanSheetItem(isPresented),
            detents: detents,
            selectedDetent: selectedDetent,
            onDismiss: onDismiss,
            content: { _ in content() },
        )
    }

    /// Presents item-driven modal content with internally owned selection.
    ///
    /// Same-ID updates retain content state. A different ID waits for the old
    /// surface and modal carrier to close before opening the replacement.
    func bottomSheet<Item: Identifiable>(
        item: Binding<Item?>,
        detents: Set<TideSheetDetent>,
        initialDetent: TideSheetDetent.Id,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> some View,
    ) -> some View {
        background {
            ModalSheetHost(
                input: SheetPresentationInput(item: item, detents: detents, selection: .initial(initialDetent), onDismiss: onDismiss),
                sheetContent: content,
            )
        }
    }

    /// Presents item-driven modal content with externally owned selection.
    func bottomSheet<Item: Identifiable>(
        item: Binding<Item?>,
        detents: Set<TideSheetDetent>,
        selectedDetent: Binding<TideSheetDetent.Id>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> some View,
    ) -> some View {
        background {
            ModalSheetHost(
                input: SheetPresentationInput(item: item, detents: detents, selection: .bound(selectedDetent), onDismiss: onDismiss),
                sheetContent: content,
            )
        }
    }
}
