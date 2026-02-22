//
//  TripDetailInfoView.swift
//

import SwiftUI

struct TripDetailInfoView: View {
    
    @ObservedObject var fareTableViewModel = FareTableManager.shared
    let dateText: String
    let timeText: String
    let costText: String
    let walkTimeText: String
    let walkDuration: String
    let bikeDuration: String
    @State private var isCalories = false
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        HStack() {
            VStack(alignment: .leading) {
                Text("Trip Details".localized())
                    .font(Font.custom(CustomFontWeight.bold.fontName, size: CustomFontStyle.body.size))
                    .foregroundColor(.black)
                HStack(alignment: .center) {
                    Image("calendar_icon")
                        .resizable()
                        .frame(width: 20, height: 20)
						.accessibilityHidden(true)
                    Text("Depart ".localized())
                        .font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.subheadline.size))
                        .foregroundColor(.black)
                    + Text(dateText)
                        .font(Font.custom(CustomFontWeight.bold.fontName, size: CustomFontStyle.subheadline.size))
                        .foregroundColor(.black)
                    + Text(" at ".localized())
                        .font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.subheadline.size))
                        .foregroundColor(.black)
                    + Text(timeText)
                        .font(Font.custom(CustomFontWeight.bold.fontName, size: CustomFontStyle.subheadline.size))
                        .foregroundColor(.black)
                }
            }
        }
        .padding()
        .background(Color.white)
    }
    
    /// Calories info view.
    /// - Parameters:
    ///   - some: Parameter description
    private var caloriesInfoView: some View {
        HStack {
            (Text("By taking this trip, you'll spend".localized())+Text(" \(walkDuration) ").bold()+Text("walking and ".localized())+Text("\(bikeDuration) ").bold() + Text("biking".localized()))
            .fixedSize(horizontal: false, vertical: true)
            VStack{
            Button(action: {
                isCalories.toggle()
            }) {
                Image("cancel_icon")
                    .resizable()
                    .frame(width: 15, height: 15)
            }
            .addAccessibility(text: "Close button, double tap to close calorise calculation description".localized())
                Spacer()
            }
        }
    .roundedBorder()
    .background(Color.white)
        
    }
}
