//
//  RouteItemViewAODA.swift
//

import SwiftUI
struct RouteItemViewAODA: View {
    @ObservedObject var routeManager = RouteManager.shared
    var modeManager = ModeManager.shared
    @Binding var item: RouteItem
    @State var busRenderTimer: Timer?
    var action: (() -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                routeManager.showRouteInfo(route: self.item)
                item.isSelected = true
                action?()
            }) {
                routeInfoView
                    .padding(.top, 10)
            }
            if item.isSelected {
                detailsView
                    .padding(.top, 5)
            }
        }
        .background(item.isSelected ? Color.main.opacity(0.1) : Color.clear)
        .clipShape(RoundedCorner(radius: 15, corners: .allCorners))
        .padding(.horizontal)
    }
    
    /// Route info view.
    /// - Parameters:
    ///   - some: Parameter description
    private var routeInfoView: some View {
        let fontContrastColor = Helper.shared.getContrastColor(hexColor: item.route.color ?? "#aaaaaa")
        let agencyName = item.route.agencyName ?? ""
        let transitMode = item.route.searchMode?.label ?? "bus"
        let modeIcon = item.route.searchMode?.mode_image ?? "ic_bus"
        var agencyImage = UIImage()
        if agencyName.count > 0 {
            agencyImage = RouteViewerModel.shared.agencyLogos[agencyName.lowercased()] ?? UIImage()
        }
        return VStack(alignment: .leading){
            HStack {
                if agencyName.count > 0 {
                    Image(uiImage: agencyImage)
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60, alignment: .center)
                        .padding(.bottom, 5)
                }
                
                Image(modeIcon)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.black).aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60, alignment: .center)
                Spacer()
            }

            TextLabel(item.route.busRouteNumber == "N/A" ? item.route.title : item.route.busRouteNumber)
                .font(.subheadline).padding(.horizontal, 2)
                .foregroundColor(fontContrastColor).frame(minWidth: 60)
                .multilineTextAlignment(.leading)
                .padding(5)
                /// Hex: item.route.color ?? "#aaaaaa")
                /// Initializes a new instance.
                /// - Parameters:

                ///   - Color.init(hex: item.route.color ?? "#aaaaaa"
                .background(Color.init(hex: item.route.color ?? "#aaaaaa"))
                .cornerRadius(5)
                .shadow(color: Color.gray, radius: 2)
            if item.route.busRouteNumber != "N/A"{
                if item.route.title.lowercased() != item.route.busRouteNumber.lowercased(){
                    TextLabel(item.route.title)
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                }
            }
        }.padding(.horizontal, 15)
            .addAccessibility(text: agencyName.localized() + "," + transitMode.localized() + "," + (item.route.busRouteNumber == "N/A" ? item.route.title.localized() : item.route.busRouteNumber.localized()) + "," + item.route.title.localized())
    }
    
    /// Hyperlink view.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: some View
    private func hyperlinkView(_ url: String) -> some View {
        VStack{
            let name = Helper.shared.mapAgencyNameAliase(agencyName: routeManager.pubDetails?.agency?.name ?? "")
                HStack{
                    TextLabel("Operated by %1".localized("\(name)"))
                        .font(.caption)
                    Spacer()
                }
            HStack{
                routeDetailView(urlString: url)
                Spacer()
            }
            
        }
    }
    
    /// Details view.
    /// - Parameters:
    ///   - some: Parameter description
    private var detailsView: some View {
        VStack(spacing: 10){
			HStack() {
				if let url = routeManager.pubDetails?.url {
					hyperlinkView(url)
				}else{
					if let url = routeManager.pubDetails?.agency?.url {
						hyperlinkView(url)
					}
				}
				Spacer()
			}
			.padding(.horizontal, 15)
			PagerViewAODA(routeItem: item)
        }
    }
    
    /// Route phone view.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: some View
    private func routePhoneView(_ phonenumber: String) -> some View {
        HStack{
            if phonenumber.count > 0 {
                Button(action: {
                    let tel = phonenumber.replacingOccurrences(of: "-", with: "")
                        .replacingOccurrences(of: "(", with: "")
                        .replacingOccurrences(of: ")", with: "")
                    if let url = URL(string: "tel://\(tel)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack{
                        TextLabel(phonenumber).font(.subheadline).foregroundColor(Color.blue)
                        Spacer()
                    }
                }
            }
            else{
                EmptyView()
            }
        }
    }
    
    /// Route detail view.
    /// - Parameters:
    ///   - urlString: Parameter description
    /// - Returns: some View
    private func routeDetailView(urlString: String) -> some View {
        Button(action: {
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack{
                TextLabel("More Details".localized()).font(.footnote).foregroundColor(Color.blue)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
    }
    
    /// No route view.
    /// - Parameters:
    ///   - some: Parameter description
    private var noRouteView: some View {
        TextLabel("No route URL provided".localized())
            .font(.caption)
            .padding(5)
            .foregroundColor(Color.black)
    }
    

}
