# TideSheet

TideSheet is an in-progress custom bottom-sheet library designed for UIKit and SwiftUI roots, with modal and host-attached presentation contexts.

> TideSheet is under active development. Its public API may change before 1.0.

The shared detent domain and initial native UIKit and SwiftUI attached and modal sheets are available. Cross-content bridges, further SwiftUI content layout, and broader platform validation remain on the roadmap.

Content owns safe-area usage, keyboard layout, and scrolling. TideSheet does not add a content inset policy, automatic keyboard avoidance, or scroll-view gesture handoff.

## Requirements

- iOS 17 or later
- Xcode 26 or later
- Swift 6.2 or later

## Modules

- `TideSheet` is the canonical public module for shared sheet values and rules.
- `TideSheetUIKit` supports UIKit content through `presentBottomSheet` and `attachBottomSheet`, with weak `BottomSheetHandler` controls. A dedicated SwiftUI-content bridge is planned.
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

- [UIKit bottom-sheet API and lifetime](Documentation/UIKit-Bottom-Sheet.md)
- [Runnable UIKit example](Examples/UIKit/README.md)
- [SwiftUI attached-sheet API and current limits](Documentation/SwiftUI-Attached-Sheet.md)
- [SwiftUI modal bottom-sheet API and lifecycle](Documentation/SwiftUI-Bottom-Sheet.md)
- [Runnable SwiftUI example](Examples/AttachedSheet/README.md)
- [Design decisions](Documentation/Design-Decisions.md)
- [Roadmap](Documentation/Roadmap.md)
