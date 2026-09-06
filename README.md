# TideSheet

TideSheet is an in-progress custom bottom-sheet library designed for UIKit and SwiftUI roots, with modal and host-attached presentation contexts.

> TideSheet is under active development. Its public API may change before 1.0.

The shared detent domain and initial native SwiftUI attached and modal sheets are available. Flexible content layout, scroll handoff, full platform adaptation, the UIKit renderer, and cross-content bridges remain on the roadmap.

## Requirements

- iOS 17 or later
- Xcode 26 or later
- Swift 6.2 or later

## Modules

- `TideSheet` is the canonical public module for shared sheet values and rules.
- `TideSheetUIKit` will own presentation for a UIKit root and accept UIKit or SwiftUI content. It is currently a placeholder.
- `TideSheetSwiftUI` supports SwiftUI content through `attachedSheet` for host composition and `bottomSheet` for independent modal presentation. UIKit content is planned.

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

## Project Direction

- [SwiftUI attached-sheet API and current limits](Documentation/SwiftUI-Attached-Sheet.md)
- [SwiftUI modal bottom-sheet API and lifecycle](Documentation/SwiftUI-Bottom-Sheet.md)
- [Runnable SwiftUI example](Examples/AttachedSheet/README.md)
- [Design decisions](Documentation/Design-Decisions.md)
- [Roadmap](Documentation/Roadmap.md)
