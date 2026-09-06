//
//  SheetSurface.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import SwiftUI
import TideSheet

struct SheetSurface<Content: View>: View {
    let detents: Set<TideSheetDetent>
    let selectedDetent: TideSheetDetent.Id
    let availableHeight: CGFloat
    let isDismissing: Bool
    let actions: SheetActions
    let onDismissed: () -> Void
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var contentHeight: CGFloat?
    @State private var isVisible = false
    @State private var hasEntered = false
    @GestureState(resetTransaction: Transaction(animation: .spring(response: 0.35, dampingFraction: 0.9)))
    private var drag: SheetDrag?

    private var animation: Animation? {
        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.9)
    }

    private var layout: TideSheetDetentLayout? {
        TideSheetDetentLayout(
            detents: detents.sorted { $0.id.rawValue < $1.id.rawValue },
            availableHeight: max(0, availableHeight),
            contentFittingSheetHeight: contentHeight,
        )
    }

    var body: some View {
        let layout = layout
        let restingHeight = layout?.restingPoint(for: selectedDetent)?.height ?? 0
        let displayedHeight = drag?.height(maximum: availableHeight) ?? restingHeight

        ZStack(alignment: .bottom) {
            Color.black.opacity(isVisible ? 0.28 : 0)
                .contentShape(Rectangle())
                .onTapGesture { actions.dismiss() }
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                Capsule()
                    .fill(.secondary.opacity(0.5))
                    .frame(width: 36, height: 5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .contentShape(Rectangle())
                    .gesture(dragGesture(layout: layout, restingHeight: restingHeight))
                    .accessibilityElement()
                    .accessibilityLabel("Resize sheet")
                    .accessibilityValue(selectedDetent.rawValue)
                    .accessibilityAdjustableAction { direction in
                        adjustSelection(direction, layout: layout)
                    }

                content()
                    .environment(\.sheet, actions)
            }
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { contentHeight = $0 }
            .frame(height: displayedHeight, alignment: .top)
            .background(.background)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
            .offset(y: isVisible ? 0 : displayedHeight)
            .opacity(layout == nil ? 0 : 1)
            .animation(animation, value: restingHeight)
            .accessibilityAction(.escape) { actions.dismiss() }
        }
        .clipped()
        .allowsHitTesting(hasEntered)
        .onChange(of: layout != nil, initial: true) { _, isReady in
            guard isReady, !hasEntered, !isDismissing else { return }
            hasEntered = true
            withAnimation(animation) { isVisible = true }
        }
        .onChange(of: isDismissing, initial: true) { _, dismissing in
            guard dismissing else { return }
            withAnimation(animation, completionCriteria: .removed) {
                isVisible = false
            } completion: {
                onDismissed()
            }
        }
        .transaction { if reduceMotion { $0.animation = nil } }
    }

    private func dragGesture(layout: TideSheetDetentLayout?, restingHeight: CGFloat) -> some Gesture {
        // The indicator moves as the sheet resizes; measure translation in a
        // stationary coordinate space so that motion does not feed back into input.
        DragGesture(minimumDistance: 4, coordinateSpace: .global)
            .updating($drag) { value, state, _ in
                if state == nil { state = SheetDrag(startingHeight: restingHeight, translation: 0) }
                state?.translation = value.translation.height
            }
            .onEnded { value in
                guard let layout else { return }
                let movement = drag ?? SheetDrag(startingHeight: restingHeight, translation: value.translation.height)
                if let id = movement.destination(
                    predictedTranslation: value.predictedEndTranslation.height,
                    layout: layout,
                    selectedDetent: selectedDetent,
                ) {
                    actions.selectDetent(id)
                } else {
                    actions.dismiss()
                }
            }
    }

    private func adjustSelection(_ direction: AccessibilityAdjustmentDirection, layout: TideSheetDetentLayout?) {
        guard let layout,
              let index = layout.restingPoints.firstIndex(where: { $0.detentIds.contains(selectedDetent) }) else { return }
        let nextIndex = direction == .increment ? index + 1 : index - 1
        guard layout.restingPoints.indices.contains(nextIndex) else { return }
        actions.selectDetent(layout.restingPoints[nextIndex].detentIds[0])
    }
}
