# SwiftUI Sheet Example

Open `SwiftUISheetExample.xcodeproj`, choose the `SwiftUISheetExample` scheme, and run on an iOS 17+ simulator using Xcode 26 or later.

You can also open the shared [TideSheetExamples workspace](../TideSheetExamples.xcworkspace) and select the same scheme to switch between both example apps.

This is a package-external SwiftUI app. It depends only on the local `TideSheetSwiftUI` product and explicitly imports `TideSheet` and `TideSheetSwiftUI`. No project generator or external dependency is required.

The catalog has four attached pages and four modal pages. Each context exercises Boolean/item presentation and internal/external detent selection. Item pages also update the current item or replace its identity.

All pages use `bottomSheet(presentation:)`. Attached pages demonstrate full navigation-area coverage, content resizing, local view state, and navigation away and back. Resizing the declaring view does not resize the sheet container. A small-control example switches the presentation setting between openings.

Modal pages apply `bottomSheet` to a small button. They demonstrate full-width independent presentation, underlying navigation while the sheet stays visible, and navigation from `onDismiss`. They also compare closure through the sheet environment, the external binding, and SwiftUI's system dismiss action.

To compare the two settings, open **Choose presentation**:

1. Open the sheet from the small button. The initial setting is `.attached`; the mask covers the navigation bar and the bottom edge.
2. Increment the counter, then choose **Change next presentation**. The open sheet keeps its original relationship and state.
3. **Push next page**, then return. The attached sheet returns with the same counter.
4. Close and reopen. The new `.modal` setting now keeps the sheet above the underlying navigation.
5. **Native sheet** exercises a system presentation from the custom content. **Leave declaring page** exercises attached teardown when its owner exits.

The indicator is the drag region in both contexts. Content owns its padding, keyboard layout, and scrolling; TideSheet does not add safe-area padding or scroll-view gesture handoff. Content remains intrinsically measured in this initial example, and general flexible-content layout remains follow-up work.

The UIKit-content pages use `UIViewControllerRepresentable` inside the existing sheet content closure. Their controller owns local state and preferred height; the adapter projects title updates and routes sheet actions through the SwiftUI renderer. See the [bridge experiments](../../Documentation/Cross-Content-Bridges.md) for this concrete sizing contract.

Run the scheme's eighteen UI tests with **Product > Test**. Core and renderer state tests belong to the package's `TideSheet-Package` scheme.

The [attached guide](../../Documentation/SwiftUI-Attached-Sheet.md) and [modal guide](../../Documentation/SwiftUI-Bottom-Sheet.md) record the supported behavior and current limits.
