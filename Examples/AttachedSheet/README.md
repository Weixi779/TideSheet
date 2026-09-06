# Attached Sheet Example

Open `AttachedSheetExample.xcodeproj`, choose the `AttachedSheetExample` scheme, and run on an iOS 17+ simulator using Xcode 26 or later.

This is a package-external SwiftUI app. It depends only on the local `TideSheetSwiftUI` product and explicitly imports `TideSheet` and `TideSheetSwiftUI`. No project generator or external dependency is required.

The four pages exercise Boolean/item presentation and internal/external detent selection. In a sheet you can select any height policy, resize its content or host, change local view state, and navigate to another route. Item pages also update the current item or replace its identity.

The indicator is the drag region. The example deliberately leaves the navigation bar outside the attachment's bounds so the host scope is visible.

Run the scheme's UI tests with **Product > Test**. Core and renderer state tests belong to the package's `TideSheet-Package` scheme.

The [API guide](../../Documentation/SwiftUI-Attached-Sheet.md) records the supported behavior and current limits.
