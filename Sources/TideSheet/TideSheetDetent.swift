//
//  TideSheetDetent.swift
//  TideSheet
//
//  Created by weixi on 2026/8/28.
//

import Foundation

public struct TideSheetDetent: Hashable, Sendable {
    public struct Id: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public enum Height: Hashable, Sendable {
        case content(maximum: CGFloat? = nil)
        case fixed(CGFloat)
        case fraction(CGFloat)
        case maximum
    }

    public let id: Id
    public let height: Height

    public init(id: Id, height: Height) {
        self.id = id
        self.height = height
    }
}
