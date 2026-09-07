# Release Readiness

> Audited: September 7, 2026
>
> Status: First public preview — `0.1.0-beta.1`.

The first beta covers both renderer products, both presentation relationships, native content, and the documented system-adapter recipes. It is a preview of the current contract, not a claim of complete platform coverage or 1.0 stability. This record distinguishes completed checks from the work still needed to broaden support.

## Current Evidence

| Area | Verified state |
| --- | --- |
| Repository | [Weixi779/TideSheet](https://github.com/Weixi779/TideSheet) is public, uses `main`, and includes an MIT [license](../LICENSE). The first version is `v0.1.0-beta.1`; no Actions workflow is present. |
| Package | iOS 17 deployment target, Swift tools 6.2 minimum, two renderer products, one canonical shared module, and no external package dependencies. |
| API | SwiftUI `bottomSheet(presentation:)` and UIKit `presentBottomSheet(presentation:)`; `.modal` is the default and `.attached` follows its owning page. |
| Examples | Two independent apps in a shared [workspace](../Examples/TideSheetExamples.xcworkspace). Both include native content and a system-adapter recipe for the other content framework. |
| Package tests | 35 passed: 8 shared-domain, 16 SwiftUI, and 11 UIKit tests. All 35 also pass in Release configuration with testability enabled after the compiler compatibility fix. |
| UI tests | 18 SwiftUI and 12 UIKit tests passed on iPhone 17 Pro Max / iOS 26.5 using Xcode 26.6 / Swift 6.3.3. No failures or skipped tests in the final results. |
| Release UI regression | After the compiler compatibility fix, 5 focused SwiftUI UI tests pass in Release: attached navigation retention, navigation/bottom coverage, nested native presentation, owner removal, and repeated modal dismissal. The earlier complete UI suite was run in Debug. |
| Visual evidence | SwiftUI attached navigation-bar and bottom-edge coverage inspected in portrait; attached rotation inspected in landscape. Navigation interception, retention, cancellation, and nested native presentation have UI coverage. |
| Static checks | Swift formatting, project-file validation, workspace/scheme references, and local documentation links pass. |
| Release builds | Both independent example apps pass unsigned Release builds for a generic iOS device destination with the iOS 17 deployment target, using Xcode 26.6 / Swift 6.3.3. |
| Documentation | API guides, accepted decisions, example instructions, bridge findings, roadmap, exact-version installation instructions, and a [changelog](../CHANGELOG.md) are present. |

These are simulator results for the recorded configurations. An iOS 17 deployment build is not an iOS 17 runtime test. The attached rotation result does not prove modal, UIKit, iPad, or multi-scene adaptation. The current checks are not a retained-object or full accessibility audit.

## First Beta Scope and Packaging

Use the exact version `0.1.0-beta.1` as shown in the [installation guide](../README.md#installation). Each renderer product includes the canonical shared module; no dependency on the other renderer is required. Cross-framework content uses the existing system-adapter recipes, not a new TideSheet bridge API.

The validated runtime is iPhone 17 Pro Max / iOS 26.5. There is no iOS 17 simulator runtime installed in the release-preparation environment. Physical devices, iPad, tab/split-view, and multi-scene configurations remain unverified. A deployment target and a successful unsigned device build are not runtime verification on those devices.

Release preparation found a compiler crash that Debug testing did not expose. Swift's generic isolated-deinit optimization can crash when back-deploying to older systems ([upstream issue](https://github.com/swiftlang/swift/issues/90625)). Explicit nonisolated empty deinitializers avoid unnecessary synthesized isolation; the host-state deinitializer retains its MainActor callback and disables optimization only for that deinitializer. Both renderer targets otherwise retain their normal Release optimization.

The published GitHub release records the final exact-tag remote-consumer check. Consumers must resolve the published tag rather than a local path or moving branch.

## Remaining Validation Before Broader Support

| Work | Current gap | Completion evidence |
| --- | --- | --- |
| Minimum runtime | Runtime results cover iOS 26.5 only. | Run key show/resize/dismiss/navigation flows on iOS 17 and record the runtime and toolchain. |
| Navigation, layout, and lifecycle | The SwiftUI attached path has the strongest navigation/rotation coverage. UIKit/modal compact-height adaptation and memory profiling remain open. | Check small-screen and landscape behavior in both renderers and both relationships, including source removal, cancellation, nested presentation, repeated opening, and weak-release probes or memory inspection. Record which bridged-content cases were included. |
| Accessibility and content layout | Initial accessibility behavior exists, but VoiceOver, Dynamic Type, and Reduce Motion are not fully exercised. Cross-framework input layout is also incomplete as evidence. | Verify basic focus entry/return, background isolation, resize/dismiss actions, large text, and reduced motion. Exercise representative inputs using content-owned safe-area and keyboard layout without changing TideSheet's ownership contract. |
| Repeatable verification | No CI workflow is present. | Add and run a pinned-toolchain workflow for package tests and both external example Release builds, with focused UI regression coverage and retained results. Keep the minimum-runtime result recorded even if it needs a separate runner. |

For iPad, tab/split-view, and multi-scene behavior, validation is required before including them in the support claim. These remain explicitly unverified in this beta. Minimum-runtime and lifecycle validation are the next steps; additional public APIs need a concrete consumer requirement.

## Current Contract Limits to Carry into Release Notes

- SwiftUI attached presentation covers its page's navigation area. UIKit attached presentation uses the bounds of the explicitly chosen host; it does not automatically rehost above that host's navigation controller. Shared presentation values describe the ownership relationship, not identical renderer containment.
- SwiftUI currently measures a single intrinsically sized body. Flexible or scrolling content needs an explicit sizing choice; automatic filling to the selected detent remains later work.
- Content owns safe-area usage, input layout, and scrolling. TideSheet does not add automatic keyboard avoidance or scroll-view gesture handoff.
- SwiftUI presentation style is captured when opening. Changing it affects the next presentation. Temporarily leaving an attached page does not dismiss its sheet or call `onDismiss`.
- Arbitrary stack rewrites removing a retained offscreen owner do not promise immediate teardown notification. Callers needing synchronous cleanup dismiss before the rewrite.
- The unified API removed the old separate attached entry points. Replace `attachedSheet(...)` with `bottomSheet(presentation: .attached, ...)`, and `attachBottomSheet(...)` with `presentBottomSheet(presentation: .attached, ...)`.

## Later Work, Not Automatic Prerelease Blockers

- Dedicated cross-content convenience APIs, after a stable sizing/update/control contract is demonstrated.
- General flexible SwiftUI content layout and additional renderer-specific styling or animation configuration.
- A full DocC site and the longer experience-article series; existing API guides should remain the source of the supported contract.
- Broader platform and accessibility matrices beyond the first release's declared support.

Stacking, queues, global presentation, Router integration, automatic keyboard avoidance, and scroll handoff remain outside the accepted scope. The [1.0 exit condition](Roadmap.md#10-exit-condition) also requires real consumer feedback and the supported cross-content matrix; publishing this preview alone does not establish 1.0 readiness.
