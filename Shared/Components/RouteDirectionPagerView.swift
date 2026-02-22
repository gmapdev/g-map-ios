//
//  RouteDirectionPagerView.swift
//

import SwiftUI
import Mapbox

struct PagerView: View{
    @State var currentPage: Int = 0
    @State var changedValue: Bool = false
    @State var isOpen : Bool = false
    @State var routeItem: RouteItem
    
    @ObservedObject var routeManager = RouteManager.shared
    @ObservedObject var mapManager = MapManager.shared
    @ObservedObject var stopViewerModel = StopViewerViewModel.shared
    
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View{
        VStack{
        GeometryReader{ g in
            VStack(spacing: 0){
                HStack(spacing: 0){
                    ForEach(routeManager.pubGeometry ?? []) { geoData in
                        VStack(alignment: .leading, spacing: 0){
                            
                            // Direction Name and Expand/Collapse Button
                            HStack(spacing: 0){
                                TextLabel("Towards".localized(), .semibold, .footnote).frame(width: 70).padding(.trailing, 10)
                                
                                VStack{
                                    TextLabel(getDirectionName(data: geoData), .semibold, .footnote)
                                        .fixedSize(horizontal: false, vertical: true)
                                /// Initializes a new instance.
                                /// - Parameters:
                                ///   - minHeight: 30

                                /// - Parameters:
                                }.frame(minHeight: 30).frame(maxHeight: .infinity)

                                Spacer()
                                Button(action: {
                                    isOpen.toggle()
                                    routeManager.isLoading = true
                                    mapManager.deSelectAnnotations()
                                    routeManager.selectedDirectionGeoData = geoData
                                    routeManager.pubDirectionStops.removeAll()
                                    if isOpen {
                                        routeManager.getDirectionStops(geometry: geoData)
                                    }
                                    mapManager.removeRealTimeBusMarker()
                                    routeManager.getRealtimeBusData(route: routeItem.route, pattern: isOpen ? geoData.id : nil)
                                    
                                }, label: {
                                    Image(isOpen ? "ic_uparrow_solid" : "ic_downarrow_solid")
                                        .frame(width: 20, height: 20, alignment: .center)
                                })
                                .frame(width: 30, height: 30, alignment: .center)
                                .accessibility(label: Text(isOpen ? "Collapse stops in this direction" : "Expand stops in this direction").font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)))
                            }
                            .frame(width: g.size.width - 20 < 0 ? 100 : g.size.width - 20)
                            .frame(minHeight:30)
                            Spacer().frame(height: 10)
                            
                            
                        }
                        .frame(width: g.size.width - 20 < 0 ? 100 : g.size.width - 20)
                        .padding(.horizontal, 10)
                    }
                }
                .offset(x: -((CGFloat(self.currentPage) * g.size.width) + 10))
                .animation(.default)
            }
        }
            Spacer().frame(height: getHeight(data: routeManager.pubGeometry, maxWidth: ScreenSize.width()))
        VStack {
            // PageControl
            VStack{
                PageControl(currentPage: $currentPage, valueChanged: $changedValue, numberOfPages: routeManager.pubGeometry?.count ?? 0, changeAction: { page in
                    DispatchQueue.main.async {
                        if let geometry = routeManager.pubGeometry{
                            routeManager.pubDirectionStops.removeAll()
                            if isOpen {
                                routeManager.isLoading = true
                                routeManager.getDirectionStops(geometry: geometry[page])
                            }
                            DispatchQueue.main.async {
                                routeManager.getRealtimeBusData(route: routeItem.route, pattern: geometry[page].id)
                            }
                        }
                    }
                })
            }.frame(minHeight: 20)
            Spacer().frame(height: 20)
            
            if isOpen{
                if !routeManager.isLoading{
                    ForEach(0..<routeManager.pubDirectionStops.count, id: \.self){ index in
                        HStack{
                            ZStack{
                                RoundedRectangle(cornerRadius: 25, style: .continuous)
                                    .frame(width: 5, height: 40, alignment: .center)
                                    .foregroundColor(Color(hex: routeItem.route.color ?? "#13C1C1"))
                                    .offset(y: index == 0 ? 10 : 0)
                                    .offset(y: index == (routeManager.pubDirectionStops.count-1) ? -10 : 0)
                                
                                Circle().strokeBorder(Color(hex: routeItem.route.color ?? "#13C1C1"), lineWidth: 5)
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .background(Circle().foregroundColor(Color.white))
                                
                            }
                            .padding(.trailing, 20)
                            Button(action: {
                                mapManager.removeRealTimeBusMarker()
                                stopViewerModel.stop = routeManager.pubDirectionStops[index]
                                stopViewerModel.getGraphQLStopTimes()
                                stopViewerModel.getGraphQLStopSchedules()
                                stopViewerModel.pubStopViewerOrigin = .route
                                stopViewerModel.addStopMarker()
                                stopViewerModel.pubIsShowingStopViewer = true
                                stopViewerModel.pubKeepShowingStopViewer = true
                                mapManager.deSelectAnnotations()
                            }, label: {
                                HStack{
                                    TextLabel(routeManager.pubDirectionStops[index].name.trimmingCharacters(in: .whitespaces))
                                        .lineLimit(nil)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .font(.footnote)
                                        .foregroundColor(Color.black)
                                    Spacer()
                                }
                            })
                            Spacer()
                            
                        }
                        .padding(.vertical, 5)
                        .padding(.trailing, 5)
                        .frame(height: 30, alignment: .center)
                        
                    }
                    .padding(.leading, 10)
                }else{
                    VStack{
                        HStack{
                            Spacer()
                            ProgressView()
                                .foregroundColor(Color.black)
                                .frame(width: 20, height: 20)
                            Spacer()
                        }
                    }
                }
            }
            Spacer()
        }
    }
        .highPriorityGesture(
            DragGesture()
                .onEnded({ value in
                    if value.translation.width > 10{
                        if self.currentPage > 0{
                            self.currentPage -= 1
                            if let geometry = routeManager.pubGeometry{
                                routeManager.pubDirectionStops.removeAll()
                                if isOpen {
                                    routeManager.isLoading = true
                                    routeManager.getDirectionStops(geometry: geometry[currentPage])
                                }
                                DispatchQueue.main.async {
                                    mapManager.removeRealTimeBusMarker()
                                    routeManager.getRealtimeBusData(route: routeItem.route, pattern: geometry[currentPage].id)
                                }
                            }
                        }
                    }else if value.translation.width < -10{
                        if self.currentPage < (routeManager.pubGeometry?.count ?? 1) - 1{
                            self.currentPage += 1
                            if let geometry = routeManager.pubGeometry{
                                routeManager.pubDirectionStops.removeAll()
                                if isOpen {
                                    routeManager.isLoading = true
                                    routeManager.getDirectionStops(geometry: geometry[currentPage])
                                }
                                DispatchQueue.main.async {
                                    mapManager.removeRealTimeBusMarker()
                                    routeManager.getRealtimeBusData(route: routeItem.route, pattern: geometry[currentPage].id)
                                }
                            }
                        }
                    }
                })
        )
        
    }
    
    /// Get height.
    /// - Parameters:
    ///   - data: Parameter description
    ///   - maxWidth: Parameter description
    /// - Returns: CGFloat
    func getHeight(data: [Geometry]?, maxWidth: CGFloat) -> CGFloat {
        if let data = data, data.count > currentPage {
            let title = getDirectionName(data: data[currentPage])
            let width = CGFloat(title.count * (AccessibilityManager.shared.pubIsLargeFontSize ? Int(AccessibilityManager.shared.getFontSize()) : 9))
            let imageWidth = 120
            let lines = width / (maxWidth - CGFloat(imageWidth)) < 1 ? 1 : (width / (maxWidth - CGFloat(imageWidth)))
            if lines < 0 {
                return 20
            } else {
                var height = (lines * 20) / 1.8
                if height < 20 {
                    height = 20
                }
                return height
            }
        } else {
            return 0
        }
    }
    
    /// Get direction name.
    /// - Parameters:
    ///   - data: Parameter description
    /// - Returns: String
    func getDirectionName(data: Geometry) -> String{
        return data.desc
    }
    
}

struct PageControl: UIViewRepresentable {
    @Binding var currentPage: Int
    @Binding var valueChanged: Bool
    var numberOfPages: Int
    var changeAction: ((Int) -> Void)? = nil
    
    typealias UIViewType = UIPageControl
    
    /// Make u i view.
    /// - Parameters:
    ///   - context: Parameter description
    /// - Returns: UIPageControl
    func makeUIView(context: Context) -> UIPageControl {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        pageControl.currentPage = currentPage
        pageControl.numberOfPages = numberOfPages
        
        return pageControl
    }
    
    /// Update u i view.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - context: Parameter description
    func updateUIView(_ uiView: UIPageControl, context: Context) {
        if uiView.currentPage != currentPage {
            uiView.currentPage = currentPage
        }
        if uiView.numberOfPages != numberOfPages {
            uiView.numberOfPages = numberOfPages
        }
        if valueChanged{
            changeAction?(currentPage)
            DispatchQueue.main.async {
                valueChanged = false
            }
        }
    }
    
    /// Make coordinator
    /// - Returns: Coordinator
    /// Make coordinator.
    func makeCoordinator() -> Coordinator {
        Coordinator(value: $currentPage, isChanged: $valueChanged)
    }
    
    class Coordinator: NSObject {
        var currentPage: Binding<Int>
        var isValueChanged: Binding<Bool>
        
        /// Value:  binding< int>, is changed:  binding< bool>
        /// Initializes a new instance.
        /// - Parameters:
        ///   - value: Binding<Int>
        ///   - isChanged: Binding<Bool>
        init(value: Binding<Int>, isChanged: Binding<Bool>) {
            self.currentPage = value
            self.isValueChanged = isChanged
        }
        
        /// Value changed.
        /// - Parameters:
        ///   - _: Parameter description
        @objc func valueChanged(_ pageControl: UIPageControl) {
            self.currentPage.wrappedValue = pageControl.currentPage
            self.isValueChanged.wrappedValue = true
        }
    }
}


