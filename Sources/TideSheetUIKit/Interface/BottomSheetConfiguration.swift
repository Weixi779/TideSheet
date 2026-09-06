//
//  BottomSheetConfiguration.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import TideSheet
import UIKit

/// A single presentation's detents, appearance, and dismissal options.
public struct BottomSheetConfiguration {
    public let detents: Set<TideSheetDetent>
    public let initialDetent: TideSheetDetent.Id
    public let surfaceColor: UIColor
    public let grabberColor: UIColor
    public let dimmingBackground: BottomSheetDimmingBackground
    public let cornerRadius: CGFloat
    /// Space reserved above content for the indicator; zero permits underlapping it.
    public let contentTopInset: CGFloat
    public let dismissesOnDimmingViewTap: Bool
    /// Disables downward dismissal without disabling detent changes.
    public let dismissesOnSwipe: Bool

    public init(
        detents: Set<TideSheetDetent>,
        initialDetent: TideSheetDetent.Id,
        surfaceColor: UIColor = .systemBackground,
        grabberColor: UIColor = .secondaryLabel,
        dimmingBackground: BottomSheetDimmingBackground = .color(.black.withAlphaComponent(0.28)),
        cornerRadius: CGFloat = 20,
        contentTopInset: CGFloat = 28,
        dismissesOnDimmingViewTap: Bool = true,
        dismissesOnSwipe: Bool = true,
    ) {
        _ = TideSheetDetentLayout(detents: Array(detents), availableHeight: 0)
        precondition(detents.contains { $0.id == initialDetent }, "The initial detent must exist in detents.")
        precondition(cornerRadius.isFinite && cornerRadius >= 0, "Corner radius must be finite and nonnegative.")
        precondition(contentTopInset.isFinite && contentTopInset >= 0, "Content top inset must be finite and nonnegative.")
        self.detents = detents
        self.initialDetent = initialDetent
        self.surfaceColor = surfaceColor
        self.grabberColor = grabberColor
        self.dimmingBackground = dimmingBackground
        self.cornerRadius = cornerRadius
        self.contentTopInset = contentTopInset
        self.dismissesOnDimmingViewTap = dismissesOnDimmingViewTap
        self.dismissesOnSwipe = dismissesOnSwipe
    }
}

public enum BottomSheetDimmingBackground {
    /// The renderer animates this color's view opacity with presentation and dragging.
    case color(UIColor)
    /// Creates fresh background content. Its opacity and animations remain caller-owned.
    /// The returned view must not already belong to a hierarchy.
    case custom(@MainActor () -> UIView)
}
