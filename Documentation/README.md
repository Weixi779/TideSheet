# TideSheet Documentation

TideSheet's unified API, initial renderers, and two runnable example apps are implemented. The first tagged release is still pending. Read [Release Readiness](Release-Readiness.md) for the current evidence and remaining delivery work.

## Reading Order

| Document | Purpose |
| --- | --- |
| [Design Decisions](Design-Decisions.md) | Accepted product, ownership, module, and content boundaries; unresolved proposals stay separate. |
| [SwiftUI Bottom Sheet](SwiftUI-Bottom-Sheet.md) | The unified SwiftUI API, presentation relationships, selection, and modal lifetime. |
| [SwiftUI Attached Sheet](SwiftUI-Attached-Sheet.md) | Page ownership, navigation coverage, retained state, and the local rendering carrier. |
| [UIKit Bottom Sheet](UIKit-Bottom-Sheet.md) | The unified UIKit entry, explicit host, handler, sizing, and dismissal contract. |
| [Cross-Content Bridge Experiments](Cross-Content-Bridges.md) | What the two system-adapter examples establish, their sizing choices, and why a dedicated bridge API remains a candidate. |
| [Roadmap](Roadmap.md) | Completed implementation milestones, the next release phase, and later or deferred capabilities. |
| [Release Readiness](Release-Readiness.md) | A dated release audit, recommended preview scope, validation gaps, and release exit checks. |

Run the [two example apps](../Examples/README.md) alongside the API guides. Their source and UI scenarios make the behavior reviewable: use **Choose presentation** in the SwiftUI app to compare `.modal` and `.attached` with the same content.

## Decisions, Evidence, and Future Writing

The API guides describe the current contract. The decision record explains accepted boundaries. The bridge document records an experiment, and the roadmap schedules work; neither automatically creates a new public requirement.

The main implementation lesson from the navigation-mask fix is that page ownership and rendering area are separate concerns. A small declaration can own a sheet covering its navigation container. Temporary navigation away preserves an attached presentation rather than dismissing it; independent modal presentation stays above the underlying navigation. The two renderers express this relationship through one shared value while retaining their own lifecycle mechanisms.

A later experience article can develop these findings and the project's earlier research into a narrative. That article is a separate writing deliverable, not a dependency of the first package release.
