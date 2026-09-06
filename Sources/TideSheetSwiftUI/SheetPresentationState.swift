//
//  SheetPresentationState.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import Observation
import SwiftUI
import TideSheet

enum SheetSelection {
    case initial(TideSheetDetent.Id)
    case bound(Binding<TideSheetDetent.Id>)

    var value: TideSheetDetent.Id {
        switch self {
        case let .initial(id): id
        case let .bound(binding): binding.wrappedValue
        }
    }
}

struct SheetPresentationInput<Item: Identifiable> {
    let item: Binding<Item?>
    let detents: Set<TideSheetDetent>
    let selection: SheetSelection
    let onDismiss: (() -> Void)?

    func validate() {
        // Resolve with zero available space to validate declarations without measuring content.
        _ = TideSheetDetentLayout(detents: Array(detents), availableHeight: 0)
        precondition(detents.contains { $0.id == selection.value }, "The initial or bound detent must exist in detents.")
    }
}

@Observable
final class SheetPresentationState<Item: Identifiable> {
    @Observable
    final class Presentation: Identifiable {
        let id = UUID()
        var isDismissing = false
        var internalSelection: TideSheetDetent.Id

        // Updated inputs are read by the host's existing SwiftUI dependencies.
        // Keeping the last item also preserves its final content during dismissal.
        @ObservationIgnored var item: Item
        @ObservationIgnored var input: SheetPresentationInput<Item>
        @ObservationIgnored var lastValidSelection: TideSheetDetent.Id
        @ObservationIgnored private var closingSelection: TideSheetDetent.Id?

        init(item: Item, input: SheetPresentationInput<Item>) {
            self.item = item
            self.input = input
            internalSelection = input.selection.value
            lastValidSelection = input.selection.value
        }

        var selectedDetent: TideSheetDetent.Id {
            if let closingSelection { return closingSelection }
            switch input.selection {
            case .initial: return internalSelection
            case let .bound(binding): return binding.wrappedValue
            }
        }

        func beginDismissal() {
            let currentSelection = selectedDetent
            closingSelection = input.detents.contains { $0.id == currentSelection }
                ? currentSelection : lastValidSelection
            isDismissing = true
        }
    }

    private(set) var presentation: Presentation?
    @ObservationIgnored private var input: SheetPresentationInput<Item>?

    isolated deinit {
        presentation?.input.onDismiss?()
    }

    func update(_ input: SheetPresentationInput<Item>) {
        self.input = input
        reconcile()
    }

    func dismiss(_ id: UUID) {
        guard let presentation, presentation.id == id, !presentation.isDismissing else { return }
        // Reconcile an external replacement before an old content action can clear it.
        guard let input, input.item.wrappedValue?.id == presentation.item.id else { return }
        presentation.beginDismissal()
        input.item.wrappedValue = nil
    }

    func select(_ detent: TideSheetDetent.Id, in id: UUID) {
        guard let presentation, presentation.id == id, !presentation.isDismissing,
              let input, input.item.wrappedValue?.id == presentation.item.id,
              input.detents.contains(where: { $0.id == detent }) else { return }

        switch input.selection {
        case .initial:
            presentation.internalSelection = detent
        case let .bound(binding):
            binding.wrappedValue = detent
        }
        presentation.lastValidSelection = presentation.selectedDetent
    }

    func finishDismissal(_ id: UUID) {
        guard let presentation, presentation.id == id, presentation.isDismissing else { return }
        let onDismiss = presentation.input.onDismiss
        self.presentation = nil
        onDismiss?()
        reconcile()
    }

    func actions(for id: UUID) -> SheetActions {
        SheetActions(
            dismiss: { [weak self] in self?.dismiss(id) },
            selectDetent: { [weak self] in self?.select($0, in: id) },
        )
    }

    private func reconcile() {
        guard let input else { return }
        if let presentation {
            guard !presentation.isDismissing else { return }
            guard let item = input.item.wrappedValue, item.id == presentation.item.id else {
                presentation.beginDismissal()
                return
            }
            input.validate()
            presentation.item = item
            presentation.input = input
            if !input.detents.contains(where: { $0.id == presentation.selectedDetent }) {
                presentation.internalSelection = input.selection.value
            }
            presentation.lastValidSelection = presentation.selectedDetent
        } else if let item = input.item.wrappedValue {
            input.validate()
            presentation = Presentation(item: item, input: input)
        }
    }
}

struct BooleanSheetItem: Identifiable {
    let id = true
}

func booleanSheetItem(_ binding: Binding<Bool>) -> Binding<BooleanSheetItem?> {
    Binding(
        get: { binding.wrappedValue ? BooleanSheetItem() : nil },
        set: { binding.wrappedValue = $0 != nil },
    )
}
