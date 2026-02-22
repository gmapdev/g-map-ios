//
//  CheckBoxView.swift
//

import SwiftUI

struct CheckBoxView: View {
    @State var isChecked: Bool
    var title: String
    var icon: String
    var checboxSize: CGFloat
    var action: (() -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        HStack {
            Button(action: {
                isChecked.toggle()
                action?()
            }, label: {
                HStack {
                    Image(systemName: isChecked ?"checkmark.square" : "square")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: checboxSize, height: checboxSize)
                        .foregroundStyle(Color.black)
                    if !icon.isEmpty {
                    Spacer().frame(width: 10)
                        HStack {
                            Image(icon)
                                .renderingMode(.template)
                                .resizable()
                                .foregroundStyle(Color.white)
                                .frame(width: getModeIconWidth(title: title), height: getModeIconHeight(title: title))
                        }
                        .frame(width: checboxSize, height: checboxSize)
                        .background(Color.black)
                        .clipShape(Circle())
                        Spacer().frame(width: 10)
                    }
                    TextLabel(title.localized())
                        .lineLimit(nil)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                }
                .foregroundStyle(Color.black)
            })
            Spacer()
        }
    }
    // hardcoded width based on different mode icons
    /// Retrieves mode icon width.
    /// - Parameters:
    ///   - title: String
    /// - Returns: CGFloat
    func getModeIconWidth(title: String) -> CGFloat {
        if AccessibilityManager.shared.pubIsLargeFontSize {
            let baseSize = AccessibilityManager.shared.getFontSize() / 2
            switch title {
            case "Bus":
                return baseSize - 10
            case "Link Light Rail":
                return baseSize - 12
            case "Ferry":
                return baseSize - 10
            case "Sounder":
                return baseSize - 12
            case "Streetcar":
                return baseSize - 12
            case "Water Taxi":
                return baseSize - 10
            case "Monorail":
                return baseSize - 12
            default:
                return baseSize - 8
            }
        } else {
            switch title {
            case "Bus":
                return 12
            case "Link Light Rail":
                return 10
            case "Ferry":
                return 12
            case "Sounder":
                return 10
            case "Streetcar":
                return 10
            case "Water Taxi":
                return 12
            case "Monorail":
                return 10
            default:
                return 15
            }
        }
        
    }
    // hardcoded height based on different mode icons
    /// Retrieves mode icon height.
    /// - Parameters:
    ///   - title: String
    /// - Returns: CGFloat
    func getModeIconHeight(title: String) -> CGFloat {
        if AccessibilityManager.shared.pubIsLargeFontSize {
            let baseSize = AccessibilityManager.shared.getFontSize() / 2
            switch title {
            case "Bus":
                return baseSize - 10
            case "Link Light Rail":
                return baseSize - 12
            case "Ferry":
                return baseSize - 10
            case "Sounder":
                return baseSize - 12
            case "Streetcar":
                return baseSize - 12
            case "Water Taxi":
                return baseSize - 10
            case "Monorail":
                return baseSize - 12
            default:
                return baseSize - 8
            }
        } else {
            switch title {
            case "Bus":
                return 12
            case "Link Light Rail":
                return 12
            case "Ferry":
                return 10
            case "Sounder":
                return 12
            case "Streetcar":
                return 12
            case "Water Taxi":
                return 10
            case "Monorail":
                return 12
            default:
                return 15
            }
        }
    }
}
