//
//  StopsListView.swift
//

import SwiftUI

struct StopsListView: View {
    @ObservedObject var autoCompleteManager = AutoCompleteManager.shared
    @ObservedObject var stopsManager = StopsManager.shared
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ScrollView{
            VStack{
                HStack{
                    TextLabel("Favorite Stops".localized(), .bold, .subheadline)
                        .foregroundColor(Color.black)
                    Spacer()
                }
                stopsFavouriteListItemView()
                Divider()
                bottomInfoView()
            }.padding(.horizontal, 15)
        }
    }
    
    /// Bottom info view
    /// - Returns: some View
    /// Bottom info view.
    func bottomInfoView() -> some View{
        VStack{
            TextLabel("To find a stop, search in the bar above or tap a transit stop on the map".localized())
                .font(.system(size: 15))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 180)
            
            Image("ic_stops")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color(hex: "848484"))
                .frame(width: 20, height: 20, alignment: .center)
                .aspectRatio(contentMode: .fit)
        }.padding(.vertical, 15)
            .padding(.bottom, 30)
    }
    
    /// Stops favourite list item view
    /// - Returns: some View
    /// Stops favourite list item view.
    func stopsFavouriteListItemView() -> some View{
        return VStack{
            if let login = AppSession.shared.loginInfo {
                let locations = retrieveFavoriteStops(login: login)
                if locations.count>0 {
                    ForEach(0..<locations.count, id: \.self) { index in
                        if let stop = stopsManager.findStopByName(stopName: locations[index].address) { let stopId = stop.id
                            stopFavouriteItemView(stopId: stopId, location: locations[index])
                        }
                    }
                }else{
                    HStack{
                        TextLabel("No favorite stops".localized()).font(.system(size: 15))
                        Spacer()
                    }
                }
            }else{
                HStack{
                    TextLabel("Please login to see your favorite stops".localized()).font(.system(size: 15))
                    Spacer()
                }
            }
        }.padding(.vertical, 15)
            .onReceive(autoCompleteManager.didChange){ stopId in
                if autoCompleteManager.autoCompleteMode == .stopList {
                    if let stop = stopsManager.findStopById(stopId: stopId){
                        StopViewerViewModel.shared.itinerary = nil
                        StopViewerViewModel.shared.itineraryStop = nil
                        StopViewerViewModel.shared.pubIsShowingStopViewer = true
                    }
                }
            }
    }
    
    /// Retrieve favorite stops.
    /// - Parameters:
    ///   - login: Parameter description
    /// - Returns: [FavouriteLocation]
    func retrieveFavoriteStops(login: LoginInfo) -> [FavouriteLocation]{
        var favoriteStops = [FavouriteLocation]()
        if let locations = login.savedLocations{
            for location in locations {
                if location.type == "stop"{
                    favoriteStops.append(location)
                }
            }
        }
        return favoriteStops
    }
    
    /// Stops list item view
    /// - Returns: some View
    /// Stops list item view.
    func stopsListItemView() -> some View{
        let locations = MapManager.shared.stops
        return LazyVStack{
            if locations.count > 0{
                    ForEach(0..<locations.count, id: \.self) { index in
                        stopItemView(stopId: locations[index].id, location: locations[index])
                }
            }else{
                TextLabel("Can not find location information".localized())
            }
        }.padding(.vertical, 15)
            .onReceive(autoCompleteManager.didChange){ stopId in
                if autoCompleteManager.autoCompleteMode == .stopList {
                    if let stop = stopsManager.findStopById(stopId: stopId){
                        StopViewerViewModel.shared.itinerary = nil
                        StopViewerViewModel.shared.itineraryStop = nil
                        StopViewerViewModel.shared.pubIsShowingStopViewer = true
                    }
                }
            }
    }
    
    /// Stop favourite item view.
    /// - Parameters:
    ///   - stopId: Parameter description
    ///   - location: Parameter description
    /// - Returns: some View
    func stopFavouriteItemView(stopId: String, location: FavouriteLocation) -> some View {
        HStack{
            Image("ic_stops")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color(hex: "848484"))
                .frame(width: 20, height: 20, alignment: .center)
                .aspectRatio(contentMode: .fit)
            
            Button(action: {
                if let stop = stopsManager.findStopById(stopId: stopId) {
                    StopViewerViewModel.shared.itinerary = nil
                    StopViewerViewModel.shared.itineraryStop = nil
                    StopViewerViewModel.shared.pubIsShowingStopViewer = true
                    MapManager.shared.pubHideStopSearchBar = true
                }
            }, label: {
                VStack(alignment:.leading){
                    TextLabel("\(location.address)".localized())
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    HStack{
                        TextLabel("Stop ID: %1".localized("\(stopId.removeStopIDPrefix)"))
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "848484"))
                        Spacer()
                    }
                }
            })
            
            Spacer()
            
            Button(action: {
                AlertManager.shared.presentConfirm(title: "Attention", message: "You are going to remove %1 from favorite list. Are you sure?".localized(location.address), primaryButtonText: "Yes", secondaryButtonText: "No") { result in
					if result == "Yes"{
						stopsManager.removeFavouriteStop(stopId: stopId)
					}
				}
            }, label: {
                Image(stopsManager.isFavouriteStop(stopId:stopId) ? "ic_saved" : "ic_save")
            })
        }
    }
    
    /// Stop item view.
    /// - Parameters:
    ///   - stopId: Parameter description
    ///   - location: Parameter description
    /// - Returns: some View
    func stopItemView(stopId: String, location: Stop) -> some View {
        HStack{
            Image("ic_stops")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color(hex: "848484"))
                .frame(width: 20, height: 20, alignment: .center)
                .aspectRatio(contentMode: .fit)
            
            Button(action: {
                if let _ = stopsManager.findStopById(stopId: stopId) {
                    StopViewerViewModel.shared.itinerary = nil
                    StopViewerViewModel.shared.itineraryStop = nil
                    StopViewerViewModel.shared.pubIsShowingStopViewer = true
                }
            }, label: {
                VStack(alignment:.leading){
                    TextLabel("\(location.name)".localized())
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    HStack{
                        TextLabel("Stop ID: %1".localized("\(stopId)"))
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "848484"))
                        Spacer()
                    }
                }
            })
            
            Spacer()
            
            Button(action: {
                let isFavourite = stopsManager.isFavouriteStop(stopId:stopId)
                if isFavourite {
                    stopsManager.removeFavouriteStop(stopId: stopId)
                }else{
                    stopsManager.favouriteStop(stopId: stopId)
                }
            }, label: {
                Image(stopsManager.isFavouriteStop(stopId:stopId) ? "ic_saved" : "ic_save")
            })
        }
    }
}

struct StopsListView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        StopsListView()
    }
}
