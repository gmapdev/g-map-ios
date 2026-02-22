//
//  Array+Extension.swift
//

import Foundation

extension Array where Element: Comparable {
    /// Is same elements.
    /// - Parameters:
    ///   - from: Parameter description
    /// - Returns: Bool
    /// Checks if same elements.
    func isSameElements(from array: [Element]) -> Bool {
        return count == array.count && sorted() == array.sorted()
    }
}

// Utility extension to safely access array elements by index
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
