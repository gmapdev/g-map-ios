//
//  TransportsView.swift
//

import SwiftUI

struct TransportsView: View {
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    var modeManager = ModeManager.shared
	var itinerary: OTPItinerary

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        let validLeg = walkDistanceCheck(itinerary: itinerary)
        return VStack{
            VFlow(alignment: .leading,spacing: 5){
                ForEach(validLeg.indices, id: \.self) { index in
                    HStack{
                        if consectiveModeCheck(index: index, in: validLeg){
                            VStack{
                                Image(modeManager.getImageIconforSearchRoute(leg: validLeg[index]))
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(3)
                                    .foregroundColor(Color.white)
                                    .addAccessibility(text: "%1".localized(validLeg[index].mode ?? ""))
                            }
                            .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize() : 40, height: AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize() : 40)
                            .background(Color.black)
                            .cornerRadius(5)
                        }
                        let routeName = getRouteName(leg: validLeg[index])
                        if routeName != ""{
                            VStack(spacing: 0){
                                VStack(spacing: 0){
                                    HStack{Spacer()}
                                    Spacer()
                                }.padding(.horizontal, 5)
                                    .frame(minWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName), maxWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName))
                                .frame(height: 10).background(Color(hex: tripPlanManager.getRouteColor(leg: validLeg[index]))).opacity(1)
                                
                                HStack{
                                    Spacer()
                                    TextLabel(routeName).font(.subheadline).foregroundColor(Color.black)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                }
                                .padding(.horizontal, 5)
                                .frame(minWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName), maxWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName), minHeight: 30)
                                .frame(minHeight: tripPlanManager.getRouteBannerHeight(routeName: routeName))
                                .background(Color(hex: tripPlanManager.getRouteColor(leg: validLeg[index])).opacity(0.5))
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        
                        if !(index == validLeg.count - 1) {
                            VStack(alignment: .center){
                                Spacer()
                                HStack{
                                    Circle()
                                        .fill(.gray).opacity(0.7)
                                        .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? 20 : 10, height: AccessibilityManager.shared.pubIsLargeFontSize ? 20 : 10)
                                        .addAccessibility(text: "to".localized())
                                }
                                Spacer()
                            }.frame(height: 40)
                        }
                    }
                }
            }
        }
    }
    
    /// Get route name.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: String
    func getRouteName(leg: OTPLeg) -> String {
        var routeName = tripPlanManager.getRouteShortName(leg: leg)
        if routeName == ""{
            routeName = tripPlanManager.getRouteLongName(leg: leg)
        }
        return routeName
    }
    
    /// Walk distance check.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// - Returns: [OTPLeg]
    func walkDistanceCheck(itinerary: OTPItinerary) -> [OTPLeg]{
        var tripLegs = [OTPLeg]()
        if let legs = itinerary.legs{
            for leg in legs{
                if leg.searchMode?.mode != "WALK" || leg.distance ?? 0 > 400{           //display walk mode only if distance is greater than 400
                    tripLegs.append(leg)
                }
            }
        }
        return tripLegs
    }

    /// Consective mode check.
    /// - Parameters:
    ///   - index: Parameter description
    ///   - in: Parameter description
    /// - Returns: Bool
    func consectiveModeCheck(index: Int, in legs: [OTPLeg]) -> Bool{
        if index == 0 {
            return true
        }
        else if legs[index - 1].searchMode?.mode == legs[index].searchMode?.mode {
            return false
        }

        return true
    }
}
