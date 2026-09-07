# TideSheet Examples

Open [TideSheetExamples.xcworkspace](TideSheetExamples.xcworkspace) in Xcode 26 or later. Select a scheme and an iOS 17+ simulator, then choose **Product > Run** (`⌘R`).

| Scheme | App root | Package product |
| --- | --- | --- |
| `SwiftUISheetExample` | SwiftUI App and NavigationStack | `TideSheetSwiftUI` |
| `UIKitSheetExample` | UIKit Scene and UINavigationController | `TideSheetUIKit` |

These are two independent apps with shared schemes. The workspace collects their projects for convenient navigation; each project can also be opened and run on its own. Both resolve the package from this checkout, with no project generator or extra setup.

- [SwiftUI example](SwiftUI/README.md): attached and modal presentation, Boolean/item state, detent selection, and UIKit content.
- [UIKit example](UIKit/README.md): attached and modal presentation, styling, native keyboard and scroll content, and SwiftUI content.

Choose **Product > Test** (`⌘U`) to run the selected app's UI tests. The scenarios cover both presentation settings through each renderer's unified API. Package unit tests remain in the package's `TideSheet-Package` scheme.
