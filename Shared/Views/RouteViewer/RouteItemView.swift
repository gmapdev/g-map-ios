//
//  RouteItemView.swift
//

import SwiftUI
struct RouteItemView: View {
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
        let transitMode = item.route.searchMode?.label ?? ""
        var agencyImage: UIImage? = nil
        if agencyName.count > 0 {
            if !RouteViewerModel.shared.agencyLogos.isEmpty {
                agencyImage = RouteViewerModel.shared.agencyLogos[agencyName.lowercased()]
            }
        }
        return HStack{
            if agencyName.count > 0, let agencyImage = agencyImage {
                Image(uiImage: agencyImage)
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50, alignment: .center)
                    .padding(.bottom, 5)
            }

            Image(item.route.searchMode?.mode_image ?? "ic_bus")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.black).aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30, alignment: .center)
            TextLabel(item.route.busRouteNumber == "N/A" ? item.route.title : item.route.busRouteNumber)
                .font(.subheadline).padding(.horizontal, 2)
                .foregroundColor(fontContrastColor).frame(minWidth: 60)
                .frame(minHeight: 25, alignment: .center)
                .padding(5)
                /// Hex: item.route.color ?? "#aaaaaa")
                /// Initializes a new instance.
                /// - Parameters:

                ///   - Color.init(hex: item.route.color ?? "#aaaaaa"
                .background(Color.init(hex: item.route.color ?? "#aaaaaa"))
                .cornerRadius(5)
                .padding(.all, 5)
                .shadow(color: Color.gray, radius: 2)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            if item.route.busRouteNumber != "N/A"{
                if item.route.title.lowercased() != item.route.busRouteNumber.lowercased(){
                    TextLabel(item.route.title)
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer()
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
                        .padding(.leading, 10)
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
        VStack(spacing: 4){
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
            Spacer().frame(height: 10)
            PagerView(routeItem: item)
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
                    .padding(10)
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
