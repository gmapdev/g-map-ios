//
//  RouteViewerItemView.swift
//

import SwiftUI
import Combine

struct RouteViewerItem: Identifiable {
    let id = UUID()
    let leftText: String
    let middleText: String
    let rightText: String
}

struct RouteViewerItemView: View {
    let item: RouteViewerItem
    let isMiddleTextBold = false
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack {
            HStack {
                HStack {
                    boldTextView(item.leftText)
                        .frame(width: 70, alignment: .leading)
                    isMiddleTextBold ? boldTextView(item.middleText) : textView(item.middleText)
                    Spacer()
                    boldTextView(item.rightText)
                }
            }
            Divider().background(Color.black)
        }.padding(.horizontal, 10)
        
    }
    
    /// Text view.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: Text
    private func textView(_ text: String) -> Text {
        return Text(text).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.footnote.size)).foregroundColor(.black)
    }
    
    /// Bold text view.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: Text
    private func boldTextView(_ text: String) -> Text {
        return textView(text).font(Font.custom(CustomFontWeight.bold.fontName, size: CustomFontStyle.footnote.size))
    }
}

extension RouteViewerItemView {
    static var mockScheduleItem = RouteViewerItem(leftText: "Route", middleText: "To", rightText: "Departure")
}

struct RouteViewerItemView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        RouteViewerItemView(item: RouteViewerItemView.mockScheduleItem)
    }
}

extension TransitRoute {
    /// Title.
    /// - Parameters:
    ///   - String: Parameter description
    var title: String {
        if let lName = longName{
            return lName
        }
        else if let sName = shortName{
            return "Route \(sName)"
        }
        return longName ?? ""
    }
    
    /// Bus route number.
    /// - Parameters:
    ///   - String: Parameter description
    var busRouteNumber: String{
        if let shortName = shortName{
            return shortName
        }
        return "N/A"
    }
    
    /// Title color.
    /// - Parameters:
    ///   - Color: Parameter description
    var titleColor: Color {
        guard let textColor = self.textColor else {
			if let bgColorHex = color {
				return Helper.shared.getContrastColor(hexColor: bgColorHex)
			}
            return Color.white
        }
		if let bgColorHex = color, textColor == bgColorHex {
			return Helper.shared.getContrastColor(hexColor: bgColorHex)
		}
        /// Hex: text color
        /// Initializes a new instance.
        /// - Parameters:
        ///   - hex: textColor
        return Color.init(hex: textColor)
    }
    
    /// Title backgound color.
    /// - Parameters:
    ///   - Color: Parameter description
    var titleBackgoundColor: Color {
        guard let color = color else {
            return Color(hex: "70757A")
        }
        /// Hex: color
        /// Initializes a new instance.
        /// - Parameters:
        ///   - hex: color
        return Color.init(hex: color)
    }
}
