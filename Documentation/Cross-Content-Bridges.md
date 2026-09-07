# Cross-Content Bridge Experiments

> Status: Initial system-bridge examples; dedicated public conveniences remain open.
>
> September 7, 2026

These examples test the accepted rule that the root chooses the renderer. They use Apple's content adapters inside existing TideSheet entry points. They introduce no new public TideSheet API, renderer dependency, or shared platform type.

| Root | Content adapter | Presentation owner | Controls |
| --- | --- | --- | --- |
| UIKit | `UIHostingController` | `TideSheetUIKit` | Existing weak `BottomSheetHandler` |
| SwiftUI | `UIViewControllerRepresentable` | `TideSheetSwiftUI` | Existing `SheetActions`, passed into UIKit callbacks |

The same adapter is used in attached and modal contexts. Adapting content does not change navigation scope.

## UIKit Root, SwiftUI Content

The [UIKit example](../Examples/UIKit/SwiftUIContentExample.swift) creates a `UIHostingController` and passes it to `presentBottomSheet(presentation:)`. It depends only on the `TideSheetUIKit` package product.

```swift
let controller = UIHostingController(rootView: ContentView(model: model))
let handler = presentBottomSheet(controller, configuration: configuration)
model.handler = handler
```

The application's observable model supplies title updates and selection feedback. SwiftUI keeps local interaction state with `@State`. The model retains the weak handler, and callbacks back to the owner and hosting controller capture them weakly. The content accepts these application-supplied controls; it does not import `TideSheetSwiftUI` to obtain its environment key.

### Fitting height at the actual width

This content has an intrinsically sized vertical body. It measures that body at its actual SwiftUI width and reports its size through the hosting controller's `preferredContentSize`. The outer hosting view fills the assigned UIKit content area and aligns the body at the top.

```swift
bodyContent
    .frame(maxWidth: .infinity)
    .fixedSize(horizontal: false, vertical: true)
    .onGeometryChange(for: CGSize.self, of: { $0.size }) { size in
        onSizeChange(size)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
```

The callback changes `preferredContentSize` only when the measured size changes. The existing UIKit renderer invalidates its measurement and adds its own indicator spacing. The content does not add sheet chrome or a bottom safe-area allowance to the reported body size.

Apple also provides hosting-controller `sizingOptions` that track ideal size. The example makes its fitting-width contract explicit rather than assuming that any ideal-size query means the height of wrapped content at the final width. See Apple's [sizing options](https://developer.apple.com/documentation/swiftui/uihostingcontrollersizingoptions) and [UIKit integration session](https://developer.apple.com/videos/play/wwdc2022/10072/).

This is an intrinsic-body recipe. A scroll view or another vertically flexible body needs an explicit sizing choice; measuring an unconstrained flexible body is not a universal content-detent strategy.

## SwiftUI Root, UIKit Content

The [SwiftUI example](../Examples/SwiftUI/UIKitContentExample.swift) puts a `UIViewControllerRepresentable` inside the item-driven `bottomSheet(presentation:)` content closure. It depends only on the `TideSheetSwiftUI` product.

```swift
host.bottomSheet(item: $item, detents: detents, initialDetent: initialDetent) { item in
    ControllerContent(title: item.title)
}
```

The representable creates a controller in `makeUIViewController`, updates its title and callbacks in `updateUIViewController`, and clears callbacks in `dismantleUIViewController`. SwiftUI supplies containment and appearance forwarding. The adapter does not call UIKit `present` or create another sheet surface.

`ControllerContent` reads `@Environment(\.sheet)` and passes close and select actions into the controller. A native `UIViewController.dismiss` call is not the TideSheet action for this path. Navigation remains an application callback.

### A concrete preferred-height contract

This sample controller owns its preferred height. It reports changes to an outer SwiftUI state value, and that value provides an explicit `.frame(height:)` around the representable. The initial state matches the controller's initial height. The sheet's existing geometry measurement then observes the changed content height.

The size callback runs for content changes, not during `updateUIViewController`. Updating an item changes the existing controller's title and callbacks without recreating its local counter. Replacing the item follows the existing sheet identity and dismissal sequence.

This is an application-specific content adapter, not automatic observation of arbitrary UIKit controllers. A different controller might need an Auto Layout fitting measurement at the proposed width, explicit scrolling dimensions, or a model-provided height. Apple's [UIViewControllerRepresentable sizing hook](https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable/sizethatfits(_:uiviewcontroller:context:)) accepts proposed sizes and may be called more than once in a layout pass; it is an available platform mechanism, not a new TideSheet sizing policy.

## What These Examples Establish

The content bridge adapters live in the examples. The unified API adds the shared `SheetPresentation` value; the content adapters do not add platform types to that shared module or introduce a dependency between renderers. The experiment also exposed a SwiftUI modal input-synchronization issue: after the underlying route was pushed offscreen, its item replacement could stop reconciling and leave the old content's actions unable to close the sheet. The modal now also reconciles input from its still-presented content tree and advances a pending replacement from native dismissal completion. This keeps the same SwiftUI presentation owner and applies equally to native and bridged content.

The focused UI scenarios exercise both adapters in both presentation contexts. They check dynamic content height, programmatic selection, content-state retention through updates and navigation, dismissal, and reopening. The UIKit-root scenarios also exercise completion-driven navigation. The SwiftUI-root scenarios exercise same-ID updates and different-ID replacement.

Validation of the unified API includes all 35 package unit tests, 18 SwiftUI UI tests, and 12 UIKit UI tests, including the content-bridge scenarios. Formatting, project-file validation, and local documentation links also pass. See the [SwiftUI attached verification](SwiftUI-Attached-Sheet.md#verification) for navigation and rotation coverage.

The build deployment target is iOS 17. Runtime checks use portrait iPhone 17 Pro Max on iOS 26.5. Minimum-version runtime, rotation, iPad, arbitrary content teardown and memory profiling, full accessibility, keyboard layout across both content frameworks, and general flexible-content measurement remain outside this experiment. This evidence does not establish complete bridge or release support.

## Candidate Convenience APIs

The samples establish that existing TideSheet entry points already compose with system adapters. The remaining application code is content sizing, state projection, and action wiring. The two directions have different responsibilities, so a symmetric wrapper API would need more justification than matching names.

A UIKit SwiftUI-builder convenience could remove hosting-controller assembly, but it must still state how content reports fitting height and receives controls. A SwiftUI controller wrapper could remove boilerplate only after identifying a stable controller sizing and update contract. Those remain candidates for a later API discussion, not prerequisites for publishing the existing recipes. The next delivery phase is described in [Release Readiness](Release-Readiness.md).
