//
//  TripDetailInfoViewAODA.swift
//

import SwiftUI

struct TripDetailInfoViewAODA: View {
    @ObservedObject var fareTableViewModel = FareTableManager.shared
    let dateText: String
    let timeText: String
    let costText: String
    let walkTimeText: String
    let walkDuration: String
    let bikeDuration: String
    let imageSize: CGFloat
    @State private var isCalories = false
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        HStack() {
            VStack(alignment: .leading) {
                TextLabel("Trip Details".localized(),.bold, .body)
                    .foregroundColor(.black)
                HStack(alignment: .top) {
                    VStack {
                        Image("calendar_icon")
                            .resizable()
                            .frame(width: imageSize, height: imageSize)
                            .accessibilityHidden(true)
                        Spacer()
                    }
                    (Text("Depart ".localized())
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
                        .foregroundColor(.black))
                        .fixedSize(horizontal: false, vertical: true)
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
            (TextLabel("By taking this trip, you'll spend %1 walking and %2 biking.".localized(walkDuration, bikeDuration)).font(.subheadline))
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
