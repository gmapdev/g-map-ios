//
//  TripSearchSettingsItemView.swift
//

import SwiftUI

struct TripSearchSettingsItemView: View {
	var item: TripSearchSettingsItem
    var action: ((TripSearchSettingsItem) -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack {
            if AccessibilityManager.shared.pubIsLargeFontSize {
                VStack(alignment: .leading, spacing: 5){
                    TextLabel(item.titleText.localized(), .bold, .subheadline)
                        .foregroundColor(Color.black)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    selectValueButton
                }
                .padding(.bottom, 5)
            } else {
                HStack {
                    TextLabel(item.titleText.localized(), .bold, .subheadline)
                        .foregroundColor(Color.black)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    selectValueButton
                }
                .padding(.bottom, 5)
            }
        }
    }
    
    /// Text
    /// - Returns: String
    /// Text.
    private func text() -> String {
		let string =  item.defaultValue
		switch item.item {
        case .walkMax: return string.maxWalkDisplayString
        case .walkSpeed: return string.walkSpeedDisplayString
        case .optimize: return string
        }
    }
    
    /// Select value button.
    /// - Parameters:
    ///   - some: Parameter description
    private var selectValueButton: some View {
            Button(action: {
				action?(item)
            }) {
                HStack {
                    TextLabel(text().localized())
                        .font(.subheadline)
                        .foregroundColor(Color.black)
                    if AccessibilityManager.shared.pubIsLargeFontSize {
                        Spacer()
                    }
                    Image(systemName: "arrowtriangle.down.fill")
                        .renderingMode(.template)
                        .resizable()
                        .padding(.horizontal, 5)
                        .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 20, height: AccessibilityManager.shared.pubIsLargeFontSize ? 20 : 10)
                        .foregroundColor(Color.java_main)
                }
                .padding(10)
                .roundedBorderWithColor(10, 0, Color.java_main,1)
                
            }
    }
}

