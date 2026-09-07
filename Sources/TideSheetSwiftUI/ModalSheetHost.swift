//
//  ModalSheetHost.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import Combine
import SwiftUI

struct ModalSheetHost<Item: Identifiable, SheetContent: View>: View {
    let input: SheetPresentationInput<Item>
    let state: SheetPresentationState<Item>
    let sheetContent: (Item) -> SheetContent

    @State private var carrier: SheetPresentationState<Item>.Presentation?
    @State private var activeCarrierID: UUID?

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .fullScreenCover(item: carrierBinding, onDismiss: carrierDidDismiss) { presentation in
                GeometryReader { geometry in
                    let safeArea = geometry.safeAreaInsets
                    SheetPresentationContent(
                        input: input,
                        state: state,
                        presentation: presentation,
                        availableHeight: geometry.size.height + safeArea.bottom,
                        onDismissed: { removeCarrier(presentation.id) },
                        sheetContent: sheetContent,
                    )
                    .frame(
                        width: geometry.size.width + safeArea.leading + safeArea.trailing,
                        height: geometry.size.height + safeArea.top + safeArea.bottom,
                    )
                    .offset(x: -safeArea.leading, y: -safeArea.top)
                    .id(presentation.id)
                }
                // The presenting route can leave the visible navigation path while
                // this carrier remains onscreen. Keep its input reconciliation alive
                // in the presented tree as well as at the original modifier site.
                .onReceive(Just((input.item.wrappedValue, input.selection.value))) { _ in state.update(input) }
                .presentationBackground(.clear)
                .interactiveDismissDisabled()
                // Only the native carrier opens/closes without animation. The
                // custom surface continues to own its animated transitions.
                .transaction { $0.disablesAnimations = false }
            }
            .onReceive(Just((input.item.wrappedValue, input.selection.value))) { _ in state.update(input) }
            .onChange(of: state.presentation?.id, initial: true) { _, _ in
                presentPendingCarrierIfNeeded()
            }
    }

    private var carrierBinding: Binding<SheetPresentationState<Item>.Presentation?> {
        Binding(
            get: { carrier },
            set: { value in
                // The system's dismiss environment action can close the modal
                // directly. Bring application state into agreement in that case.
                if value == nil, let id = activeCarrierID { state.dismiss(id) }
                carrier = value
            },
        )
    }

    private func removeCarrier(_ id: UUID) {
        guard activeCarrierID == id else { return }
        withoutCarrierAnimation { carrier = nil }
    }

    private func carrierDidDismiss() {
        guard carrier == nil, let id = activeCarrierID else { return }
        activeCarrierID = nil
        state.update(input)
        state.dismiss(id)
        state.finishDismissal(id)
        // An offscreen modifier does not run its onChange observer. A replacement
        // must advance from native dismissal completion, which remains active.
        presentPendingCarrierIfNeeded()
    }

    private func presentPendingCarrierIfNeeded() {
        guard activeCarrierID == nil, let presentation = state.presentation else { return }
        guard !presentation.isDismissing else {
            state.finishDismissal(presentation.id)
            return
        }
        activeCarrierID = presentation.id
        withoutCarrierAnimation { carrier = presentation }
    }

    private func withoutCarrierAnimation(_ action: () -> Void) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction, action)
    }
}
