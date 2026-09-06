# SwiftUI Attached Sheet

The first SwiftUI slice provides a custom sheet inside the bounds and lifetime of the view carrying `attachedSheet`. It is implemented with SwiftUI views, layout, animation, and gestures. It does not call the UIKit renderer or present a system sheet.

Import both modules explicitly:

```swift
import TideSheet
import TideSheetSwiftUI
```

## Presentation and selection

Declare a set of detents with stable IDs:

```swift
let compact = TideSheetDetent(
    id: .init(rawValue: "compact"),
    height: .fixed(280)
)
let expanded = TideSheetDetent(
    id: .init(rawValue: "expanded"),
    height: .maximum
)
let detents: Set<TideSheetDetent> = [compact, expanded]
```

Use an initial ID when the sheet should manage current selection:

```swift
page.attachedSheet(
    isPresented: $showDetails,
    detents: detents,
    initialDetent: compact.id
) {
    DetailsView()
}
```

Or supply the selection binding when the application should control it:

```swift
page.attachedSheet(
    isPresented: $showDetails,
    detents: detents,
    selectedDetent: $selectedDetent
) {
    DetailsView()
}
```

The two selection parameters never appear together. With an external binding, its current value is also the initial selection. Closing a sheet does not reset that binding.

Both forms also accept `item: Binding<Item?>` in place of `isPresented`, and a content builder receiving `Item`. `Item` must be `Identifiable`; it need not be `Equatable`.

All four overloads accept an optional `onDismiss: () -> Void`.

## Content actions

```swift
struct DetailsView: View {
    @Environment(\.sheet) private var sheet

    var body: some View {
        VStack {
            Button("Expand") {
                sheet.selectDetent(.init(rawValue: "expanded"))
            }
            Button("Close") {
                sheet.dismiss()
            }
        }
        .padding()
    }
}
```

These operations affect the presentation that injected the environment. They do nothing outside a TideSheet or after that presentation starts dismissing or ends. Unknown IDs passed to `selectDetent` are ignored. There is no per-action completion callback or public content-size invalidation method.

## State and lifetime

- Detents must be nonempty and have unique IDs and valid height values. The initial or externally bound ID must exist in the set. Invalid configuration fails a precondition.
- Internal selection initializes once for each presentation. Changing content, geometry, or the configured initial ID does not reset a still-valid current selection.
- If an internally selected detent is removed, selection returns to the currently configured initial ID. With external selection, update the binding and detents together to retain a valid selection.
- The same item ID updates content in place and preserves its SwiftUI state. A new item ID closes the old presentation before opening the new one. Pending changes are reconciled against the latest binding.
- Environment, backdrop, and drag dismissal clear the matching presentation binding when closure is requested. External binding-driven closure does not write it a second time.
- `onDismiss` runs once after the closing animation has completed. State is cleared before the callback, so it can request another presentation. Old completion callbacks and environment actions cannot clear a newer request.
- Releasing the host's SwiftUI state also ends its active presentation and invokes `onDismiss`, without clearing an externally shared presentation binding. This notification follows state lifetime, not every `onDisappear`.
- Navigation away from a retained host does not constitute dismissal. Attaching to a route places the surface inside that route; attaching above a navigation stack places it above that stack. TideSheet never inspects navigation state.

## Geometry and interaction in this slice

The host's bounds define available height and backdrop coverage. Give the host the space you intend the sheet to occupy. Attaching to a small `Text` does not create a screen-wide presentation, and relocating an attachment does not make it an independent modal.

Content, fixed, fractional, and maximum height policies describe the complete outer surface, including its 28-point drag-indicator region. Heights are clamped to the measured host height. `.content` uses the content's fitting height at the available width; content and host size changes automatically re-resolve the layout. Equal physical heights retain the logical selected ID.

This slice measures a single intrinsically sized content hierarchy. Content is top-aligned and clipped to the selected height. A scroll view or other vertically flexible content needs an explicit content height; automatic scroll handoff and filling flexible content to the selected detent are not implemented yet.

Drag the indicator region to resize. Gesture cancellation resets the transient drag without committing a detent. Settlement uses projected drag position and the nearest physical resting point; a downward projection below 60% of the lowest point requests dismissal. The body does not install a drag recognizer over application controls.

The initial appearance uses a rounded surface, a dimming layer, and spring animation. Tapping the backdrop dismisses. Accessibility adjustment on the indicator switches resting points, accessibility escape requests dismissal, and Reduce Motion disables the default animation. These are initial defaults, not a complete accessibility or styling API.

For an independent modal scope, use [`bottomSheet`](SwiftUI-Bottom-Sheet.md). It shares these detent, selection, content-identity, and interaction rules, with an additional native modal lifecycle before `onDismiss`.

Scroll handoff, keyboard policy, full platform adaptation, configurable visuals and animation, and multiple-sheet coordination remain future work. No tagged release or cross-renderer completeness is implied.

See the [standalone example](../Examples/AttachedSheet/README.md) for all four overloads, content and host resizing, item updates, navigation, and drag interaction.
