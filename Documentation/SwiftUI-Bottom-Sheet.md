# SwiftUI Modal Bottom Sheet

`bottomSheet` presents a TideSheet surface in an independent SwiftUI modal scope. It can be installed on a small button without limiting the sheet to that button's bounds. Use `attachedSheet` when the surface should belong to the chosen view's bounds and hierarchy.

## Public API

```swift
import SwiftUI
import TideSheet
import TideSheetSwiftUI

struct Example: View {
    @State private var isPresented = false

    private let compact = TideSheetDetent(
        id: .init(rawValue: "compact"),
        height: .fixed(280)
    )
    private let expanded = TideSheetDetent(
        id: .init(rawValue: "expanded"),
        height: .maximum
    )

    var body: some View {
        Button("Open details") { isPresented = true }
            .bottomSheet(
                isPresented: $isPresented,
                detents: [compact, expanded],
                initialDetent: compact.id
            ) {
                DetailsView()
            }
    }
}
```

The same four combinations are available in both contexts:

| Presentation | Detent selection | Content builder |
| --- | --- | --- |
| `isPresented: Binding<Bool>` | `initialDetent: TideSheetDetent.Id` | `() -> Content` |
| `isPresented: Binding<Bool>` | `selectedDetent: Binding<TideSheetDetent.Id>` | `() -> Content` |
| `item: Binding<Item?>` | `initialDetent: TideSheetDetent.Id` | `(Item) -> Content` |
| `item: Binding<Item?>` | `selectedDetent: Binding<TideSheetDetent.Id>` | `(Item) -> Content` |

Every overload requires `detents: Set<TideSheetDetent>` and accepts an optional `onDismiss`. `Item` requires only `Identifiable`. The set is unordered: `initialDetent` selects the starting position, or the selection binding supplies it. The two selection parameters never appear together.

Content receives the same `@Environment(\.sheet)` actions as an attachment:

```swift
struct DetailsView: View {
    @Environment(\.sheet) private var sheet

    var body: some View {
        VStack {
            Button("Expand") {
                sheet.selectDetent(.init(rawValue: "expanded"))
            }
            Button("Close") { sheet.dismiss() }
        }
        .padding()
    }
}
```

Detent validation, selection ownership, same-ID content updates, replacement, and stale-action behavior follow the [attached contract](SwiftUI-Attached-Sheet.md). Both contexts use the same state and surface implementation.

## Modal lifetime and navigation

The initial carrier is SwiftUI's item-driven `fullScreenCover`. A clear presentation background exposes TideSheet's own dimming layer and the underlying page. TideSheet draws and animates the sheet inside that presentation. Apple documents the carrier's item and dismissal lifecycle in [`fullScreenCover`](https://developer.apple.com/documentation/swiftui/view/fullscreencover(item:ondismiss:content:)) and presentation background behavior in [`presentationBackground`](https://developer.apple.com/documentation/swiftui/view/presentationbackground(alignment:content:)).

For ordinary closure through `sheet.dismiss()`, the backdrop, a downward indicator drag, or an external binding change:

1. The presentation begins dismissing. A TideSheet action clears the matching Boolean/item binding; an external change is already reflected in that binding.
2. The custom surface completes its closing animation.
3. The native modal carrier is removed without a second transition.
4. `onDismiss` runs once, after the carrier's dismissal notification. A pending replacement can then open.

Use `onDismiss` for application work that must follow closure, such as pushing another route. It is a presentation-level notification, so individual actions do not also accept completion callbacks.

SwiftUI's `@Environment(\.dismiss)` is still available inside modal content. Calling it directly follows the native carrier's dismissal path; TideSheet reconciles the presentation binding and emits one `onDismiss`. Use the sheet environment action to follow TideSheet's surface-first animation sequence. Apple's [`dismiss` documentation](https://developer.apple.com/documentation/swiftui/environmentvalues/dismiss) explains why the environment must be read from the presented content's scope.

Pushing the underlying `NavigationStack` keeps the modal above the new route. The example verifies that its local content state survives this operation. TideSheet neither inspects the navigation stack nor moves the pushed route above the modal. The modifier still needs an owned SwiftUI host; an independent presentation scope is not a global presenter.

If the host's SwiftUI state is released, its active presentation also emits a one-shot termination notification. That fallback does not clear a shared external binding or promise a surviving carrier animation. Merely receiving `onDisappear` does not end the presentation. Arbitrary navigation rewrites that retain offscreen state remain outside the verified host-removal contract.

## Geometry and current limits

The backdrop covers the modal container. Maximum sheet height excludes the top safe area while the surface reaches the bottom edge. Side and bottom content padding participate in intrinsic fitting measurement; declared heights continue to describe the complete outer surface, including the indicator region.

The initial modal path shares the attached surface's single intrinsic-content hierarchy. Content is top-aligned and clipped to the selected height. Vertically flexible views and scroll views need an explicit content height; automatic filling and scroll handoff remain future work.

Runtime validation covers portrait iPhone 17 Pro Max on iOS 26.5: all four API combinations, small-view presentation, detent selection, drag dismissal, item updates/replacement, repeated closure, system dismissal, and navigation ordering. Screenshots also verify the transparent backdrop and independent scope. The package compiles with an iOS 17 deployment target, but minimum-version runtime checks have not been performed.

Keyboard policy, rotation, compact height, iPad, multi-scene behavior, the full accessibility matrix, visual and animation configuration, multiple-sheet coordination, and UIKit content remain future work. This is an initial SwiftUI modal slice, not a tagged release or the completed cross-renderer contract.

See the [runnable example](../Examples/AttachedSheet/README.md) and [roadmap](Roadmap.md).
