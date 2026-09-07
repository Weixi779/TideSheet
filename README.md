# TideSheet

TideSheet is an in-progress custom bottom-sheet library designed for UIKit and SwiftUI roots, with modal and host-attached presentation contexts.

> TideSheet is under active development. Its public API may change before 1.0.

The shared detent domain and initial native UIKit and SwiftUI attached and modal sheets are available. System content-bridge examples are included for both directions. Dedicated bridge APIs, further SwiftUI content layout, and broader platform validation remain on the roadmap.

Content owns safe-area usage, keyboard layout, and scrolling. TideSheet does not add a content inset policy, automatic keyboard avoidance, or scroll-view gesture handoff.

## Requirements

- iOS 17 or later
- Xcode 26 or later
- Swift 6.2 or later

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

- [Cross-content bridge experiments and API questions](Documentation/Cross-Content-Bridges.md)
- [UIKit bottom-sheet API and lifetime](Documentation/UIKit-Bottom-Sheet.md)
- [Runnable UIKit example](Examples/UIKit/README.md)
- [SwiftUI attached-sheet API and current limits](Documentation/SwiftUI-Attached-Sheet.md)
- [SwiftUI modal bottom-sheet API and lifecycle](Documentation/SwiftUI-Bottom-Sheet.md)
- [Runnable SwiftUI example](Examples/SwiftUI/README.md)
- [Design decisions](Documentation/Design-Decisions.md)
- [Roadmap](Documentation/Roadmap.md)
