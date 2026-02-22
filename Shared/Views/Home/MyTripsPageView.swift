//
//  MyTripsPageView.swift
//

import SwiftUI

/// My Trips page view that displays the user's saved trips.
/// This view is shown when the My Trips tab is selected.
struct MyTripsPageView: View {
	var body: some View {
		MyTripViewer()
			.edgesIgnoringSafeArea(.all)
	}
}
