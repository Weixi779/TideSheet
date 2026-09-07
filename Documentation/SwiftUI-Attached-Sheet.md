# SwiftUI Attached Sheet

Use `.bottomSheet(presentation: .attached, ...)` for a sheet that belongs to its declaring page. It covers the containing navigation area, leaves when that page is pushed away, and restores the same content and selection on return. The surface, state, layout, animation, and gestures remain SwiftUI. A local UIKit carrier adapter places a hosting view above navigation chrome and follows the page's transition coordinator; it does not execute `TideSheetUIKit`, present a modal, replace navigation delegates, or search for a global presenter.

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
page.bottomSheet(
    isPresented: $showDetails,
    presentation: .attached,
    detents: detents,
    initialDetent: compact.id
) {
    DetailsView()
}
```

Or supply the selection binding when the application should control it:

```swift
page.bottomSheet(
    isPresented: $showDetails,
    presentation: .attached,
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
- Navigation away from a retained page does not constitute dismissal. A local anchor follows that page's navigation transition, including cancellation, while retaining its SwiftUI content. NavigationLink values and environment values come from the declaration site. No Router or navigation delegate is installed.
- Ownership follows the declaration site. A declaration outside a `NavigationStack` belongs to that outer root, not to whichever child destination happens to be visible. Put a page-owned declaration in that page.
- Presentation style is captured at opening. A changed `presentation` value takes effect on the next presentation.
- Removing the declaration tears down the rendering container. Synchronous notification for arbitrary removal of an already-offscreen route is not guaranteed; dismiss explicitly before rewriting a stack if required.

## Geometry and interaction in this slice

The page's containing navigation area defines backdrop coverage, rather than the size of the modified view. A declaration on a small button still covers the navigation bar and bottom edge. Without navigation, the page's own controller is the container. No extra root modifier is required. This is page attachment; local subview overlays should use SwiftUI composition directly.

Content, fixed, fractional, and maximum height policies describe the complete outer surface, including its 28-point drag-indicator region. Heights are clamped to the measured container height. `.content` uses the content's fitting height at the available width; content and container size changes automatically re-resolve the layout. Equal physical heights retain the logical selected ID.

This slice measures a single intrinsically sized content hierarchy. Content is top-aligned and clipped to the selected height. A scroll view or other vertically flexible content needs an explicit content height; filling flexible content to the selected detent remains follow-up layout work. Scroll-view gesture handoff is outside the component's scope.

Content and its host decide how to use native safe-area and keyboard layout behavior. TideSheet adds no uniform safe-area padding to content and implements no keyboard tracking, keyboard-driven movement, or scrolling to an input. Resizing only the declaring button or stack does not resize the presentation container. See the [content ownership decision](Design-Decisions.md#12-content-owns-safe-area-usage-keyboard-layout-and-scrolling).

Drag the indicator region to resize. Gesture cancellation resets the transient drag without committing a detent. Settlement uses projected drag position and the nearest physical resting point; a downward projection below 60% of the lowest point requests dismissal. The body does not install a drag recognizer over application controls.

The initial appearance uses a rounded surface, a dimming layer, and spring animation. Tapping the backdrop dismisses. Accessibility adjustment on the indicator switches resting points, accessibility escape requests dismissal, and Reduce Motion disables the default animation. These are initial defaults, not a complete accessibility or styling API.

For an independent modal scope, use the same [`bottomSheet`](SwiftUI-Bottom-Sheet.md) entry with `presentation: .modal` (or omit the parameter). It shares these detent, selection, content-identity, and interaction rules, with an additional native modal lifecycle before `onDismiss`.

Full platform adaptation, configurable visuals and animation, and multiple-sheet coordination remain future work. Content keyboard layout and scrolling remain content responsibilities. No tagged release or cross-renderer completeness is implied.

See the [standalone example](../Examples/SwiftUI/README.md) for all four overloads, content resizing and independence from the declaration size, item updates, navigation, and drag interaction.

The [cross-content experiments](Cross-Content-Bridges.md) also demonstrate a UIKit controller adapted through `UIViewControllerRepresentable` with an explicit content-height contract. This uses the existing content closure, with no dedicated TideSheet bridge API.

## Verification

The September 7 unified-API revision passes all 18 SwiftUI UI tests on iPhone 17 Pro Max / iOS 26.5. The checks include full navigation-bar and bottom-edge coverage from a small button, real backdrop tap interception, ordinary push/pop, interactive return and cancellation, source-page removal, a native sheet opened from attached content, portrait/landscape rotation, detent and item state, changing the next presentation style, and both content frameworks. Final result attachments contain no runtime hierarchy warnings. Screenshots verify the navigation mask and bottom surface.

The iOS 17 deployment target builds, but minimum-version runtime, iPad, multi-scene and tab/split-view combinations, and the complete accessibility matrix remain unverified.
