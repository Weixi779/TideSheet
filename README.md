# TideSheet

A native UIKit and SwiftUI bottom sheet for modal, root-scoped, and host-attached presentation.

> TideSheet is under active development. Its public API is not available yet.

## Requirements

- iOS 17 or later
- Xcode 26 or later
- Swift 6.2 or later

## Modules

- `TideSheetUIKit` owns presentation for a UIKit root and accepts UIKit or SwiftUI content.
- `TideSheetSwiftUI` owns presentation for a SwiftUI root and accepts SwiftUI or UIKit content.
- `TideSheetDomain` is an internal target for shared sheet semantics, geometry, and interaction decisions.
