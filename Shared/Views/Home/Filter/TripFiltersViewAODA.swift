//
//  TripFiltersViewAODA.swift
//

import Foundation
import SwiftUI


struct TripFiltersViewAODA: View {
    @ObservedObject var model = TripFiltersModel()
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    
    var columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
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
                MapFromToViewModel.shared.pubIsTripFiltersViewExpanded.toggle()
            }
            .onTapGesture {
                MapFromToViewModel.shared.pubIsTripFiltersViewExpanded.toggle()
            }
            VStack {
                Spacer().frame(height: ScreenSize.safeTop())
                HStack {
                    Spacer()
                    Button(action: {
                        MapFromToViewModel.shared.pubIsTripFiltersViewExpanded = false
                    }, label: {
                        Image("cancel_icon")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color.gray_subtitle_color)
                            .frame(width: 25, height: 25)
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
                    Spacer().frame(height: 20)
                    VStack(spacing:0){
                        ForEach(model.topItems.indices, id: \.self){ index in
                            FilterButtonViewAODA(width: (ScreenSize.width()-90)/3, data: model.topItems[index], isSelected: self.tripPlanManager.pubModeFilterCollection.contains(where: { $0 == model.topItems[index]}), action:{
                                if self.tripPlanManager.pubModeFilterCollection.contains(where: { $0 == model.topItems[index]}) {
                                    self.tripPlanManager.pubModeFilterCollection.removeAll(where: { $0 == model.topItems[index] })
                                } else {
                                    self.tripPlanManager.pubModeFilterCollection.append(model.topItems[index])
                                }
                            })
                            .accessibilityAddTraits(.isButton)
                        }
                        .padding(.vertical)
                    }
                }
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

struct FilterButtonViewAODA: View{
    @ObservedObject var model = TripTransitFiltersViewModel.shared
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    
    let width: CGFloat
    let data: SearchMode
    var isSelected = false
    var action: (() -> Void)? = nil
    @State var isOpen = false
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View{
        VStack {
            HStack(spacing: 10){
                HStack {
                    Spacer().frame(width: 20)
                    Button(action: {
                        action?()
                    }, label: {
                        ZStack{
                            if isSelected{
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: width - 40)
                            }
                            Image(data.mode_image)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: width - 60, height: width - 60)
                                .padding()
                                .foregroundColor(Color.black)
                        }
                        .cornerRadius(5)
                        .roundedBorderWithColor(5, 0, Color.java_main,2)
                        .background(isSelected ? Color.java_main : Color.clear)
                        
                        TextLabel(data.label.localized(),.bold)
                    })
                }
                .addAccessibility(text: isSelected ? "%1 mode on, double tap to turn off".localized(data.label) : "%1 mode off, double tap to turn on".localized(data.label) )
                .accessibilityAction {
                    action?()
                }
                Spacer()
            }
        }
    }
}
