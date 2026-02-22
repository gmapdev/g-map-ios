//
//  CheckmarkStyles.swift
//

import SwiftUI

struct CheckMarkCircleToggleStyle: ToggleStyle {
    let label: String
    
    /// Make body.
    /// - Parameters:
    ///   - configuration: Parameter description
    /// - Returns: some View
    func makeBody(configuration: Self.Configuration) -> some View {
        VStack(alignment: .leading) {
            Button(action: { configuration.isOn.toggle() }) {
                VStack(spacing: 0){
                    TextLabel(label.localized(), .semibold)
                        .font(.footnote)
                        .foregroundColor(Color.white)
                    if configuration.isOn{
                        HorizontalLine(color: Color.white).padding([.leading,.trailing], 10)
                    }
                }
            }
            .frame(height: 40).frame(minWidth: 90, maxWidth: 200, maxHeight: 40)
        }
    }
}

struct CheckMarkSquareToggleStyle: ToggleStyle {
    let label: String
    let icon: String
    /// Make body.
    /// - Parameters:
    ///   - configuration: Parameter description
    /// - Returns: some View
    func makeBody(configuration: Self.Configuration) -> some View {
        VStack {
            Button(action: { configuration.isOn.toggle() }) {
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    HStack{
                        Image(icon)
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.white)
                            .padding(.leading, 5)
                        TextLabel(label.localized(), .semibold)
                            .font(.footnote)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Color.white)
                            /// Initializes a new instance.
                            /// - Parameters:
                            ///   - minWidth: 60

                            ///   - maxWidth: .infinity
                            .frame(minWidth: 60, maxWidth: .infinity)
                    }
                } else {
                    VStack{
                        Image(icon)
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(Color.white)
                        TextLabel(label.localized(), .semibold)
                            .font(.footnote)
                            .foregroundColor(Color.white)
                            /// Initializes a new instance.
                            /// - Parameters:
                            ///   - minWidth: 60

                            ///   - maxWidth: .infinity
                            .frame(minWidth: 60, maxWidth: .infinity)
                        
                    }
                }
            }
        }
        .padding(4)
        .background(Color.main)
        .frame(height: 100).frame(minWidth: 100, maxHeight: 100)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: configuration.isOn ? 2 : 0)
        )
    }
}
