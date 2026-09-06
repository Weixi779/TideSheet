# SwiftUI Sheet Example

Open `AttachedSheetExample.xcodeproj`, choose the `AttachedSheetExample` scheme, and run on an iOS 17+ simulator using Xcode 26 or later.

This is a package-external SwiftUI app. It depends only on the local `TideSheetSwiftUI` product and explicitly imports `TideSheet` and `TideSheetSwiftUI`. No project generator or external dependency is required.

The catalog has four attached pages and four modal pages. Each context exercises Boolean/item presentation and internal/external detent selection. Item pages also update the current item or replace its identity.

Attached pages demonstrate content and host resizing, local view state, and navigation away and back. The navigation bar remains outside the attachment's bounds so the host scope is visible.

Modal pages apply `bottomSheet` to a small button. They demonstrate full-width independent presentation, underlying navigation while the sheet stays visible, and navigation from `onDismiss`. They also compare closure through the sheet environment, the external binding, and SwiftUI's system dismiss action.

The indicator is the drag region in both contexts. Content owns its padding, keyboard layout, and scrolling; TideSheet does not add safe-area padding or scroll-view gesture handoff. Content remains intrinsically measured in this initial example, and general flexible-content layout remains follow-up work.

Run the scheme's UI tests with **Product > Test**. Core and renderer state tests belong to the package's `TideSheet-Package` scheme.

The [attached guide](../../Documentation/SwiftUI-Attached-Sheet.md) and [modal guide](../../Documentation/SwiftUI-Bottom-Sheet.md) record the supported behavior and current limits.
