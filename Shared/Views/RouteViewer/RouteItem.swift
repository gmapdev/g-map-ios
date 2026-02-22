//
//  RouteItem.swift
//

import SwiftUI

struct RouteItem: Identifiable {
    let id = UUID().uuidString
    let route: TransitRoute
    var isSelected: Bool = false
}

