//
//  AccessibilityLegendView.swift
//

import Foundation
import SwiftUI

struct AccessibilityLegendView: View {
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ZStack{
            VStack{
                Spacer()
                HStack{
                    Spacer()
                }
            }.background(Color.black).opacity(0.43).ignoresSafeArea(edges: .all)
            .onTapGesture {
                tripPlanManager.pubShowAccessibilityLegend = false
            }
            .addAccessibility(text: AvailableAccessibilityItem.blackAreaFliter.rawValue.localized())
            .accessibilityAction {
                tripPlanManager.pubShowAccessibilityLegend = false
            }
            VStack {
                Spacer().frame(height: ScreenSize.safeTop())
                HStack {
                    Spacer()
                    Button(action: {
                        tripPlanManager.pubShowAccessibilityLegend = false
                    }, label: {
                        Image("cancel_icon")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color.gray_subtitle_color)
                            .frame(width: 22, height: 22)
                    })
                    .padding(12)
                    .background(Color.white)
                    .clipShape(Circle())
                    .addAccessibility(text: "Close button, Double tap to activate".localized())
                    Spacer().frame(width: 20)
                }
                Spacer()
            }
            VStack {
                HStack {
                    Spacer()
                    TextLabel("Accessible Routing".localized())
                    Spacer()
                }
                .addAccessibility(text: "Accessible Routing".localized())
                    VStack(alignment: .leading){
                        HStack(spacing: 5){
                            HStack {
                                Image("ic_wheelchair_black")
                                Image("ic_like")
                            }
                            .padding(5)
                            .background(Color.accessibility_green)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            TextLabel("Wheelchair accessible".localized())
                            Spacer()
                        }
                        .addAccessibility(text: "Wheelchair accessible".localized())
                        
                        HStack(spacing: 5){
                            HStack {
                                Image("ic_wheelchair_black")
                                Image("ic_help_circle")
                            }
                            .padding(5)
                            .background(Color.accessibility_blue)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            TextLabel("Wheelchair accessibility information unavailable".localized())
                            Spacer()
                        }
                        .addAccessibility(text: "Wheelchair accessibility information unavailable".localized())
                        
                        HStack(spacing: 5){
                            HStack {
                                Image("ic_wheelchair_black")
                                Image("ic_dislike")
                            }
                            .padding(5)
                            .background(Color.accessibility_red)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            TextLabel("Not wheelchair accessible".localized())
                            Spacer()
                        }
                        .addAccessibility(text: "Not wheelchair accessible".localized())
                    }
            }
            .padding()
            .background(Color.white)
            .foregroundColor(Color.primary)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding()
        }
    }
}

struct AccessibilityLegendViewAODA: View {
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        contentView()
    }
    
    /// Content view
    /// - Returns: some View
    /// Content view.
    func contentView() -> some View {
        ZStack(alignment: .center){
            VStack{
                HStack{
                    Spacer()
                }
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
            .background(Color.black.opacity(0.6))
            .zIndex(9990)
            .accessibilityAddTraits(.isButton)
            .addAccessibility(text: AvailableAccessibilityItem.blackAreaFliter.rawValue.localized())
            .accessibilityAction {
                tripPlanManager.pubShowAccessibilityLegend = false
            }
            .onTapGesture {
                tripPlanManager.pubShowAccessibilityLegend = false
            }
            VStack {
                Spacer().frame(height: ScreenSize.safeTop())
                HStack {
                    Spacer()
                    Button(action: {
                        tripPlanManager.pubShowAccessibilityLegend = false
                    }, label: {
                        Image("cancel_icon")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color.gray_subtitle_color)
                            .frame(width: 22, height: 22)
                    })
                    .padding(12)
                    .background(Color.white)
                    .clipShape(Circle())
                    .addAccessibility(text: "Close button, Double tap to activate".localized())
                    Spacer().frame(width: 20)
                }
                Spacer()
            }.zIndex(9998)
            VStack {
                Spacer().frame(height: 60)
                ScrollView {
                    HStack {
                        Spacer()
                        TextLabel("Accessible Routing".localized())
                        Spacer()
                    }
                    HStack {
                        VStack(alignment: .leading){
                            VStack(alignment: .leading, spacing: 5){
                                HStack {
                                    Image("ic_wheelchair_black")
                                    Image("ic_like")
                                }
                                .padding(5)
                                .background(Color.accessibility_green)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                
                                TextLabel("Wheelchair accessible".localized())
                            }
                            
                            VStack(alignment: .leading, spacing: 5){
                                HStack {
                                    Image("ic_wheelchair_black")
                                    Image("ic_help_circle")
                                }
                                .padding(5)
                                .background(Color.accessibility_blue)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                
                                TextLabel("Wheelchair accessibility information unavailable".localized())
                            }
                            
                            VStack(alignment: .leading, spacing: 5){
                                HStack {
                                    Image("ic_wheelchair_black")
                                    Image("ic_dislike")
                                }
                                .padding(5)
                                .background(Color.accessibility_red)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                
                                TextLabel("Not wheelchair accessible".localized())
                            }
                        }
                        Spacer()
                    }
                }
                .padding()
                .frame(height: ScreenSize.height() - (ScreenSize.safeTop() + ScreenSize.safeBottom() + 200))
                .background(Color.white)
                .foregroundColor(Color.primary)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding()
            }
            .zIndex(9999)
        }
        
    }
}
