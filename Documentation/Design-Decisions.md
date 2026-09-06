# TideSheet Design Decisions

> Status: Living baseline
>
> Last updated: September 6, 2026

This document records decisions that define TideSheet's direction. It describes accepted boundaries, not implementation order or current feature availability. See the [roadmap](Roadmap.md) for delivery status.

An implementation idea does not become a decision merely because it appears in the roadmap. Unresolved contracts remain listed under **Open Decisions**.

## Terminology

- **Root**: The UIKit or SwiftUI hierarchy that owns presentation.
- **Renderer**: The root-specific module that turns shared sheet values into hierarchy, layout, animation, interaction, and lifecycle behavior.
- **Content**: Application-owned UIKit or SwiftUI UI displayed inside a sheet.
- **Modal**: A sheet with an independent presentation scope.
- **Attached**: A sheet composed into and owned by an explicit host hierarchy.
- **Detent**: A logical sheet position declared by the application.
- **Resting point**: A concrete physical height resolved from one or more detents.

## Confirmed Decisions

### 1. Product Position

TideSheet is an application-independent, open-source bottom-sheet library for iOS. It is designed to provide a library-controlled sheet surface for UIKit-rooted and SwiftUI-rooted applications.

TideSheet is not a thin wrapper around `UISheetPresentationController` or SwiftUI `.sheet`. System sheets remain the right choice when an application wants system-owned presentation, appearance, and interaction. TideSheet exists for applications that need a custom and controllable surface, including applications that do not want their sheet design to change with the system sheet.

TideSheet is a personal open-source project. It must remain application-independent and must not expose application-specific APIs, business concepts, or compatibility behavior.

### 2. Platform Baseline

TideSheet requires:

- iOS 17 or later
- Swift 6.2 or later
- Xcode 26 or later

This modern baseline is deliberate. The project may use current Swift language, concurrency, Observation, and SwiftUI capabilities directly. It will not add compatibility layers solely to support older deployment targets or toolchains.

### 3. Module and Product Boundary

The package has one canonical shared module and two root-specific renderer modules:

```text
                    TideSheet
          shared public values and rules
                  /           \
        TideSheetUIKit   TideSheetSwiftUI
          UIKit root       SwiftUI root
```

- `TideSheet` owns renderer-independent public values and shared rules.
- `TideSheetUIKit` owns presentation in a UIKit root.
- `TideSheetSwiftUI` owns presentation in a SwiftUI root.

The package exposes two renderer products:

- `TideSheetUIKit`, containing the `TideSheet` and `TideSheetUIKit` modules
- `TideSheetSwiftUI`, containing the `TideSheet` and `TideSheetSwiftUI` modules

There is no standalone `TideSheet` product until a real domain-only consumer requires one.

Client source imports the canonical module and its renderer explicitly:

```swift
import TideSheet
import TideSheetUIKit
```

or:

```swift
import TideSheet
import TideSheetSwiftUI
```

TideSheet will not use duplicate public wrappers, public `typealias` declarations, `@_exported import`, or an umbrella module to obscure ownership.

The renderer targets are isolated to `MainActor`. The shared `TideSheet` target is not globally main-actor isolated.

### 4. The Root Selects the Renderer

The root technology determines the renderer. The content technology does not.

| Root owner | Renderer | Native content | Bridged content |
| --- | --- | --- | --- |
| UIKit | `TideSheetUIKit` | UIKit | SwiftUI |
| SwiftUI | `TideSheetSwiftUI` | SwiftUI | UIKit |

A UIKit root does not switch to the SwiftUI renderer merely because its sheet content is SwiftUI. A SwiftUI root does not move its presentation topology into UIKit merely because its content is UIKit.

Foreign content is adapted at the selected renderer boundary. A bridge must not duplicate the sheet engine or move presentation ownership into the content framework. The exact public bridge APIs remain open.

### 5. Each Root Keeps Its Native Presentation Model

The renderers share domain semantics, but they do not share a single presentation implementation.

For a UIKit root:

- modal presentation follows UIKit presentation ownership;
- attached presentation belongs to an explicit UIKit host hierarchy;
- SwiftUI content is hosted inside the UIKit renderer.

For a SwiftUI root:

- SwiftUI content remains a native `View`;
- attached presentation is native SwiftUI composition, such as an overlay owned by the chosen host;
- UIKit containment and `UIViewController` presentation are not imposed on the native SwiftUI path;
- UIKit content is adapted at the SwiftUI renderer boundary.

The goal is shared, documented semantics with framework-native mechanics—not identical internal code or pixel-for-pixel execution.

### 6. Modal and Attached Are Different Ownership Contexts

Modal and attached are presentation contexts, not separate detent engines.

A modal sheet establishes an independent presentation scope. It is presented and dismissed as its own presentation rather than belonging to the underlying route's view hierarchy.

An attached sheet is composed into an explicit host hierarchy and shares that host's ownership. Its effective scope is determined by where the application installs it:

- installing it on route content can make it route-scoped;
- installing it on a navigation or application root can make it root-scoped.

TideSheet does not infer that scope from a Router or navigation stack. Both contexts reuse the same public configuration and domain semantics where their host frameworks allow it.

### 7. Presentation Ownership Stays Outside the Shared Domain

| Layer | Responsibility |
| --- | --- |
| Application, Router, or Coordinator | Why and when to show a sheet, which host owns it, and what navigation follows |
| Renderer | Hosting, hierarchy, geometry, animation, gestures, dismissal, and lifecycle |
| `TideSheet` | Shared values and renderer-independent resolution rules |
| Sheet content | Business UI, state, and user actions |

TideSheet must not choose a global presenter, search for a top-most screen, parse URLs, resolve routes, or decide whether a business action should push or present another screen.

A Router or Coordinator may invoke a TideSheet renderer, but TideSheet does not depend on routing. It also does not alter UIKit's modal hierarchy to make a navigation controller beneath a presented sheet push content above that sheet. Applications needing a surviving sheet and independent navigation should choose an attached host scope or establish another application-owned presentation flow.

### 8. Content Is Application-Owned

TideSheet controls the sheet boundary: outer geometry, surface, presentation, interaction, and lifecycle. The application owns the content hierarchy and business behavior inside that boundary.

Supporting UIKit and SwiftUI content from either root is a product direction. The exact public content units—such as `UIView`, `UIViewController`, SwiftUI builders, or renderer-specific wrappers—remain open until the native renderers and bridge samples establish their ownership requirements.

Platform UI types do not enter the shared module. `UIView`, `UIViewController`, `UIColor`, SwiftUI `View`, and SwiftUI `Color` remain renderer concerns.

### 9. Detent Domain Contract

`TideSheetDetent` is the canonical public detent declaration. Its public identifier spelling is `Id`, not `ID`.

Each detent has a stable logical `Id` and one height policy:

```swift
.content(maximum: CGFloat?)
.fixed(CGFloat)
.fraction(CGFloat)
.maximum
```

The shared contract is:

- resolved heights describe the complete outer sheet height;
- the renderer supplies a normalized `availableHeight`;
- content measurement describes the complete content-fitting sheet height, including sheet chrome;
- fixed detents do not require content measurement;
- content detents remain unresolved until a positive content measurement is available;
- resolved heights are clamped to the available height;
- detent identifiers are unique;
- invalid, non-finite, or non-positive declarations fail explicitly.

Logical identity is distinct from physical height. Multiple detents may temporarily resolve to one physical resting point. Their logical identifiers remain preserved so they can separate again when content or container measurements change.

`TideSheetDetentLayout` and `RestingPoint` are package implementation, not public API. `RestingPoint` is the canonical internal term for a resolved physical position.

### 10. Pre-1.0 Compatibility

TideSheet is under active development, and public API may change before 1.0.

This freedom permits deliberate API correction. It does not justify ambiguous ownership, hidden imports, compatibility aliases, or premature exposure of renderer internals.

### 11. SwiftUI Attachment and Selection

The native SwiftUI entry point is `attachedSheet`, with separate `isPresented: Binding<Bool>` and `item: Binding<Item?>` overloads. Item content requires `Identifiable`, without an additional `Equatable` requirement.

Detents are configured as a `Set<TideSheetDetent>`. IDs must still be unique: value equality in a set does not enforce identifier uniqueness. Physical drag order is resolved from measured heights; set iteration order has no presentation meaning.

There are two mutually exclusive selection modes:

- `initialDetent: TideSheetDetent.Id`: the sheet owns current selection and initializes it once per new presentation.
- `selectedDetent: Binding<TideSheetDetent.Id>`: the caller owns selection, including its initial value. Environment actions and drag settlement write back to that same binding.

Ordinary content updates, layout changes, and navigation away and back do not reapply an initial detent. Logical selection survives temporarily coalesced heights.

Sheet content uses the custom `@Environment(\.sheet)` value to call `dismiss()` or `selectDetent(_:)`. Actions belong to one presentation and become inert when it ends. They do not control navigation or locate another presenter. Native SwiftUI content measurement does not require a public invalidation action.

The initial attached implementation's dismissal, input-validation, item-update, and measurement behavior is documented in the [SwiftUI API guide](SwiftUI-Attached-Sheet.md). These defaults do not establish a modal, keyboard, styling, or scrolling contract for later work.

## Explicit Non-Goals

TideSheet is not:

- a Router, Coordinator, deep-link system, or URL dispatcher;
- a navigation-stack abstraction;
- a global presenter or top-most-view-controller finder;
- an application-wide overlay queue or arbitrary surface orchestration framework;
- an application-specific compatibility package;
- a system-sheet backend, skin, or polyfill;
- an exact replica of every system-sheet behavior;
- a UIKit implementation disguised as a native SwiftUI API;
- a back-deployment library for iOS versions before iOS 17;
- a public general-purpose geometry engine.

## Open Decisions

The following are not yet public contracts:

- concrete UIKit presentation and attachment entry points;
- the SwiftUI modal entry point and carrier;
- the accepted UIKit content unit and both cross-content bridge APIs;
- shared selection and lifecycle behavior beyond the initial SwiftUI attachment contract;
- UIKit handler APIs for dismissal, invalidation, and lifecycle callbacks;
- drag thresholds, velocity rules, cancellation, and animation curves;
- scroll-view handoff behavior;
- keyboard, safe-area, rotation, compact-height, iPad, and multi-scene policy;
- renderer-specific styling for corner radius, grabber, dimming, backgrounds, and custom content;
- accessibility focus, dismissal, announcement, Reduce Motion, and Dynamic Type contracts;
- multiple attached sheets, stacking, replacement, and teardown ordering;
- lifecycle notification for an externally retained, offscreen host removed by an arbitrary navigation-stack rewrite;
- example structure, visual regression strategy, release versioning, and support policy.

Open decisions may appear in the roadmap as work to investigate or deliver. They must not be documented as supported behavior until their contract is accepted and verified.
