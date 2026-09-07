# TideSheet

TideSheet is a custom bottom-sheet library designed for UIKit and SwiftUI roots, with modal and host-attached presentation contexts.

> Current preview: **0.1.0-beta.1**. TideSheet is under active development; its public API may change before 1.0.

The first beta includes the unified presentation API, UIKit and SwiftUI renderers, and two runnable example apps. System content-bridge examples are included for both directions. See the [release notes](https://github.com/Weixi779/TideSheet/releases/tag/v0.1.0-beta.1), [changelog](CHANGELOG.md), and [validation record and known gaps](Documentation/Release-Readiness.md).

Content owns safe-area usage, keyboard layout, and scrolling. TideSheet does not add a content inset policy, automatic keyboard avoidance, or scroll-view gesture handoff.

## Requirements

- iOS 17 or later
- Xcode 26 or later
- Swift 6.2 or later

This beta was validated with Xcode 26.6 / Swift 6.3.3 on iPhone 17 Pro Max / iOS 26.5. Both examples also pass unsigned Release builds for an iOS device destination with an iOS 17 deployment target. iOS 17 runtime behavior, physical devices, iPad, and multi-scene configurations remain unverified.

## Installation

In Xcode, add `https://github.com/Weixi779/TideSheet.git` as a package dependency and choose **Exact Version: 0.1.0-beta.1**. Select the renderer product for your application's root framework.

In a Swift package, pin the preview explicitly:

```swift
.package(url: "https://github.com/Weixi779/TideSheet.git", exact: "0.1.0-beta.1")
```

Add one renderer to your target dependencies:

```swift
.product(name: "TideSheetSwiftUI", package: "TideSheet")
// Or: .product(name: "TideSheetUIKit", package: "TideSheet")
```

Each product includes the shared module. Keep the explicit imports shown below.

## Modules

- `TideSheet` is the canonical public module for shared sheet values and rules.
- `TideSheetUIKit` supports UIKit content through `presentBottomSheet(presentation:)`, with weak `BottomSheetHandler` controls. Its example adapts SwiftUI content through `UIHostingController`.
- `TideSheetSwiftUI` supports SwiftUI content through `bottomSheet(presentation:)` for both page attachment and independent modal presentation. Its example adapts UIKit content through `UIViewControllerRepresentable`.

Choose one renderer product. It includes the shared `TideSheet` module, and source files import both modules explicitly:

```swift
import TideSheet
import TideSheetUIKit
```

or:

```swift
import TideSheet
import TideSheetSwiftUI
```

## One API, Two Presentation Relationships

SwiftUI uses `.bottomSheet(isPresented:presentation:detents:initialDetent:content:)` (or the item and selected-detent overloads). UIKit uses `presentBottomSheet(_:presentation:configuration:)`.

- `.modal` is the default: the sheet stays above navigation in the presenting page.
- `.attached` leaves with its page on push and returns with its content state on pop.

In SwiftUI, either style may be declared on a small button. The attached carrier covers the containing navigation area, including its bar, without moving the page's state or requiring a root modifier. Presentation style is captured when opening; changes apply to the next presentation.

## Run the Examples

Open [Examples/TideSheetExamples.xcworkspace](Examples/TideSheetExamples.xcworkspace), choose `SwiftUISheetExample` or `UIKitSheetExample`, select an iOS simulator, and run (`⌘R`). Each is an independent app using only its root renderer product. See the [example guide](Examples/README.md) for details.

## Project Direction

- [Documentation reading guide](Documentation/README.md)
- [Release readiness and remaining work](Documentation/Release-Readiness.md)
- [Cross-content bridge experiments and API questions](Documentation/Cross-Content-Bridges.md)
- [UIKit bottom-sheet API and lifetime](Documentation/UIKit-Bottom-Sheet.md)
- [Runnable UIKit example](Examples/UIKit/README.md)
- [SwiftUI attached-sheet API and current limits](Documentation/SwiftUI-Attached-Sheet.md)
- [SwiftUI unified bottom-sheet API and modal lifecycle](Documentation/SwiftUI-Bottom-Sheet.md)
- [Runnable SwiftUI example](Examples/SwiftUI/README.md)
- [Design decisions](Documentation/Design-Decisions.md)
- [Roadmap](Documentation/Roadmap.md)
