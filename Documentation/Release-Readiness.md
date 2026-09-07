# Release Readiness

> Audited: September 7, 2026
>
> Status: Implementation milestone complete; no tagged release yet.

This document separates repository facts from a recommended release plan. The user-approved unified API and example work is complete. The proposed first-release scope and checklist below do not freeze a version number, broaden supported behavior, or authorize publishing.

## Current Evidence

| Area | Verified state |
| --- | --- |
| Repository | [Weixi779/TideSheet](https://github.com/Weixi779/TideSheet) is public, uses `main`, and includes an MIT [license](../LICENSE). The remote has no tags, GitHub Releases, or Actions workflows at this audit. |
| Package | iOS 17 deployment target, Swift 6.2, two renderer products, one canonical shared module, and no external package dependencies. |
| API | SwiftUI `bottomSheet(presentation:)` and UIKit `presentBottomSheet(presentation:)`; `.modal` is the default and `.attached` follows its owning page. |
| Examples | Two independent apps in a shared [workspace](../Examples/TideSheetExamples.xcworkspace). Both include native content and a system-adapter recipe for the other content framework. |
| Package tests | 35 passed: 8 shared-domain, 16 SwiftUI, and 11 UIKit tests. |
| UI tests | 18 SwiftUI and 12 UIKit tests passed on iPhone 17 Pro Max / iOS 26.5 using Xcode 26.6 / Swift 6.2. No failures or skipped tests in the final results. |
| Visual evidence | SwiftUI attached navigation-bar and bottom-edge coverage inspected in portrait; attached rotation inspected in landscape. Navigation interception, retention, cancellation, and nested native presentation have UI coverage. |
| Static checks | Swift formatting, project-file validation, workspace/scheme references, and local documentation links pass. |
| Documentation | API guides, accepted decisions, example instructions, bridge findings, and the roadmap are present. Versioned installation instructions and release notes remain to be written. |

These are simulator results for the recorded configurations. An iOS 17 deployment build is not an iOS 17 runtime test. The attached rotation result does not prove modal, UIKit, iPad, or multi-scene adaptation. The current checks are not a retained-object or full accessibility audit.

## Recommended First Release

Start with a **pre-1.0 prerelease** covering both renderer products, both presentation relationships, native content, and the documented system-adapter recipes. Keep the initial intrinsic-content sizing contract explicit. A dedicated TideSheet bridge API is not necessary for those recipes to be usable.

The precise version and support matrix remain to be chosen. A preview should describe the validated phone configurations and list unverified iPad, tab/split-view, and multi-scene combinations. It should not claim that all eight root/content/presentation combinations support arbitrary content or every platform configuration.

## Recommended Gates Before Tagging

| Work | Current gap | Completion evidence |
| --- | --- | --- |
| Support scope | No first-release version or verified support matrix has been selected. | README and release notes agree on the version stage, supported configurations, content-sizing limits, and known gaps. |
| Minimum runtime and packaging | Runtime results cover iOS 26.5 only; no Release/device-build or remote-dependency consumer result is recorded for this milestone. | Run key show/resize/dismiss/navigation flows on iOS 17 and the chosen current runtime; build both products and examples in Release for an iOS device destination. Verify a separate consumer resolves the intended Git revision with only the selected renderer product. |
| Navigation, layout, and lifecycle | The SwiftUI attached path has the strongest navigation/rotation coverage. UIKit/modal compact-height adaptation and memory profiling remain open. | Check small-screen and landscape behavior in both renderers and both relationships, including source removal, cancellation, nested presentation, repeated opening, and weak-release probes or memory inspection. Record which bridged-content cases were included. |
| Accessibility and content layout | Initial accessibility behavior exists, but VoiceOver, Dynamic Type, and Reduce Motion are not fully exercised. Cross-framework input layout is also incomplete as evidence. | Verify basic focus entry/return, background isolation, resize/dismiss actions, large text, and reduced motion. Exercise representative inputs using content-owned safe-area and keyboard layout without changing TideSheet's ownership contract. |
| Repeatable verification | No CI workflow is present locally or on the remote. | Add and run a pinned-toolchain workflow for package tests and both external example builds, with focused UI regression coverage and retained test results. Keep the minimum-runtime result recorded even if it needs a separate runner. |
| Release delivery | No versioned install guide, changelog, tag, or release exists. | Add install/quick-start steps, migration and known-limit notes, then publish a tag and prerelease from the verified commit when authorized. Verify clean consumer resolution of that tag. |

For iPad, tab/split-view, and multi-scene behavior, validation is required before including them in the support claim. They can remain explicitly unverified in a focused prerelease. Fix a failure in the chosen support matrix before tagging; adding every optional capability is not the same release gate.

The next implementation slice should be the **minimum-runtime, packaging, and lifecycle validation** above. It gives a concrete answer about whether the current API is ready for outside consumers before adding more public surface.

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

Stacking, queues, global presentation, Router integration, automatic keyboard avoidance, and scroll handoff remain outside the accepted scope. The [1.0 exit condition](Roadmap.md#10-exit-condition) also requires real consumer feedback and the supported cross-content matrix; passing this preview checklist alone does not establish 1.0 readiness.
