//
//  SheetPresentation.swift
//  TideSheet
//
//  Created by weixi on 2026/9/7.
//

/// The relationship between a sheet and the page that opens it.
public enum SheetPresentation: Equatable, Sendable {
    /// An independent modal remains above navigation in the presenting page.
    case modal

    /// The sheet leaves with its page during navigation and returns with its state intact.
    case attached
}
