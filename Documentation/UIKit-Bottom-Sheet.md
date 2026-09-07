# UIKit Bottom Sheet

`TideSheetUIKit` presents UIKit content through a native custom modal or an explicit child-controller attachment. Both contexts reuse one internal surface, the shared `TideSheetDetent` model, and a weak `BottomSheetHandler`. The module does not depend on the SwiftUI renderer.

## Presentation

```swift
import TideSheet
import TideSheetUIKit
import UIKit

let compact = TideSheetDetent(id: .init(rawValue: "compact"), height: .fixed(320))
let expanded = TideSheetDetent(id: .init(rawValue: "expanded"), height: .maximum)
let configuration = BottomSheetConfiguration(
    detents: [compact, expanded],
    initialDetent: compact.id
)

let handler = presentBottomSheet(
    contentViewController,
    configuration: configuration,
    onDismiss: { /* This presentation has ended. */ }
)
```

Call `presentBottomSheet` on the owning `UIViewController`. Its `presentation: SheetPresentation` parameter defaults to `.modal`; use `.attached` when the sheet should belong to that controller's view hierarchy. The content controller must not already have a parent or presenter. Present and attach from a stable, visible host; TideSheet does not choose a global presenter or repair invalid UIKit presentation requests.

The entry accepts `animated`, an optional `onDismiss`, and an optional presentation `completion`. The completion means entry has finished; it does not mean the sheet has closed. The returned handler can be retained by application content without retaining the sheet.

## Controls and selection

```swift
handler.selectDetent(expanded.id)
handler.invalidateContentSize(animated: true)
handler.onSelectedDetentChange = { id in
    // Update application UI after the selection settles.
}
handler.dismiss(animated: true) {
    // Continue application navigation after teardown.
}
```

- `selectedDetent` reads the current logical ID and becomes `nil` after the presentation ends or is released.
- `selectDetent` ignores unknown IDs and ending presentations. Temporarily equal physical heights retain the selected logical ID.
- `onSelectedDetentChange` reports changed, settled selections, with no initial notification. A superseded animation need not report its intermediate selection.
- `invalidateContentSize` coalesces updates and remeasures content detents. Changes to a child's `preferredContentSize` also invalidate layout automatically.
- `dismiss` routes through the presentation owner. Repeated requests share teardown, and every supplied completion runs. An already-ended or released handler completes immediately.

Configuration is an immutable snapshot for one presentation. The detent set is unordered, with nonempty, unique IDs and valid height declarations required. `initialDetent` must be in the set. There is no runtime configuration replacement API.

## Content and outer geometry

The renderer supplies available outer height to the shared resolver. Modal height is limited by the container's top safe area and reaches the bottom edge. Attached layout uses its host bounds and top safe area. Height does not gain an additional bottom safe-area allowance.

For `.content`, a positive finite `preferredContentSize.height` supplies the content height. Otherwise, the renderer measures Auto Layout content at the actual available width. Measurement includes `contentTopInset`, which defaults to 28 points for the indicator. Content changes that do not update `preferredContentSize` should call `invalidateContentSize`. Width changes invalidate the cached measurement. A set containing only fixed, fractional, and maximum detents does not measure content.

The child root fills the content area. `contentTopInset: 0` lets it extend beneath the indicator; this is chrome configuration, not a safe-area adjustment. The native child retains normal safe-area propagation. Content chooses where to use `safeAreaLayoutGuide`, `keyboardLayoutGuide`, and its own scroll views. TideSheet does not change `additionalSafeAreaInsets`, add uniform safe-area padding, watch keyboard notifications, or implement scroll-view gesture handoff.

Content must provide meaningful fitting height when using a content detent. A scrolling controller can instead use fixed, fractional, or maximum detents and fill its assigned content area.

## Appearance and interaction

`BottomSheetConfiguration` owns the surface color, indicator color, corner radius, content top inset, backdrop, and two independent dismissal options. Defaults use system background, a rounded top edge, a dimming color, and indicator dragging.

The initial drag hit region is the top 44 points. It supports any number of declared detents and downward dismissal; content scrolling remains separate. Turning off `dismissesOnSwipe` keeps detent changes available while preventing downward closure. Cancelling a drag returns to its original logical selection. Programmatic selection can interrupt a settling animation, and container changes resolve the current ID again.

`.color` backdrops animate their opacity with presentation and drag progress. `.custom` creates fresh caller-owned background content for each presentation; TideSheet lays it out and removes it without changing its opacity or driving its animation. Background interaction and accessibility are handled by a separate dismissal control. Do not return a view that already belongs to another hierarchy.

The indicator exposes accessibility adjustment, escape respects the dismissal options, and entry/exit moves accessibility focus between the sheet and host. Reduce Motion disables the renderer's transition and height animations. Full accessibility and device-matrix validation remains follow-up work.

## Ownership and lifetime

Modal uses `UIPresentationController` and a custom transition. An underlying navigation push stays behind it. Dismissing through the handler removes the sheet and its descendant modal presentations, then finishes the request.

Attached uses child containment and the view bounds of the chosen host. Attaching to a content controller does not automatically extend coverage above its navigation controller's bar. An ordinary push and pop preserves the sheet and content state. Explicit dismissal removes its child hierarchy; a visible host's ordinary exit also ends the attachment. `onDismiss` is one-shot across observable teardown paths. Do not use ordinary `viewDidDisappear` as a signal that a retained route's sheet has ended.

An attached handler removes its local sheet hierarchy; it does not dismiss native pages presented by the host. Content or application navigation should return from such a page before closing the attachment.

As in the existing project contract, an already-offscreen host removed by an arbitrary navigation-stack rewrite does not have an immediate-detachment guarantee. A caller requiring synchronous cleanup should dismiss before rewriting the stack. No Router observation, registry, queue, or process-wide presentation coordination is introduced.

## Verification and remaining scope

The [standalone UIKit example](../Examples/UIKit/README.md) uses only the `TideSheetUIKit` product. All 35 package unit tests pass, including 11 UIKit tests covering measurement, shared detent resolution, coalesced identities, weak handles, one-shot notification, containment, appearance, and custom backdrop ownership.

All 12 UIKit UI tests pass on iPhone 17 Pro Max / iOS 26.5. They cover the unified `presentation` parameter, both SwiftUI-content bridge scenarios, modal and attached navigation, returning to attached content from a native modal, dynamic preferred-size updates, repeated dismissal, immediate dismissal during entry, descendant modal closure, native content keyboard layout, and scrolling without sheet resizing. The deployment target is iOS 17. Minimum-version runtime, rotation, iPad, full accessibility, and arbitrary navigation cancellation/removal remain follow-up validation.

This initial slice accepts native UIKit content. A [system-adapter example](Cross-Content-Bridges.md) also hosts SwiftUI through `UIHostingController` using these same entry points; dedicated bridge conveniences remain open. No tagged release or complete capability-matrix support is implied.

See [Release Readiness](Release-Readiness.md) for the remaining validation and delivery work.
