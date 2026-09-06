//
//  SheetPresentationContent.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import SwiftUI
import TideSheet

/// The same content identity, selection, and surface for both ownership contexts.
struct SheetPresentationContent<Item: Identifiable, SheetContent: View>: View {
    let input: SheetPresentationInput<Item>
    let state: SheetPresentationState<Item>
    let presentation: SheetPresentationState<Item>.Presentation
    let availableHeight: CGFloat
    let onDismissed: () -> Void
    let sheetContent: (Item) -> SheetContent

    var body: some View {
        let currentItem = input.item.wrappedValue.flatMap {
            !presentation.isDismissing && $0.id == presentation.item.id ? $0 : nil
        } ?? presentation.item
        let activeInput = presentation.isDismissing ? presentation.input : input
        let selectedId = if case .bound = activeInput.selection {
            presentation.isDismissing ? presentation.selectedDetent : activeInput.selection.value
        } else {
            activeInput.detents.contains { $0.id == presentation.internalSelection }
                ? presentation.internalSelection : activeInput.selection.value
        }

        SheetSurface(
            detents: activeInput.detents,
            selectedDetent: selectedId,
            availableHeight: availableHeight,
            isDismissing: presentation.isDismissing,
            actions: state.actions(for: presentation.id),
            onDismissed: onDismissed,
            content: { sheetContent(currentItem) },
        )
    }
}
