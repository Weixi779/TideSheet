# TideSheet Roadmap

> Status: Working plan
>
> Last updated: September 7, 2026

TideSheet is a pre-1.0, iOS 17+ bottom-sheet library built with Swift 6.2. This roadmap is ordered by dependency rather than date. The order is the current execution plan, not a compatibility promise.

The accepted architectural boundary lives in [Design Decisions](Design-Decisions.md). If implementation evidence challenges that boundary, update the decision explicitly instead of silently changing ownership in code.

## Direction

TideSheet has one canonical shared module and two native renderers:

```text
                    TideSheet
          shared values and layout rules
                  /           \
        TideSheetUIKit   TideSheetSwiftUI
```

The root selects the renderer; the content framework is bridged inside that renderer. `TideSheet` gains a shared abstraction only when both renderers prove that the semantics are genuinely identical.

The implementation strategy is vertical rather than layer-complete: finish one narrow, usable root/context path, verify it, and then use the next renderer to pressure-test the shared domain.

Content owns safe-area usage, keyboard layout, and scrolling. Automatic keyboard avoidance, a content safe-area policy, and scroll-view gesture handoff are non-goals, not prerequisites for the UIKit renderer. See the [accepted content boundary](Design-Decisions.md#12-content-owns-safe-area-usage-keyboard-layout-and-scrolling).

## Status Legend

- **Done**: Implemented and verified in the repository.
- **Next**: The next intended implementation slice.
- **Later**: Ordered work whose details may still change from evidence.
- **Deferred**: Outside the initial roadmap until a concrete consumer establishes a requirement.

## Done — Canonical Core Baseline

The current foundation includes:

- `TideSheet` as the canonical shared module;
- public, renderer-independent `TideSheetDetent` values;
- package-scoped detent resolution and `RestingPoint` logic;
- stable logical identities when detents temporarily share one physical height;
- separate, `MainActor`-isolated `TideSheetUIKit` and `TideSheetSwiftUI` targets;
- renderer products that include the shared module while keeping imports explicit;
- no public `typealias`, exported import, umbrella module, or old domain-module name.

The core tests cover detent resolution. Initial native SwiftUI and UIKit attached and modal slices are implemented below. No dedicated cross-content API is implemented yet.

### Verified baseline

- Core layout tests pass on an iOS Simulator.
- Both renderer products build from package-external consumers using explicit imports.
- The Package manifest and formatting checks pass.

## Done — Initial Native SwiftUI Attached Slice

### Goal

Prove the shared model through a native SwiftUI implementation whose lifetime belongs to an explicit SwiftUI root or subtree.

### Deliverables

- `bottomSheet(presentation: .attached, ...)` overloads for Boolean/item presentation and internal/external selection.
- A `Set` of detents with an explicit initial ID or selected-ID binding.
- A page-owned SwiftUI surface with local container integration inside `TideSheetSwiftUI`.
- Native SwiftUI content only.
- Programmatic show and dismiss.
- A minimal dimming layer, rounded sheet surface, and drag indicator.
- Content, fixed, fractional, and maximum detents.
- Programmatic selection by stable detent identity.
- Dragging from the indicator, transient gesture-state reset on cancellation, settling between resting points, and interactive dismissal.
- Dynamic fitting-content and container measurement, with content top-aligned and clipped to the selected height.
- Re-resolution after measurement changes without silently losing logical selection.
- One-shot dismissal notification and deterministic state cleanup.

SwiftUI owns the view tree, geometry, animation, gesture state, and presentation state. This slice must not execute the UIKit renderer or a UIKit presentation controller.

### Validation

- Core and renderer unit tests cover height resolution, coalesced identities, selection ownership, item updates/replacement, stale actions, one-shot dismissal, reentrant callbacks, and host-state release.
- The [package-external SwiftUI example](../Examples/SwiftUI/README.md) uses only the `TideSheetSwiftUI` product and explicit imports.
- UI tests on iPhone 17 Pro Max / iOS 26.5 exercise all four overloads, height-policy selection, external binding writes, repeated show/dismiss, content and host resizing, dragging, interactive dismissal, item updates, and navigation away/back with retained state.
- Builds use the iOS 17 deployment target. Runtime checks on iOS 17, gesture interruption during an active drag, root-versus-route comparison, and the full accessibility/adaptation matrix remain follow-up validation.

See the [SwiftUI API guide](SwiftUI-Attached-Sheet.md) for the current public contract and limitations. Vertically flexible content, including unbounded scroll views, is not yet measured and filled as a general-purpose sheet body.

### Not in this slice

- independent modal presentation;
- UIKit content;
- scroll-view handoff;
- multiple concurrent sheets, stacking, or queues;
- Router or `NavigationStack` orchestration;
- content keyboard layout, exhaustive accessibility, or platform-adaptation behavior.

### Exit condition

A pure SwiftUI application can attach, resize, drag, select, and dismiss a SwiftUI sheet without importing or executing the UIKit renderer.

## Done — Initial Native SwiftUI Modal Slice

### Deliverables

- `bottomSheet` overloads with the same Boolean/item presentation and internal/external selection choices as the `.attached` style.
- A SwiftUI `fullScreenCover` carrier with a transparent background and independent presentation scope.
- Reuse of the attached implementation's state, content identity, detent resolution, surface, and indicator interaction.
- TideSheet-owned surface animation, with the carrier opening and closing without an additional transition for ordinary TideSheet actions.
- Surface dismissal, carrier removal, and one-shot `onDismiss` in that order; item replacement waits for carrier completion.
- Reconciliation when content invokes SwiftUI's system `dismiss` action directly.
- Initial outer geometry: the backdrop reaches the container edges and the maximum surface avoids the top safe area. Content chooses its own padding; the renderer adds no uniform content safe-area inset.

### Validation

- All 23 core and renderer unit tests pass after sharing the presentation state between contexts.
- All 10 example UI tests pass on iPhone 17 Pro Max / iOS 26.5, including the existing attached scenarios.
- Modal scenarios cover all four overloads, full-width presentation from a small button, selection through actions and bindings, drag dismissal, repeated presentation, same-ID updates, replacement, external closure, and system dismissal.
- Navigation scenarios verify that a modal remains above an underlying push with content state intact, and that navigation from `onDismiss` occurs after closure. Captured screenshots confirm transparent backdrop coverage and the separate modal scope.
- The deployment target remains iOS 17; this runtime validation covers portrait iPhone on iOS 26.5. Minimum-version, rotation, native layout propagation with input content, iPad, accessibility, and arbitrary host-removal checks remain follow-up validation.

See the [modal guide](SwiftUI-Bottom-Sheet.md) for the supported lifecycle and current limits. This slice retains the attached surface's intrinsic-content measurement path.

## Done — Initial Native UIKit Slice

### Goal

Implement the accepted domain semantics with UIKit-native presentation and containment, using the existing application's lifecycle implementation as the reference.

### Deliverables

- One internal UIKit-owned sheet surface and interaction implementation.
- `presentBottomSheet` through a custom presentation controller and transition.
- `presentBottomSheet(presentation: .attached, ...)` through explicit host-owned child-controller containment.
- Native UIKit content only.
- Immutable `BottomSheetConfiguration` using the shared detent set and an explicit initial ID.
- A weak `BottomSheetHandler` for selection, settled-selection observation, content-size invalidation, and dismissal completion.
- Content, fixed, fractional, and maximum detents, including coalesced logical identities.
- Programmatic selection, indicator dragging, settling, and interactive dismissal.
- Content measurement from `preferredContentSize` or Auto Layout at the available width, with cached measurements and explicit invalidation.
- Outer-frame re-resolution after container-size changes, with normal safe-area propagation to content.
- Content-owned safe-area usage, keyboard layout, and scrolling, without a renderer avoidance policy or scroll-view handoff.
- Renderer-owned colors, corner radius, indicator spacing, dismissal options, and a custom backdrop provider; custom backdrop opacity remains caller-owned.
- Initial accessibility adjustment, escape, focus handoff, and Reduce Motion behavior.
- One-shot dismissal after observable teardown, with completion for every repeated dismissal request.
- Attached state retained through ordinary navigation away and back, without Router inference.

The UIKit renderer consumes the shared domain but does not reuse or depend on the SwiftUI renderer.

### Validation

- The [package-external UIKit example](../Examples/UIKit/README.md) uses only the `TideSheetUIKit` product and explicit module imports.
- All 34 package unit tests pass: 8 shared-core, 15 SwiftUI, and 11 UIKit tests. UIKit coverage includes preferred-size and real Auto Layout measurement, width-cache invalidation, coalesced selection, drag projection, weak handlers, one-shot notification, containment, appearance, and custom backdrop opacity in both contexts.
- All 10 UIKit example UI tests pass on iPhone 17 Pro Max / iOS 26.5. They cover attached push/pop and native-modal-return retention, modal presentation above underlying navigation, size and selection changes, repeated and immediate dismissal, descendant modal closure, and navigation from dismissal completion.
- Input content uses its own `keyboardLayoutGuide` while the sheet frame stays fixed. Scrolling content scrolls without changing the sheet's height.
- The deployment target is iOS 17. Minimum-version runtime, rotation, iPad, Dynamic Type, VoiceOver, Reduce Motion, interrupted gestures, and cancelled navigation remain follow-up validation. The implementation of basic accessibility and adaptation behavior is not a claim that the full matrix has passed.

See the [UIKit guide](UIKit-Bottom-Sheet.md) for the current public contract. Arbitrary navigation-stack rewrites that remove an already-offscreen retained host do not gain an immediate-detachment guarantee.

### Exit condition

A UIKit application can use modal and attached TideSheet presentation with UIKit content and the same documented domain semantics as the SwiftUI renderer.

## Next — Cross-Content Bridges

### Goal

Allow the root to keep presentation ownership regardless of content technology.

### Deliverables

- SwiftUI content hosted by `TideSheetUIKit`.
- UIKit controller-backed content hosted by `TideSheetSwiftUI`.
- Correct content measurement, safe-area propagation, appearance, replacement, and teardown.
- Bridge-specific public conveniences derived from real sample consumers.
- No renderer-to-renderer dependency and no duplicated sheet engine.

The exact public APIs should be accepted only after both bridge samples establish whether they require a `UIView`, `UIViewController`, SwiftUI builder, or another renderer-specific boundary.

### Initial system-bridge examples

- The UIKit example hosts SwiftUI through `UIHostingController`, using the existing UIKit entry points and handler. Its intrinsic body reports measured height at the actual width through `preferredContentSize`.
- The SwiftUI example hosts a controller through `UIViewControllerRepresentable`, using the existing SwiftUI entry points and environment actions. The concrete controller's preferred-height changes update an explicit SwiftUI content frame.
- Each example still depends on only its root renderer product. No new public bridge wrapper, module, or renderer-to-renderer dependency has been added.
- Focused UI scenarios cover both directions in both contexts, including height changes, content updates, navigation retention, dismissal, and reopening. The SwiftUI-root scenarios also exercise item replacement.
- September 7 validation passes: 34 package unit tests, the full 12-test SwiftUI example suite, and 2 UIKit bridge UI tests. Bridge testing also fixed modal item reconciliation and replacement after the presenting SwiftUI route moves offscreen; native SwiftUI content now has regression coverage for that same sequence.

See [Cross-Content Bridge Experiments](Cross-Content-Bridges.md) for the sizing contracts, validation evidence, and remaining API questions. These examples are the evidence-gathering portion of this milestone; they do not establish a generic bridge API or complete capability-matrix support.

### Capability matrix

Each root, content, and context combination must work while the root renderer remains the sole presentation owner:

| Root renderer | Content | Attached | Modal |
| --- | --- | --- | --- |
| SwiftUI | SwiftUI | Initial slice | Initial slice |
| SwiftUI | UIKit | System-adapter example | System-adapter example |
| UIKit | UIKit | Initial slice | Initial slice |
| UIKit | SwiftUI | System-adapter example | System-adapter example |

For every supported combination, verify:

- initial and changing content size;
- detent selection and drag settlement;
- interactive and programmatic dismissal;
- content replacement and teardown;
- appearance and safe-area propagation;
- repeated presentation without retained hosts or duplicate callbacks.

### Exit condition

All eight root/content/context combinations satisfy the published contract without moving ownership into bridged content.

## Later — SwiftUI Content Layout and Validation

The initial SwiftUI attached and modal paths are implemented. The following remain independent follow-up work:

- Flexible content layout beyond the initial fitting-content path, including explicit sizing for scroll content without adopting its gesture or scroll state.
- Detent-update, cancellation, and host-teardown validation across both contexts.
- Native safe-area propagation and content-owned input layout in representative samples.
- Rotation, compact height, Dynamic Type, VoiceOver, and Reduce Motion checks.
- Renderer-owned SwiftUI style and backdrop customization.

Validate these against both presentation contexts and preserve one-shot dismissal and content identity. This work does not introduce automatic keyboard avoidance, uniform content safe-area padding, or scroll-view gesture handoff.

## Later — Pre-1.0 Hardening

### Deliverables

- Audit public names, access control, actor isolation, and `Sendable` conformance.
- Document presentation contexts, lifecycle, detent semantics, supported scrolling, and migration behavior.
- Provide focused SwiftUI-root and UIKit-root examples.
- Add DocC documentation for the supported public surface.
- Add minimum-deployment and current-toolchain CI.
- Add accessibility, memory, repeated-presentation, and interaction regression coverage.
- Record breaking 0.x changes with migration notes.
- Add release-facing contribution, changelog, support, and security guidance.

### First release decision

Do not label placeholder targets or planned cells as supported. Choose the first tagged release only after deciding whether it is a focused SwiftUI preview or a complete capability-matrix release. The release notes and README must state that scope exactly.

### 1.0 exit condition

TideSheet reaches 1.0 only when:

- both renderer products work independently;
- both renderers support attached and modal presentation;
- native and bridged content combinations pass the supported matrix;
- shared detent, selection, interaction, and dismissal semantics are documented;
- public APIs have survived real sample usage and at least one pre-1.0 feedback cycle;
- no renderer-to-renderer dependency, hidden import, or duplicate public core type exists.

## Deferred Until Evidence Exists

- Sheet stacking, queues, replacement policy, and global hosts.
- Router, Coordinator, URL, or deep-link integration.
- Navigation-stack inference.
- Automatic keyboard avoidance, content safe-area policy, and scroll-view gesture handoff; reconsider only if a new consumer and an explicit ownership decision change the accepted boundary.
- Backward compatibility below iOS 17 or Swift 6.2.
- macOS, visionOS, or other platform support.
- System-sheet API, behavior, or appearance parity.
- Specialized third-party scrolling containers.
- State restoration across process termination.

A deferred capability enters the roadmap only when a concrete consumer establishes its required ownership and lifecycle contract.

## Unified Presentation API and Navigation Coverage

The single entry in each renderer accepts `SheetPresentation`: `.modal` by default or `.attached`. SwiftUI captures the style per presentation, retaining the original carrier during dismissal and applying changes on the next opening. Example call sites and guides use this entry without compatibility aliases.

The attached SwiftUI carrier belongs to the declaring page while covering its containing navigation area. A local UIKit adapter coordinates the rendering container and navigation visibility; the SwiftUI state, surface, content, environment, measurement, and gestures stay in `TideSheetSwiftUI`. Navigation delegates and application paths remain application-owned.

The final September 7 regression passes 35 package unit tests, 18 SwiftUI UI tests, and 12 UIKit UI tests on iPhone 17 Pro Max / iOS 26.5. Verification includes declaration from a small control, navigation-bar tap interception, bottom-edge coverage, ordinary and interactive navigation, retained content, nested native presentation, rotation, and style changes between presentations. Portrait and landscape screenshots were inspected. Minimum-version runtime and broader platform adaptation remain open.
