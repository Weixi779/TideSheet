# UIKit Sheet Example

Open `UIKitSheetExample.xcodeproj`, choose `UIKitSheetExample`, and run on an iOS 17+ simulator with Xcode 26 or later. The app uses a UIKit scene and navigation controller, imports `TideSheet` and `TideSheetUIKit` explicitly, and depends only on the local `TideSheetUIKit` product.

You can also open the shared [TideSheetExamples workspace](../TideSheetExamples.xcworkspace) and select the same scheme to switch between both example apps.

Every scenario uses `presentBottomSheet(presentation:)`, with `.modal` as the default and `.attached` for page ownership.

The catalog demonstrates:

- Modal and attached presentation with content, fixed, fractional, and maximum detents.
- Local content state, preferred-size updates, and repeated dismissal.
- An underlying navigation push, push/pop retention for attached content, and navigation after closing.
- A modal sheet and its descendant native modal dismissed through the sheet's handler.
- Native full-screen presentation from attached content, returning to the same sheet through UIKit dismissal.
- A custom blur backdrop whose opacity belongs to the application.
- A scrolling table that retains its own gesture and scroll state.
- Immediate dismissal requested during entry in both contexts.
- SwiftUI content hosted by `UIHostingController` in modal and attached contexts, with dynamic fitting height, local state, and the existing weak handler.

The input field uses the content controller's `keyboardLayoutGuide`; the sheet does not implement keyboard avoidance. The indicator is the sheet's drag region.

Run **Product > Test** for the twelve UI scenarios. Package unit tests use the `TideSheet-Package` scheme. See the [UIKit guide](../../Documentation/UIKit-Bottom-Sheet.md) for public API, ownership, and validation limits, and [bridge experiments](../../Documentation/Cross-Content-Bridges.md) for the SwiftUI-content recipe.
