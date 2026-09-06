//
//  AttachedSheetApp.swift
//  TideSheet
//
//  Created by weixi on 2026/9/6.
//

import SwiftUI
import TideSheet
import TideSheetSwiftUI

@main
struct AttachedSheetApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    NavigationLink("Internal selection", value: "internal")
                    NavigationLink("External selection", value: "external")
                    NavigationLink("Item and initial selection", value: "itemInitial")
                    NavigationLink("Item and external selection", value: "itemExternal")
                }
                .navigationTitle("TideSheet")
                .navigationDestination(for: String.self) { mode in
                    if mode == "detail" {
                        Text("An independent route")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.background)
                            .navigationTitle("Next page")
                    } else {
                        AttachedSheetExample(mode: mode)
                    }
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
            host.attachedSheet(isPresented: $isPresented, detents: ExampleDetents.all, selectedDetent: $selection, onDismiss: didDismiss) {
                sheetContent(title: "External selection")
            }
        case "itemInitial":
            host.attachedSheet(item: $item, detents: ExampleDetents.all, initialDetent: ExampleDetents.compact.id, onDismiss: didDismiss) {
                sheetContent(title: $0.title)
            }
        case "itemExternal":
            host.attachedSheet(item: $item, detents: ExampleDetents.all, selectedDetent: $selection, onDismiss: didDismiss) {
                sheetContent(title: $0.title)
            }
        default:
            host.attachedSheet(isPresented: $isPresented, detents: ExampleDetents.all, initialDetent: ExampleDetents.compact.id, onDismiss: didDismiss) {
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
                Button("Resize host") { compactHost.toggle() }
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
