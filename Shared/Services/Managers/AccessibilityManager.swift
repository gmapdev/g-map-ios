//
//  AccessibilityManager.swift
//

import Foundation
import SwiftUI

class AccessibilityManager : ObservableObject{
    
    @Published var pubIsLargeFontSize = false
    
    /// Is larger text enabled
    /// Checks if larger text enabled.
    public func isLargerTextEnabled() {
        DispatchQueue.main.async {
            let contentSize = UIApplication.shared.preferredContentSizeCategory
            let accessibilitySizeEnabled = contentSize.isAccessibilityCategory
            self.pubIsLargeFontSize = accessibilitySizeEnabled
        }
    }
    
    /// Get font size
    /// - Returns: CGFloat
    /// Retrieves font size.
    public func getFontSize() -> CGFloat{
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        let preferredFontSize = fontMetrics.scaledValue(for: UIFont.preferredFont(forTextStyle: .body).pointSize)
        if preferredFontSize > 100 {
            return preferredFontSize * 0.5
        } else if preferredFontSize > 70 {
            return preferredFontSize * 0.65
        } else if preferredFontSize > 50 {
            return preferredFontSize * 0.8
        } else {
            return preferredFontSize
        }
    }
    
    /// Shared.
    /// - Parameters:
    ///   - AccessibilityManager: Parameter description
    public static var shared: AccessibilityManager = {
        let mgr = AccessibilityManager()
        return mgr
    }()
    
}

enum ContentSizeCategoryValue: Int {
    case extraSmall = 0
    case small = 1
    case medium = 2
    case large = 3
    case extraLarge = 4
    case extraExtraLarge = 5
    case extraExtraExtraLarge = 6
    case accessibilityMedium = 7
    case accessibilityLarge = 8
    case accessibilityExtraLarge = 9
    case accessibilityExtraExtraLarge = 10
    case accessibilityExtraExtraExtraLarge = 11
}

extension ContentSizeCategoryValue {
    /// _ content size category:  content size category
    /// Initializes a new instance.
    /// - Parameters:
    ///   - contentSizeCategory: ContentSizeCategory
    init(_ contentSizeCategory: ContentSizeCategory) {
        switch contentSizeCategory {
        case .extraSmall:
            self = .extraSmall
        case .small:
            self = .small
        case .medium:
            self = .medium
        case .large:
            self = .large
        case .extraLarge:
            self = .extraLarge
        case .extraExtraLarge:
            self = .extraExtraLarge
        case .extraExtraExtraLarge:
            self = .extraExtraExtraLarge
        case .accessibilityMedium:
            self = .accessibilityMedium
        case .accessibilityLarge:
            self = .accessibilityLarge
        case .accessibilityExtraLarge:
            self = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge:
            self = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge:
            self = .accessibilityExtraExtraExtraLarge
        @unknown default:
            self = .medium
        }
    }
}
