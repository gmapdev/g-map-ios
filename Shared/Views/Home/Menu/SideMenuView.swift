//
//  SideMenuView.swift
//

import SwiftUI

enum MenuType: String{
    case startOver = "startover"
    case link = "link"
}

struct SideMenuView: View{
    
    @ObservedObject var homeViewModel = HomeViewModel.shared
    let menuWidth: CGFloat
    let startOverItem = MenuOption(title: "Start Over", icon: "ic_startover", type: MenuType.startOver.rawValue, url: "", isVisible: true, order: 1)
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View{
        ZStack{
            BlurView()
                .addAccessibility(text: AvailableAccessibilityItem.blackAreaMenu.rawValue.localized())
                .onTapGesture(perform: {
                    homeViewModel.pubOpenSideMenu = false
                })
            HStack{
                ScrollView {
                    VStack{
                        Spacer()
                            .frame(height: ScreenSize.safeTop() + 10)
                        ZStack {
                            VStack {
                                MenuItemView(menuItem: startOverItem)
                                SideMenuItemsView(menuItems: FeatureConfig.shared.menu)
                                    .padding(.trailing,40)
                            }
                            if AccessibilityManager.shared.pubIsLargeFontSize {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            homeViewModel.pubOpenSideMenu = false
                                        }, label: {
                                            Image(systemName: "xmark")
                                                .renderingMode(.template)
                                                .resizable()
                                                .padding(5)
                                                .foregroundColor(.black)
                                                .frame(width: 40, height: 40)
                                        })
                                        .addAccessibility(text: "Close button, Double tap to activate".localized())
                                    }
                                    .padding(.horizontal)
                                    Spacer()
                                }
                            }
                        }
                        Spacer()
                        HStack{
                            TextLabel("V\(Bundle.main.fullVersion)")
                                .foregroundColor(Color.black)
                                .font(.subheadline)
                            Spacer()
                        }.padding()
                        Spacer()
                            .frame(height: ScreenSize.safeBottom() + 10)
                    }.frame(width: menuWidth)
                        .background(Color.white)
                        .onTapGesture(perform: {
                            homeViewModel.pubOpenSideMenu = false
                        })
                }
                .background(Color.white)
                Spacer()
            }
        }
        .accessibilityAction {
            homeViewModel.pubOpenSideMenu = false
        }
    }
}

struct SideMenuItemsView: View{
    let menuItems: [MenuOption]
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View{
        ForEach(menuItems) { item in
            if item.isVisible {
                MenuItemView(menuItem: item)
            }
        }
    }
}

struct MenuItemView: View{
    let menuItem: MenuOption
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View{
        HStack(spacing: 10){
            Image(menuItem.icon ?? "")
                .resizable()
                .frame(width: 40, height: 40)
            TextLabel((menuItem.title ?? "").localized(), .bold, .body)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal)
        .onTapGesture {
            handleTap()
        }
        .addAccessibility(text: "%1 Button, Double tap to activate".localized(menuItem.title ?? ""))
    }

    @MainActor private func handleTap() {
        switch menuItem.action {
        case .startOver:
            MapFromToViewModel.shared.resetAction()
            moveToPlanTripPage()
        case .openExternalWeb(let value):
            guard let url = URL(string: value),
                  let scheme = url.scheme?.lowercased(),
                  ["https", "http"].contains(scheme),
                  url.host != nil else {
                OTPLog.log(level: .error, info: "Invalid external web menu URL")
                return
            }
            openMenuURL(url)
        case .phoneCall(let value):
            let number = value.filter { $0.isASCII && ($0.isNumber || $0 == "+") }
            guard number.contains(where: { $0.isNumber }),
                  let url = URL(string: "tel://\(number)") else {
                OTPLog.log(level: .error, info: "Invalid phone menu number")
                return
            }
            openMenuURL(url)
        case .none:
            break
        case .unknown:
            OTPLog.log(level: .warning, info: "Unsupported menu action")
        }
        HomeViewModel.shared.pubOpenSideMenu = false
    }

    @MainActor private func openMenuURL(_ url: URL) {
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                OTPLog.log(level: .error, info: "Unable to open menu action")
                AlertManager.shared.presentAlert(message: "Unable to open this menu item.".localized())
            }
        }
    }
    
    func moveToPlanTripPage() {
        HomeViewModel.shared.pubOpenSideMenu = false
        // MARK: Plan trip page handling
        TabBarMenuManager.shared.currentItemTab = .planTrip
        TabBarMenuManager.shared.currentViewTab = .planTrip
        TabBarMenuManager.shared.switchToTab(.planTrip)
        MapManager.shared.pubIsInTripPlan = false
        MapManager.shared.pubIsInTripPlanDetail = false
        MapManager.shared.pubHideAddressBar = false
        // MARK: Route Viewer page handling
        RouteManager.shared.selectedRoute = nil
        RouteViewerModel.shared.pubLastUpdated = Date().timeIntervalSinceNow
        // MARK: Stop Viewer page handling
        StopViewerViewModel.shared.pubIsShowingStopViewer = false
        // MARK: My Trips page handling
        ProfileManager.shared.pubShowTripList = true
    }

}
