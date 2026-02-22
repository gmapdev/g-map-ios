//
//  UIConfig.swift
//

import Foundation
import SwiftUI

struct UIConfig: Codable {
    let navigationBar: NavigationConfig
}

struct NavigationConfig: Codable {
    let height: CGFloat
}
