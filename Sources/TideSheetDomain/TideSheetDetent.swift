//
//  TideSheetDetent.swift
//  TideSheet
//
//  Created by weixi on 2026/8/28.
//

import Foundation

package struct TideSheetDetent: Hashable {
    package struct Id: RawRepresentable, Hashable {
        package let rawValue: String

        package init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    package enum Height: Hashable {
        case content(maximum: CGFloat? = nil)
        case fixed(CGFloat)
        case fraction(CGFloat)
        case maximum
    }

    package let id: Id
    package let height: Height

    package init(id: Id, height: Height) {
        self.id = id
        self.height = height
    }
}
