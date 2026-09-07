# Changelog

## [0.1.0-beta.1](https://github.com/Weixi779/TideSheet/releases/tag/v0.1.0-beta.1) — 2026-09-07

First public preview. Requires iOS 17+ and Swift tools 6.2+. The API may change before 1.0.

### Included

- Independent `TideSheetSwiftUI` and `TideSheetUIKit` products, each including the shared `TideSheet` module, with no external dependencies.
- One presentation entry per renderer: SwiftUI `bottomSheet` and UIKit `presentBottomSheet`, with `.modal` and `.attached` relationships.
- Content, fixed-height, fractional, and maximum detents with stable identities; internal selection or external controls; indicator dragging and dismissal.
- SwiftUI Boolean/item presentation and initial-ID/selected-ID overloads, plus `@Environment(\.sheet)` dismiss and selection actions.
- SwiftUI page-owned attachment covering the containing navigation area, with content state retained across push/pop.
- UIKit modal presentation, explicit host attachment, weak handler controls, and configurable surface/backdrop behavior.
- Two independent example apps and documented system-adapter recipes for cross-framework content.

### Release-build compatibility

- Added localized deinitializer workarounds for the Swift 6.2/6.3 generic isolated-deinit optimizer crash when deploying to older iOS versions ([compiler issue](https://github.com/swiftlang/swift/issues/90625)). The host-release callback remains MainActor-isolated; the public API and deployment target are unchanged.
- Both examples pass unsigned Release builds for a generic iOS device destination using Xcode 26.6 / Swift 6.3.3.

### Migration from development snapshots

- Replace SwiftUI `attachedSheet(...)` with `bottomSheet(presentation: .attached, ...)`.
- Replace UIKit `attachBottomSheet(...)` with `presentBottomSheet(presentation: .attached, ...)`.

### Known limits

- Runtime validation is on iPhone 17 Pro Max / iOS 26.5. iOS 17 runtime, physical devices, iPad, tab/split-view, and multi-scene configurations remain unverified.
- SwiftUI measures intrinsically sized content; flexible and scrolling bodies need an explicit sizing choice.
- UIKit attachment stays within the explicitly chosen host's bounds. Choose that host deliberately when navigation-bar coverage is needed.
- Content owns safe-area use, keyboard layout, and scrolling. Automatic keyboard avoidance and scroll-view gesture handoff are outside the current contract.
- Arbitrary stack rewrites removing a retained offscreen SwiftUI owner do not guarantee immediate teardown notification; dismiss first when synchronous cleanup is required.
- Full accessibility, memory, and broader adaptation audits and CI remain follow-up work. This preview does not establish 1.0 readiness.

See [Release Readiness](Documentation/Release-Readiness.md) for detailed validation and [Roadmap](Documentation/Roadmap.md) for the next steps.
