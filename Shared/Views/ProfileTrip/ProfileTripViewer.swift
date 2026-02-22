//
//  ProfileTripViewer.swift
//

import SwiftUI

struct ProfileTripViewer: View {
	@ObservedObject var profileManager = ProfileManager.shared
	
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack(spacing: 0){
			if profileManager.pubShowTripList {
				Spacer().frame(height:20)
				TripListViewer()
			}else{
				TripManageViewer()
			}
		}
    }
}

struct ProfileTripViewer_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        ProfileTripViewer()
    }
}
