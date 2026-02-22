//
//  TripPlanDetailView.swift
//

import SwiftUI

struct TripPlanDetailView: View {
    @ObservedObject var loginFlowManager = LoginFlowManager.shared
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    let sortOption: SortOption
    var backAction: (() -> Void)? = nil
    var stopViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    var tripViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    var tripManageViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    var signInAction: (() -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        
        VStack {
            if let item = tripPlanManager.pubSelectedItinerary,
			   let entry = tripPlanManager.pubSelectedGroupEntry {
                VStack(spacing: 0){
                    itemView(entry, item, sortOption: sortOption).padding(0)
                }
                .background(Color.white)
                .padding(.top, 0)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
			if let itinerary = tripPlanManager.pubSelectedItinerary {
                showFavourite(itinerary, sortOption: sortOption)
            }
        }
    }
    
 /// Item view.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - sortOption: Parameter description
 /// - Returns: TripPlanItemView
	private func itemView(_ entry: GroupEntry, _ item: OTPItinerary, sortOption: SortOption) -> TripPlanItemView {
		var itemView = TripPlanItemView(sortOption: sortOption, entry: entry, isOther: false, isFull: true)
        
        itemView.stopViewerAction = { itinerary, leg in
            stopViewerAction?(itinerary, leg)
        }
        
        itemView.tripViewerAction = { itinerary, leg in
            tripViewerAction?(itinerary, leg)
        }
        
        itemView.isExpandedDirection = true
        return itemView
            
    }
    
    /// Show favourite.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - sortOption: Parameter description
    func showFavourite(_ itinerary: OTPItinerary, sortOption: SortOption){
		var hasTransit = false
		var hasRentalOrRideHail = false
		if let legs = itinerary.legs {
			for leg in legs {
				if let transitLeg = leg.transitLeg, transitLeg {
					hasTransit = transitLeg
				}
                // Explictly allowing Car/Walk and Bike trips to saved.
                else if let mode = leg.searchMode?.mode, mode == Mode.bicycle.rawValue || mode == Mode.car.rawValue || mode == Mode.walk.rawValue {
                    hasTransit = true
                }
                else if let mode = leg.searchMode?.mode, mode == Mode.bicycle.rawValue {
					if leg.rentedBike ?? false {
						hasRentalOrRideHail = true
					}
				}
			}
		}
		if hasTransit && !hasRentalOrRideHail {
			tripPlanManager.pubSaveTripText = "Save Trip"
		}else{
			tripPlanManager.pubSaveTripText = "Cannot Save"
		}
    }
}

