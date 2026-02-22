//
//  AppTheme.swift
//

import SwiftUI

// MARK:- App colors
extension UIColor {
    static let main = UIColor(named: "main_color")!
    static let second = UIColor(named: "second_color")!
    static let shadow = UIColor(named: "shadow_color")!
    static let java_main = UIColor(named: "java_main")!
    static let gray_main = UIColor(named: "gray_color")!
    static let gray_subtitle_color = UIColor(named: "gray_subtitle_color")!
    static let yellow_main = UIColor(named: "yellow_color")!
    static let text_header = UIColor(named: "text_header_color")!
    static let green_main = UIColor(named: "green_color")!
    static let toolbar_action = UIColor(named: "toolbar_action_color")!
    static let navigationTitle = UIColor.white
    static let navigationLargeTitle = UIColor.white
    static let blueBackground = UIColor(named: "blue_background_color")!
    static let blueForeground = UIColor(named: "blue_foreground_color")!
    static let redBackground = UIColor(named: "red_background_color")!
    static let redForeground = UIColor(named: "red_foreground_color")!
    static let polylineOverlay = UIColor(named: "ployline_overlay_color")!
    static let toggleOff = UIColor(named: "toggle_off_color")!
    static let badgeColor = UIColor(named: "badge_color")!
    static let accessibility_green = UIColor(named: "accessibility_green")!
    static let accessibility_blue = UIColor(named: "accessibility_blue")!
    static let accessibility_red = UIColor(named: "accessibility_red")!
}

extension Color {
    static let main = Color(.main)
    static let second = Color(.second)
    static let shadow = Color(.shadow)
    static let java_main = Color(.java_main)
    static let gray_main = Color(.gray_main)
    static let gray_subtitle_color = Color(.gray_subtitle_color)
    static let yellow_main = Color(.yellow_main)
    static let green_main = Color(.green_main)
    static let navigationTitle = Color(.navigationTitle)
    static let navigationLargeTitle = Color(.navigationLargeTitle)
    static let text_header = Color(.text_header)
    static let toolbar_action = Color(.toolbar_action)
    static let blueBackground = Color(.blueBackground)
    static let blueForeground = Color(.blueForeground)
    static let redBackground = Color(.redBackground)
    static let redForeground = Color(.redForeground)
    static let toggleOffColor = Color(.toggleOff)
    static let badgeColor = Color(.badgeColor)
    static let accessibility_green = Color(.accessibility_green)
    static let accessibility_blue = Color(.accessibility_blue)
    static let accessibility_red = Color(.accessibility_red)
}

enum CustomFontStyle{
    case largeTitle
    case title
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption
    case caption2
    case caption3

    /// Size.
    /// - Parameters:
    ///   - CGFloat: Parameter description
    var size: CGFloat {
        switch self {
        case .largeTitle:
            return 30
        case .title:
            return 28
        case .title2:
            return 22
        case .title3:
            return 20
        case .headline:
            return 18
        case .body:
            return 17
        case .callout:
            return 16
        case .subheadline:
            return 15
        case .footnote:
            return 13
        case .caption:
            return 12
        case .caption2:
            return 11
        case .caption3:
            return 10
        }
    }
}

enum CustomFontWeight {
    case black
    case blackItalic
    case bold
    case boldItalic
    case italic
    case light
    case lightItalic
    case semibold
    case semiboldItalic
    case regular
    case thin
    case thinItalic
    
    /// Font name.
    /// - Parameters:
    ///   - String: Parameter description
    var fontName: String {
        switch self {
        case .black:
            return "Roboto-Black"
        case .blackItalic:
            return "Roboto-BlackItalic"
        case .bold:
            return "Roboto-Bold"
        case .boldItalic:
            return "Roboto-BoldItalic"
        case .italic:
            return "Roboto-Italic"
        case .light:
            return "Roboto-Light"
        case .lightItalic:
            return "Roboto-LightItalic"
        case .semibold:
            return "Roboto-Medium"
        case .semiboldItalic:
            return "Roboto-MediumItalic"
        case .regular:
            return "Roboto-Regular"
        case .thin:
            return "Roboto-Thin"
        case .thinItalic:
            return "Roboto-ThinItalic"
        }
    }
}

// MARK: - Custom Text View to update fonts
struct TextLabel: View {
    let text : String
    let weight: CustomFontWeight
    let style: CustomFontStyle
    
    /// _ text:  string, _ weight:  custom font weight = .regular, _ style:  custom font style = .body
    /// Initializes a new instance.
    /// - Parameters:
    ///   - text: String
    ///   - weight: CustomFontWeight = .regular
    ///   - style: CustomFontStyle = .body
    init(_ text: String, _ weight: CustomFontWeight = .regular, _ style: CustomFontStyle = .body) {
        self.text = text
        self.weight = weight
        self.style = style
    }
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        return Text(text).font(Font.custom(weight.fontName, size: style.size))
    }
}


// MARK:- Navigation
extension UINavigationBarAppearance {
    /// Default appearance.
    /// - Parameters:
    ///   - UINavigationBarAppearance: Parameter description
    static var defaultAppearance: UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.main
        appearance.titleTextAttributes = [.foregroundColor: UIColor.navigationTitle]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.navigationLargeTitle]
        return appearance
    }
}
// MARK:- Dismiss Keyboard
extension UIApplication {
      /// Dismiss keyboard
      /// Dismisses keyboard.
      func dismissKeyboard() {
          UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
      }
  }
