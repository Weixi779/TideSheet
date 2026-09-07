# SwiftUI Bottom Sheet

`bottomSheet` is the single SwiftUI entry point. `presentation: .modal` (the default) establishes an independent modal scope. `presentation: .attached` follows the declaring page through navigation. Both cover their presentation container, including navigation chrome, even when declared on a small button. See the [attached behavior](SwiftUI-Attached-Sheet.md) for page ownership.

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

Every overload accepts `presentation: SheetPresentation = .modal`. The style is captured once when each presentation starts. Changing it while open affects the next presentation, without resetting content or detent selection.

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

While that modal remains visible, input reconciliation continues in its presented content tree even if the original route is offscreen. Item updates and replacement therefore remain active; replacement starts from the old carrier's dismissal completion. This is verified for both native SwiftUI content and the UIKit-content example.

If the host's SwiftUI state is released, its active presentation also emits a one-shot termination notification. That fallback does not clear a shared external binding or promise a surviving carrier animation. Merely receiving `onDisappear` does not end the presentation. Arbitrary navigation rewrites that retain offscreen state remain outside the verified host-removal contract.

## Geometry and current limits

The backdrop covers the modal container. Maximum sheet height excludes the top safe area while the surface reaches the bottom edge. Declared heights describe the complete outer surface, including the indicator region, without an additional bottom safe-area allowance. TideSheet adds no uniform side or bottom safe-area padding to content. Any padding chosen by content participates in its fitting measurement.

Content and its host decide how to use native safe-area and keyboard layout behavior. TideSheet has no safe-area policy, keyboard tracking, keyboard-driven movement or resizing, or automatic scrolling to an input. Native SwiftUI layout responses still belong to the framework and the owning host. See the [content ownership decision](Design-Decisions.md#12-content-owns-safe-area-usage-keyboard-layout-and-scrolling).

The initial modal path shares the attached surface's single intrinsic-content hierarchy. Content is top-aligned and clipped to the selected height. Vertically flexible views and scroll views need an explicit content height; automatic filling remains follow-up layout work. Scroll-view gesture handoff is outside the component's scope.

Runtime validation covers portrait iPhone 17 Pro Max on iOS 26.5: all four API combinations, small-view presentation, detent selection, drag dismissal, item updates/replacement, repeated closure, system dismissal, and navigation ordering. Screenshots also verify the transparent backdrop and independent scope. The package compiles with an iOS 17 deployment target, but minimum-version runtime checks have not been performed.

Rotation, compact height, iPad, multi-scene behavior, the full accessibility matrix, visual and animation configuration, and multiple-sheet coordination remain future work. A [UIKit-content example](Cross-Content-Bridges.md) now uses the system representable API; dedicated bridge conveniences remain open. Content keyboard layout and scrolling remain content responsibilities. This is an initial SwiftUI modal slice, not a tagged release or the completed cross-renderer contract.

See the [runnable example](../Examples/SwiftUI/README.md) and [roadmap](Roadmap.md).
