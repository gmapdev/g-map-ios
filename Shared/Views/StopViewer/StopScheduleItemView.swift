//
//  StopScheduleItemView.swift
//

import SwiftUI

struct StopScheduleItem: Identifiable {
    let id = UUID()
    let leftText: String
    let middleText: String
    let rightText: String
}

struct StopScheduleItemView: View {
    let item: StopScheduleItem
    let isMiddleTextBold = false
    let index: Int
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack {
            if AccessibilityManager.shared.pubIsLargeFontSize {
                itemViewAODA
                HorizontalLine(color: Color.gray)
            } else {
                itemView
            }
        }
    }
    
    /// Item view.
    /// - Parameters:
    ///   - some: Parameter description
    var itemView: some View {
        HStack {
            TextLabel(item.leftText).frame(width: 50, alignment: .leading).font(.subheadline)
                .foregroundColor(.gray).padding(.trailing, 10)
            TextLabel(item.middleText).font(.subheadline)
                .foregroundColor(.gray).frame(alignment: .leading).multilineTextAlignment(.leading)
            Spacer()
            TextLabel(item.rightText).frame(width: 85, alignment: .leading).font(.subheadline)
                .foregroundColor(.gray)
            
        }.padding(.vertical, 5).addAccessibility(text: "Route: %1, Destination: %2, Departure time: %3".localized(item.leftText, item.middleText, item.rightText))
    }
    
    /// Item view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var itemViewAODA: some View {
        HStack {
            VStack(alignment: .leading){
                TextLabel(item.leftText)
                    .font(.subheadline)
                    .foregroundColor(.gray).padding(.trailing, 10)
                TextLabel(item.middleText).font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                TextLabel(item.rightText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
            }
            Spacer()
        }
        .padding(.vertical, 5).addAccessibility(text: "Route: %1, Destination: %2, Departure time: %3".localized(item.leftText, item.middleText, item.rightText))
    }
}

extension StopScheduleItemView {
    static var mockScheduleItem = StopScheduleItem(leftText: "Route", middleText: "Destination", rightText: "Departure")
}

struct StopScheduleItemView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        StopScheduleItemView(item: StopScheduleItemView.mockScheduleItem, index: 0)
    }
}
