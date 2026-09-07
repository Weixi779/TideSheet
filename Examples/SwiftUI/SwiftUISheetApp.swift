//
//  SwiftUISheetApp.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import SwiftUI
import TideSheet
import TideSheetSwiftUI

@main
struct SwiftUISheetApp: App {
    var body: some Scene {
        WindowGroup { SheetCatalog() }
    }
}

private struct SheetCatalog: View {
    @State private var path: [String] = []
    @State private var endedSheets = 0

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("Presentation") {
                    NavigationLink("Choose presentation", value: "presentation")
                    Text("Ended sheets: \(endedSheets)")
                }
                Section("Attached") {
                    NavigationLink("Internal selection", value: "internal")
                    NavigationLink("External selection", value: "external")
                    NavigationLink("Item and initial selection", value: "itemInitial")
                    NavigationLink("Item and external selection", value: "itemExternal")
                }
                Section("Modal") {
                    NavigationLink("Modal internal selection", value: "modalInternal")
                    NavigationLink("Modal external selection", value: "modalExternal")
                    NavigationLink("Modal item and initial selection", value: "modalItemInitial")
                    NavigationLink("Modal item and external selection", value: "modalItemExternal")
                }
                Section("UIKit content") {
                    NavigationLink("UIKit content · Attached", value: "uikitAttached")
                    NavigationLink("UIKit content · Modal", value: "uikitModal")
                }
            }
            .navigationTitle("TideSheet")
            .navigationDestination(for: String.self) { mode in
                if mode == "presentation" {
                    PresentationExample(onNavigate: { path.append("detail") }, onEnded: { endedSheets += 1 })
                } else if mode == "detail" {
                    Text("An independent route")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.background)
                        .navigationTitle("Next page")
                } else if mode.hasPrefix("uikit") {
                    UIKitContentExample(isAttached: mode == "uikitAttached", onNavigate: { path.append("detail") })
                } else if mode.hasPrefix("modal") {
                    ModalSheetExample(mode: mode, onNavigate: { path.append("detail") })
                } else {
                    AttachedSheetExample(mode: mode)
                }
            }
        }
    }
}

private enum ExampleDetents {
    static let compact = TideSheetDetent(id: .init(rawValue: "compact"), height: .fixed(440))
    static let content = TideSheetDetent(id: .init(rawValue: "content"), height: .content())
    static let half = TideSheetDetent(id: .init(rawValue: "half"), height: .fraction(0.5))
    static let maximum = TideSheetDetent(id: .init(rawValue: "maximum"), height: .maximum)
    static let all: Set<TideSheetDetent> = [compact, content, half, maximum]
}

private struct ExampleItem: Identifiable {
    let id: Int
    var title: String
}

private struct AttachedSheetExample: View {
    let mode: String
    @State private var isPresented = false
    @State private var item: ExampleItem?
    @State private var selection = ExampleDetents.compact.id
    @State private var dismissals = 0
    @State private var compactHost = false

    var body: some View {
        attachment
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .navigationTitle("Attached Sheet")
            .navigationBarTitleDisplayMode(.inline)
    }

    private var host: some View {
        VStack(spacing: 20) {
            Text("The sheet belongs to this page.")
            Text("Dismissals: \(dismissals)")
            Button("Open sheet") {
                if mode.hasPrefix("item") {
                    item = ExampleItem(id: 1, title: "Item 1")
                } else {
                    isPresented = true
                }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: compactHost ? 430 : nil)
        .frame(maxHeight: compactHost ? nil : .infinity)
        .background(.blue.opacity(0.06))
    }

    @ViewBuilder
    private var attachment: some View {
        switch mode {
        case "external":
            host.bottomSheet(isPresented: $isPresented, presentation: .attached, detents: ExampleDetents.all, selectedDetent: $selection, onDismiss: didDismiss) {
                sheetContent(title: "External selection")
            }
        case "itemInitial":
            host.bottomSheet(item: $item, presentation: .attached, detents: ExampleDetents.all, initialDetent: ExampleDetents.compact.id, onDismiss: didDismiss) {
                sheetContent(title: $0.title)
            }
        case "itemExternal":
            host.bottomSheet(item: $item, presentation: .attached, detents: ExampleDetents.all, selectedDetent: $selection, onDismiss: didDismiss) {
                sheetContent(title: $0.title)
            }
        default:
            host.bottomSheet(isPresented: $isPresented, presentation: .attached, detents: ExampleDetents.all, initialDetent: ExampleDetents.compact.id, onDismiss: didDismiss) {
                sheetContent(title: "Internal selection")
            }
        }
    }

    private func didDismiss() {
        dismissals += 1
    }

    private func sheetContent(title: String) -> some View {
        ExampleSheetContent(
            title: title,
            selection: $selection,
            compactHost: $compactHost,
            isExternallySelected: mode == "external" || mode == "itemExternal",
            updateItem: mode.hasPrefix("item") ? { item?.title = "Updated item" } : nil,
            replaceItem: mode.hasPrefix("item") ? { item = ExampleItem(id: 2, title: "Item 2") } : nil,
        )
    }
}

private struct ExampleSheetContent: View {
    let title: String
    @Binding var selection: TideSheetDetent.Id
    @Binding var compactHost: Bool
    let isExternallySelected: Bool
    let updateItem: (() -> Void)?
    let replaceItem: (() -> Void)?

    @Environment(\.sheet) private var sheet
    @State private var count = 0
    @State private var moreContent = false

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button("Close") { sheet.dismiss() }
            }
            HStack {
                Button("Fixed") { sheet.selectDetent(ExampleDetents.compact.id) }
                Button("Content") { sheet.selectDetent(ExampleDetents.content.id) }
                Button("Half") { sheet.selectDetent(ExampleDetents.half.id) }
                Button("Maximum") { sheet.selectDetent(ExampleDetents.maximum.id) }
            }
            Button("Count \(count)") { count += 1 }
            HStack {
                Button("Resize content") { moreContent.toggle() }
                Button("Resize source") { compactHost.toggle() }
            }
            if moreContent {
                Text("Extra content changes the fitting height automatically.")
                    .frame(height: 90)
            }
            if isExternallySelected {
                Text("Selection: \(selection.rawValue)")
                Button("Select half through binding") { selection = ExampleDetents.half.id }
            }
            if let updateItem, let replaceItem {
                HStack {
                    Button("Update item", action: updateItem)
                    Button("Replace item", action: replaceItem)
                }
            }
            NavigationLink("Push next page", value: "detail")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .buttonStyle(.bordered)
    }
}

private struct ModalSheetExample: View {
    let mode: String
    let onNavigate: () -> Void
    @State private var isPresented = false
    @State private var item: ExampleItem?
    @State private var selection = ExampleDetents.compact.id
    @State private var dismissals = 0
    @State private var navigateAfterDismissal = false

    private var detents: Set<TideSheetDetent> {
        [.init(id: ExampleDetents.compact.id, height: .fixed(520)), ExampleDetents.content, ExampleDetents.half, ExampleDetents.maximum]
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("A modal opened from a small button.")
            Text("Dismissals: \(dismissals)")
            presentationTrigger
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.orange.opacity(0.08))
        .navigationTitle("Modal Sheet")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var trigger: some View {
        Button("Open modal") {
            if mode.contains("Item") {
                item = ExampleItem(id: 1, title: "Modal item 1")
            } else {
                isPresented = true
            }
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder
    private var presentationTrigger: some View {
        switch mode {
        case "modalExternal":
            trigger.bottomSheet(isPresented: $isPresented, detents: detents, selectedDetent: $selection, onDismiss: didDismiss) {
                content(title: "Modal external selection")
            }
        case "modalItemInitial":
            trigger.bottomSheet(item: $item, detents: detents, initialDetent: ExampleDetents.compact.id, onDismiss: didDismiss) {
                content(title: $0.title)
            }
        case "modalItemExternal":
            trigger.bottomSheet(item: $item, detents: detents, selectedDetent: $selection, onDismiss: didDismiss) {
                content(title: $0.title)
            }
        default:
            trigger.bottomSheet(isPresented: $isPresented, detents: detents, initialDetent: ExampleDetents.compact.id, onDismiss: didDismiss) {
                content(title: "Modal internal selection")
            }
        }
    }

    private func didDismiss() {
        dismissals += 1
        if navigateAfterDismissal {
            navigateAfterDismissal = false
            onNavigate()
        }
    }

    private func content(title: String) -> some View {
        ModalExampleContent(
            title: title,
            selection: $selection,
            isExternallySelected: mode == "modalExternal" || mode == "modalItemExternal",
            updateItem: mode.contains("Item") ? { item?.title = "Updated modal item" } : nil,
            replaceItem: mode.contains("Item") ? { item = ExampleItem(id: 2, title: "Modal item 2") } : nil,
            dismissExternally: { isPresented = false; item = nil },
            onNavigate: onNavigate,
            prepareNavigation: { navigateAfterDismissal = true },
        )
    }
}

private struct ModalExampleContent: View {
    let title: String
    @Binding var selection: TideSheetDetent.Id
    let isExternallySelected: Bool
    let updateItem: (() -> Void)?
    let replaceItem: (() -> Void)?
    let dismissExternally: () -> Void
    let onNavigate: () -> Void
    let prepareNavigation: () -> Void
    @Environment(\.sheet) private var sheet
    @Environment(\.dismiss) private var systemDismiss
    @State private var count = 0

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button("Close modal") { sheet.dismiss() }
            }
            HStack {
                Button("Fixed") { sheet.selectDetent(ExampleDetents.compact.id) }
                Button("Content") { sheet.selectDetent(ExampleDetents.content.id) }
                Button("Half") { sheet.selectDetent(ExampleDetents.half.id) }
                Button("Maximum") { sheet.selectDetent(ExampleDetents.maximum.id) }
            }
            Button("Count \(count)") { count += 1 }
            if isExternallySelected {
                Text("Selection: \(selection.rawValue)")
                Button("Select half through binding") { selection = ExampleDetents.half.id }
            }
            if let updateItem, let replaceItem {
                HStack {
                    Button("Update modal item", action: updateItem)
                    Button("Replace modal item", action: replaceItem)
                }
            }
            Button("Push behind modal", action: onNavigate)
            HStack {
                Button("Close externally", action: dismissExternally)
                Button("System dismiss") { systemDismiss() }
            }
            Button("Close then navigate") {
                prepareNavigation()
                sheet.dismiss()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .buttonStyle(.bordered)
    }
}

private struct PresentationExample: View {
    let onNavigate: () -> Void
    let onEnded: () -> Void
    @State private var isPresented = false
    @State private var presentation: SheetPresentation = .attached
    @State private var dismissals = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Dismissals: \(dismissals)")
            Text("Next: \(presentation == .attached ? "attached" : "modal")")
            Button("Open chosen sheet") { isPresented = true }
                .buttonStyle(.borderedProminent)
                .bottomSheet(
                    isPresented: $isPresented,
                    presentation: presentation,
                    detents: ExampleDetents.all,
                    initialDetent: ExampleDetents.compact.id,
                    onDismiss: { dismissals += 1; onEnded() },
                ) {
                    PresentationContent(presentation: $presentation, onNavigate: onNavigate)
                }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.blue.opacity(0.06))
        .navigationTitle("Presentation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PresentationContent: View {
    @Binding var presentation: SheetPresentation
    let onNavigate: () -> Void
    @Environment(\.sheet) private var sheet
    @Environment(\.dismiss) private var dismissPage
    @State private var count = 0
    @State private var showsNativeSheet = false

    var body: some View {
        VStack(spacing: 14) {
            Text("One API, two relationships").font(.headline)
            Button("Count \(count)") { count += 1 }
            Button("Maximum") { sheet.selectDetent(ExampleDetents.maximum.id) }
            Button("Change next presentation") {
                presentation = presentation == .attached ? .modal : .attached
            }
            Text("Next: \(presentation == .attached ? "attached" : "modal")")
            Button("Push next page", action: onNavigate)
            HStack {
                Button("Leave declaring page") { dismissPage() }
                Button("Native sheet") { showsNativeSheet = true }
            }
            Button("Close chosen sheet") { sheet.dismiss() }
        }
        .padding()
        .buttonStyle(.bordered)
        .sheet(isPresented: $showsNativeSheet) {
            Button("Close native sheet") { showsNativeSheet = false }
        }
    }
}
