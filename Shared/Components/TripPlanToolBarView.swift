//
//  TripPlanToolBarView.swift
//

import SwiftUI

struct TripPlanToolBarView: View {
	
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    @State var isPresentedPicker = false
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        
        VStack(spacing: 0){
            if SearchManager.shared.userCriterias.accessibleRouting ?? false {
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    HStack{
                        Button(action: {
                            tripPlanManager.pubShowAccessibilityLegend.toggle()
                        }, label: {
                            HStack(spacing: 5){
                                Image(systemName: "info.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                
                                Image("ic_wheelchair_black")
                                    .resizable()
                                    .renderingMode(.template)
                                    .frame(width: 30, height: 30)
                            }.foregroundColor(Color.white)
                            
                        })
                        Spacer()
                    }
                    .padding(.bottom, 10)
                }
            }
            HStack{
                if !AccessibilityManager.shared.pubIsLargeFontSize {
                    if SearchManager.shared.userCriterias.accessibleRouting ?? false {
                        Button(action: {
                            TripPlanningManager.shared.pubShowAccessibilityLegend.toggle()
                        }, label: {
                            HStack(spacing: 5){
                                Image(systemName: "info.circle.fill")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                
                                Image("ic_wheelchair_black")
                                    .resizable()
                                    .renderingMode(.template)
                                    .frame(width: 25, height: 25)
                            }.foregroundColor(Color.white)

                        })
                    }
                    Spacer()
                }
                Button(action: {
                    isPresentedPicker.toggle()
                }) {
                    HStack {
                        TextLabel(tripPlanManager.pubSortOption.rawValue.localized(), .bold, .headline)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 2)
                            .foregroundColor(Color.white)
                        if AccessibilityManager.shared.pubIsLargeFontSize {
                            Image("ic_down")
                                .renderingMode(.template)
                                .resizable()
                                .foregroundColor(Color.white)
                                .frame(width: 40, height: 40)
                        } else {
                            Image("ic_decending")
                                .frame(width: 20, height: 20)
                        }
                    }
                    .frame(minHeight: 30)
                }
                .addAccessibility(text: "Sort by %1, Double Tap to Change Sort Order".localized(tripPlanManager.pubSortOption.rawValue.localized()))
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    Spacer()
                }
            }.frame(minHeight: 30)
        }
        .frame(minHeight: 30)
        .sheet(isPresented: $isPresentedPicker){
            MultiPickerView(selectedOption: $tripPlanManager.pubSortOption)
        }
    }
}

enum SortOption: String {
    case bestOption = "Best Option"
    case duration = "Duration"
    case arrivalTime = "Arrival Time"
    case departureTime = "Departure Time"
    case walkTime = "Walk Time"
    case cost = "Cost"
}

struct MultipleSelectionRow: View {
    var item: SortOption
    var isSelected  = false
    var action: () -> Void
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        Button(action:
                
                self.action
        ) {
            HStack {
                TextLabel(self.item.rawValue.localized())
                    .font(.body)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }.foregroundColor(Color.black)
        }
    }
}

struct MultiPickerView: View {
    @Binding var selectedOption : SortOption
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    @Environment(\.presentationMode) var presentationMode
    var selectionList: [SortOption] = [.bestOption, .duration, .arrivalTime, .departureTime, .walkTime]
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ZStack{
            VStack{
                List {
                    ForEach(0..<self.selectionList.count, id: \.self) { index in
                        MultipleSelectionRow(item: self.selectionList[index],isSelected: selectedOption == selectionList[index]) {
                            if selectedOption != selectionList[index] {
                                selectedOption = selectionList[index]
                                presentationMode.wrappedValue.dismiss()
                            } }
                    }
                }
            }
            VStack{
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    HStack{
                        Spacer()
                        TextLabel("Close".localized())
                        Spacer()
                    }
                    .foregroundColor(Color.white)
                    .padding()
                    .background(Color.main)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                })
                .padding()
            }
        }
    }
}



