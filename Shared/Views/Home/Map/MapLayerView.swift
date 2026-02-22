//
//  MapLayerView.swift
//

import Foundation
import SwiftUI

struct mapLayerView: View{
    @ObservedObject var mapManager = MapManager.shared
    @ObservedObject var routeViewer = RouteViewerModel.shared
    @ObservedObject var stopViewer = StopViewerViewModel.shared
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack{
            Button(action: {
                withAnimation {
                    mapManager.isMapSettings.toggle()
                    TabBarMenuManager.shared.pubShowTabsPopUp = false
                }
            }) {
                Image("ic_layer")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(mapManager.isMapSettings ? Color.white : Color.gray)
                    .frame(width: 30, height: 30, alignment: .center)
            }
            
        }
        .frame(width: 48, height: 48)
        .background(mapManager.isMapSettings ? Color.main : Color.white)
        .clipShape(Circle())
        .padding(.trailing, 20)
        .shadow(radius: 5)
    }
}
