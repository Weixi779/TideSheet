# TideSheet Roadmap

> Status: Working plan
>
> Last updated: September 6, 2026

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

The core tests cover detent resolution. Initial native SwiftUI attached and modal slices are implemented below. The UIKit renderer remains a placeholder, and no cross-content API is implemented yet.

### Verified baseline

- Core layout tests pass on an iOS Simulator.
- Both renderer products build from package-external consumers using explicit imports.
- The Package manifest and formatting checks pass.

## Done — Initial Native SwiftUI Attached Slice

### Goal

Prove the shared model through a native SwiftUI implementation whose lifetime belongs to an explicit SwiftUI root or subtree.

### Deliverables

- `attachedSheet` overloads for Boolean/item presentation and internal/external selection.
- A `Set` of detents with an explicit initial ID or selected-ID binding.
- A host-attached overlay implemented entirely inside `TideSheetSwiftUI`.
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
- The [package-external SwiftUI example](../Examples/AttachedSheet/README.md) uses only the `TideSheetSwiftUI` product and explicit imports.
- UI tests on iPhone 17 Pro Max / iOS 26.5 exercise all four overloads, height-policy selection, external binding writes, repeated show/dismiss, content and host resizing, dragging, interactive dismissal, item updates, and navigation away/back with retained state.
- Builds use the iOS 17 deployment target. Runtime checks on iOS 17, gesture interruption during an active drag, root-versus-route comparison, and the full accessibility/adaptation matrix remain follow-up validation.

See the [SwiftUI API guide](SwiftUI-Attached-Sheet.md) for the current public contract and limitations. Vertically flexible content, including unbounded scroll views, is not yet measured and filled as a general-purpose sheet body.

### Not in this slice

- independent modal presentation;
- UIKit content;
- scroll-view handoff;
- multiple concurrent sheets, stacking, or queues;
- Router or `NavigationStack` orchestration;
- exhaustive keyboard, accessibility, or platform-adaptation behavior.

### Exit condition

A pure SwiftUI application can attach, resize, drag, select, and dismiss a SwiftUI sheet without importing or executing the UIKit renderer.

## Done — Initial Native SwiftUI Modal Slice

### Deliverables

- `bottomSheet` overloads with the same Boolean/item presentation and internal/external selection choices as `attachedSheet`.
- A SwiftUI `fullScreenCover` carrier with a transparent background and independent presentation scope.
- Reuse of the attached implementation's state, content identity, detent resolution, surface, and indicator interaction.
- TideSheet-owned surface animation, with the carrier opening and closing without an additional transition for ordinary TideSheet actions.
- Surface dismissal, carrier removal, and one-shot `onDismiss` in that order; item replacement waits for carrier completion.
- Reconciliation when content invokes SwiftUI's system `dismiss` action directly.
- Initial safe-area geometry: the backdrop reaches the container edges, the maximum surface avoids the top safe area, and fitting measurement includes bottom content padding.

### Validation

- All 23 core and renderer unit tests pass after sharing the presentation state between contexts.
- All 10 example UI tests pass on iPhone 17 Pro Max / iOS 26.5, including the existing attached scenarios.
- Modal scenarios cover all four overloads, full-width presentation from a small button, selection through actions and bindings, drag dismissal, repeated presentation, same-ID updates, replacement, external closure, and system dismissal.
- Navigation scenarios verify that a modal remains above an underlying push with content state intact, and that navigation from `onDismiss` occurs after closure. Captured screenshots confirm transparent backdrop coverage and the separate modal scope.
- The deployment target remains iOS 17; this runtime validation covers portrait iPhone on iOS 26.5. Minimum-version, rotation, keyboard, iPad, accessibility, and arbitrary host-removal checks remain follow-up work.

See the [modal guide](SwiftUI-Bottom-Sheet.md) for the supported lifecycle and current limits. This slice retains the attached surface's intrinsic-content measurement path.

## Next — Complete the SwiftUI Presentation Contract

### Goal

Make `TideSheetSwiftUI` coherent across attached and independent modal presentation.

### Deliverables

- Extend detent-update, cancellation, and host-teardown validation across both contexts.
- Flexible content layout and scroll content measurement beyond the initial fitting-content path.
- Scroll handoff for documented SwiftUI scrolling content.
- Keyboard and safe-area adaptation.
- Dynamic Type, VoiceOver, Reduce Motion, and compact-height behavior.
- Renderer-owned SwiftUI style and backdrop customization.

The initial modal carrier is implemented and verified above. The next work extends content layout and interaction without moving presentation ownership out of SwiftUI.

### Validation

- Run one behavior matrix against attached and modal contexts.
- Exercise scroll content away from the top, at the top, and during interactive dismissal.
- Exercise keyboard, rotation, compact height, Dynamic Type, Reduce Motion, and VoiceOver scenarios.
- Verify cancellation and teardown do not retain content or emit duplicate callbacks.

### Exit condition

A pure SwiftUI application can choose attached or modal presentation while observing one documented detent, selection, interaction, and dismissal contract.

## Later — Native UIKit Renderer

### Goal

Implement the accepted domain semantics with UIKit-native presentation and containment.

### Deliverables

- One UIKit-owned sheet surface and interaction implementation.
- UIKit modal presentation.
- UIKit host-attached presentation with correct view-controller containment.
- Native UIKit content only.
- Programmatic selection, dragging, settling, and interactive dismissal.
- `UIScrollView` handoff for a documented primary scrolling model.
- Safe-area, keyboard, rotation, and container-size handling.
- Renderer-owned UIKit styling and backdrop customization, with UIKit types confined to `TideSheetUIKit`.
- Defined Dynamic Type, VoiceOver, Reduce Motion, and accessibility-dismissal behavior.
- One-shot dismissal and reentrant-safe teardown.
- Explicit attached-host ownership without Router inference.

The UIKit renderer consumes the shared domain but does not reuse or depend on the SwiftUI renderer.

### Validation

- A package-external UIKit sample using only the `TideSheetUIKit` product and explicit module imports.
- The common detent and lifecycle matrix for UIKit modal and attached contexts.
- View-controller appearance, containment, repeated presentation, and teardown checks.
- Ordinary navigation away and back while an attached host remains owned.
- Representative `UIScrollView` handoff scenarios.
- Styling, custom backdrop, Dynamic Type, VoiceOver, and Reduce Motion scenarios.

### Exit condition

A UIKit application can use modal and attached TideSheet presentation with UIKit content and the same documented domain semantics as the SwiftUI renderer.

## Later — Cross-Content Bridges

### Goal

Allow the root to keep presentation ownership regardless of content technology.

### Deliverables

- SwiftUI content hosted by `TideSheetUIKit`.
- UIKit controller-backed content hosted by `TideSheetSwiftUI`.
- Correct content measurement, safe-area propagation, appearance, replacement, and teardown.
- Bridge-specific public conveniences derived from real sample consumers.
- No renderer-to-renderer dependency and no duplicated sheet engine.

The exact public APIs should be accepted only after both bridge samples establish whether they require a `UIView`, `UIViewController`, SwiftUI builder, or another renderer-specific boundary.

### Capability matrix

Each root, content, and context combination must work while the root renderer remains the sole presentation owner:

| Root renderer | Content | Attached | Modal |
| --- | --- | --- | --- |
| SwiftUI | SwiftUI | Initial slice | Initial slice |
| SwiftUI | UIKit | Planned | Planned |
| UIKit | UIKit | Planned | Planned |
| UIKit | SwiftUI | Planned | Planned |

For every supported combination, verify:

- initial and changing content size;
- detent selection and drag settlement;
- interactive and programmatic dismissal;
- content replacement and teardown;
- appearance and safe-area propagation;
- repeated presentation without retained hosts or duplicate callbacks.

### Exit condition

All eight root/content/context combinations satisfy the published contract without moving ownership into bridged content.

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
- Backward compatibility below iOS 17 or Swift 6.2.
- macOS, visionOS, or other platform support.
- System-sheet API, behavior, or appearance parity.
- Specialized third-party scrolling containers.
- State restoration across process termination.

A deferred capability enters the roadmap only when a concrete consumer establishes its required ownership and lifecycle contract.
