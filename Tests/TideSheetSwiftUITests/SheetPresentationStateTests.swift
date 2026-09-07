//
//  SheetPresentationStateTests.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import SwiftUI
import Testing
import TideSheet
@testable import TideSheetSwiftUI

@Suite("Sheet presentation ownership")
struct SheetPresentationStateTests {
    private let compact = TideSheetDetent(id: .init(rawValue: "compact"), height: .fixed(200))
    private let expanded = TideSheetDetent(id: .init(rawValue: "expanded"), height: .maximum)

    /// Intentionally not Equatable: the public item API only requires identity.
    private struct Item: Identifiable {
        let id: Int
        var title = "Original"
    }

    private final class Storage<Value> {
        var value: Value
        var writes = 0
        init(_ value: Value) {
            self.value = value
        }

        /// Match the generic deinit workaround used by the renderer for Release tests.
        nonisolated deinit {}

        var binding: Binding<Value> {
            Binding(get: { self.value }, set: { self.value = $0; self.writes += 1 })
        }
    }

    @Test
    func `Presentation style changes apply to the next presentation`() throws {
        let item = Storage<Item?>(Item(id: 1))
        let state = SheetPresentationState<Item>()
        var input = input(item)
        input.style = .attached
        state.update(input)
        let original = try #require(state.presentation)
        state.actions(for: original.id).selectDetent(expanded.id)

        input.style = .modal
        state.update(input)
        #expect(state.presentation === original)
        #expect(original.style == .attached)
        #expect(original.selectedDetent == expanded.id)

        item.value = Item(id: 2)
        state.update(input)
        #expect(original.isDismissing)
        state.finishDismissal(original.id)
        #expect(state.presentation?.style == .modal)
        #expect(state.presentation?.item.id == 2)
    }

    @Test
    func `Updates content without resetting internal selection`() throws {
        let item = Storage<Item?>(Item(id: 1))
        let state = SheetPresentationState<Item>()
        let input = input(item)
        state.update(input)
        let presentation = try #require(state.presentation)
        state.actions(for: presentation.id).selectDetent(expanded.id)

        item.value = Item(id: 1, title: "Updated")
        state.update(input)

        #expect(state.presentation === presentation)
        #expect(presentation.item.title == "Updated")
        #expect(presentation.selectedDetent == expanded.id)
    }

    @Test
    func `External selection is the single source of truth`() throws {
        let item = Storage<Item?>(Item(id: 1))
        let selection = Storage(compact.id)
        let state = SheetPresentationState<Item>()
        let input = input(item, selection: .bound(selection.binding))
        state.update(input)
        let presentation = try #require(state.presentation)
        let actions = state.actions(for: presentation.id)

        actions.selectDetent(expanded.id)
        #expect(selection.value == expanded.id)
        #expect(selection.writes == 1)

        selection.value = compact.id
        #expect(presentation.selectedDetent == compact.id)
        actions.selectDetent(.init(rawValue: "unknown"))
        #expect(selection.value == compact.id)
        #expect(selection.writes == 1)
    }

    @Test
    func `Dismissal writes once and notifies only after completion`() throws {
        let item = Storage<Item?>(Item(id: 1))
        let state = SheetPresentationState<Item>()
        var dismissals = 0
        state.update(input(item, onDismiss: {
            #expect(state.presentation == nil)
            dismissals += 1
        }))
        let presentation = try #require(state.presentation)
        let actions = state.actions(for: presentation.id)
        actions.dismiss()
        actions.dismiss()

        #expect(item.value == nil)
        #expect(item.writes == 1)
        #expect(dismissals == 0)
        #expect(presentation.isDismissing)

        state.finishDismissal(presentation.id)
        state.finishDismissal(presentation.id)
        #expect(dismissals == 1)
    }

    @Test
    func `New item survives old actions and completion`() throws {
        let item = Storage<Item?>(Item(id: 1))
        let state = SheetPresentationState<Item>()
        var dismissals = 0
        let input = input(item, onDismiss: { dismissals += 1 })
        state.update(input)
        let first = try #require(state.presentation)
        let oldActions = state.actions(for: first.id)

        item.value = Item(id: 2)
        oldActions.dismiss()
        oldActions.selectDetent(expanded.id)
        #expect(item.value?.id == 2)
        #expect(first.selectedDetent == compact.id)

        state.update(input)
        #expect(first.isDismissing)
        state.finishDismissal(first.id)
        let second = try #require(state.presentation)
        #expect(second.id != first.id)
        #expect(second.item.id == 2)
        #expect(dismissals == 1)

        oldActions.dismiss()
        state.finishDismissal(first.id)
        #expect(item.value?.id == 2)
        #expect(!second.isDismissing)
        #expect(dismissals == 1)
    }

    @Test
    func `Replacing configuration freezes the old external selection during dismissal`() throws {
        let item = Storage<Item?>(Item(id: 1))
        let selection = Storage(expanded.id)
        let state = SheetPresentationState<Item>()
        state.update(input(item, selection: .bound(selection.binding)))
        let old = try #require(state.presentation)

        let replacement = TideSheetDetent(id: .init(rawValue: "replacement"), height: .fixed(300))
        item.value = Item(id: 2)
        selection.value = replacement.id
        state.update(SheetPresentationInput(
            item: item.binding,
            detents: [replacement],
            selection: .bound(selection.binding),
            onDismiss: nil,
        ))

        #expect(old.isDismissing)
        #expect(old.selectedDetent == expanded.id)
        state.finishDismissal(old.id)
        #expect(state.presentation?.selectedDetent == replacement.id)
    }

    @Test
    func `A new presentation reapplies the initial detent`() throws {
        let item = Storage<Item?>(Item(id: 1))
        let state = SheetPresentationState<Item>()
        let input = input(item)
        state.update(input)
        let first = try #require(state.presentation)
        let actions = state.actions(for: first.id)
        actions.selectDetent(expanded.id)
        actions.dismiss()
        state.finishDismissal(first.id)

        item.value = Item(id: 1)
        state.update(input)
        let second = try #require(state.presentation)
        #expect(second.selectedDetent == compact.id)
        actions.selectDetent(expanded.id)
        #expect(second.selectedDetent == compact.id)
    }

    @Test
    func `Removing an internally selected detent returns to the configured initial detent`() throws {
        let item = Storage<Item?>(Item(id: 1))
        let state = SheetPresentationState<Item>()
        state.update(input(item))
        let presentation = try #require(state.presentation)
        state.select(expanded.id, in: presentation.id)
        state.update(SheetPresentationInput(item: item.binding, detents: [compact], selection: .initial(compact.id), onDismiss: nil))
        #expect(presentation.selectedDetent == compact.id)
    }

    @Test
    func `External dismissal does not write the binding again`() throws {
        let item = Storage<Item?>(Item(id: 1))
        let state = SheetPresentationState<Item>()
        let input = input(item)
        state.update(input)
        let presentation = try #require(state.presentation)
        item.value = nil
        state.update(input)
        #expect(presentation.isDismissing)
        state.finishDismissal(presentation.id)
        #expect(item.writes == 0)
    }

    @Test
    func `Reentrant dismissal callback can request another presentation`() throws {
        let item = Storage<Item?>(Item(id: 1))
        let state = SheetPresentationState<Item>()
        state.update(input(item, onDismiss: { item.value = Item(id: 2) }))
        let first = try #require(state.presentation)
        state.dismiss(first.id)
        state.finishDismissal(first.id)
        #expect(state.presentation?.item.id == 2)
    }

    @Test
    func `Releasing the host ends the presentation without clearing shared state`() throws {
        let item = Storage<Item?>(Item(id: 1))
        var dismissals = 0
        var state: SheetPresentationState<Item>? = SheetPresentationState()
        state?.update(input(item, onDismiss: { dismissals += 1 }))
        let presentation = try #require(state?.presentation)
        let actions = try #require(state?.actions(for: presentation.id))
        weak var weakState = state
        state = nil
        #expect(weakState == nil)
        #expect(dismissals == 1)
        actions.dismiss()
        #expect(item.value?.id == 1)
        #expect(item.writes == 0)
    }

    @Test
    func `Default environment actions are inert`() {
        let actions = EnvironmentValues().sheet
        actions.dismiss()
        actions.selectDetent(compact.id)
    }

    private func input(
        _ item: Storage<Item?>,
        selection: SheetSelection? = nil,
        onDismiss: (() -> Void)? = nil,
    ) -> SheetPresentationInput<Item> {
        SheetPresentationInput(
            item: item.binding,
            detents: [compact, expanded],
            selection: selection ?? .initial(compact.id),
            onDismiss: onDismiss,
        )
    }
}
