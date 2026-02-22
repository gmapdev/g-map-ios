//
//  RouteDirectionPagerViewAODA.swift
//

import SwiftUI
import Mapbox

struct ScrollOffsetPreferenceKey: PreferenceKey {
	static var defaultValue: CGPoint = .zero
 /// Reduce.
 /// - Parameters:
 ///   - value: Parameter description
 ///   - nextValue: Parameter description
 /// - Returns: CGPoint)
	static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}

struct PagerButtonAODA: View {
	@Binding var index: Int
	var total: Int = 0
	var buttonSize = 10.0
	var onTap:((Int)->Void)?
 /// Body.
 /// - Parameters:
 ///   - some: Parameter description
	var body: some View {
		Button(action: {
			if index + 1 < total {
				index = index + 1
			}else{
				index = 0
			}
			
			onTap?(index)
		}, label: {
			HStack{
				ForEach(0..<total, id:\.self){ idx in
					if index == idx {
                        Circle().fill(Color.gray).frame(width:buttonSize, height:buttonSize).addAccessibility(text: "Page %1, Tap to change".localized(idx + 1))
					}else{
						Circle().stroke(lineWidth:2).stroke(Color.gray).frame(width:buttonSize, height:buttonSize).addAccessibility(text: "Page %1,Tap to change".localized(idx + 1))
					}
				}
			}
		})
	}
}

struct PagerViewAODA: View{
    @State var currentPage: Int = 0
    @State var isOpen : Bool = false
    @State var routeItem: RouteItem
	@State private var scrollPosition: CGPoint = .zero
    @ObservedObject var routeManager = RouteManager.shared
    @ObservedObject var mapManager = MapManager.shared
    @ObservedObject var stopViewerModel = StopViewerViewModel.shared
	
 /// Load data for page.
 /// - Parameters:
 ///   - index: Parameter description
 /// Loads data for page.
	func loadDataForPage(index: Int){
		DispatchQueue.main.async {
			if let geometry = routeManager.pubGeometry, geometry.count > index && index >= 0{
				
				routeManager.pubDirectionStops.removeAll()
				if isOpen {
					routeManager.isLoading = true
					routeManager.getDirectionStops(geometry: geometry[index])
				}
			}
		}
	}
	
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
		let offsetPadding = 80.0
        return VStack{
			ScrollViewReader { value in
				ScrollView(.horizontal){
					HStack(spacing: 0){
						ForEach(0..<(routeManager.pubGeometry ?? []).count, id:\.self) { index in
							VStack(alignment: .leading, spacing: 0){
                                HStack {
                                    TextLabel("Towards".localized(), .semibold, .footnote)
                                    Spacer()
                                }
                                .frame(width: UIScreen.main.bounds.width - offsetPadding)
								HStack {
									TextLabel(getDirectionName(data: (routeManager.pubGeometry ?? [])[index]), .semibold, .footnote)
										.fixedSize(horizontal: false, vertical: true)
                                    Spacer()
									Button(action: {
										isOpen.toggle()
										routeManager.isLoading = true
										mapManager.deSelectAnnotations()
										routeManager.selectedDirectionGeoData = (routeManager.pubGeometry ?? [])[index]
										routeManager.pubDirectionStops.removeAll()
										DispatchQueue.main.async {
											if isOpen {
												routeManager.getDirectionStops(geometry: (routeManager.pubGeometry ?? [])[index])
											}
											mapManager.removeRealTimeBusMarker()
                                            routeManager.getRealtimeBusData(route: routeItem.route, pattern: routeManager.selectedDirectionGeoData?.id)
										}
									}, label: {
											Image(isOpen ? "ic_uparrow_solid" : "ic_downarrow_solid")
												.resizable()
												.frame(width: 35, height: 30, alignment: .center)
									})
									.accessibility(label: Text(isOpen ? "Collapse stops in this direction" : "Expand stops in this direction").font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)))
								}
                                .frame(width: UIScreen.main.bounds.width - (offsetPadding))
                            }
                            .id(index)
                        }
                    }
                    .background(GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).origin)
                    })
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        self.scrollPosition = value
                        let idx = Int(floor(-value.x/(UIScreen.main.bounds.size.width - offsetPadding)))
                        
                        if(self.currentPage != idx){
                            self.currentPage = idx
                            loadDataForPage(index: idx)
                        }
                    }
                }
                .coordinateSpace(name: "scroll")
                .frame(width:UIScreen.main.bounds.size.width - offsetPadding)
                .padding(.top, 10)
                Spacer().frame(height: 45)
                VStack(spacing: 0){
                    VStack(spacing: 0){
                        PagerButtonAODA(index: self.$currentPage, total:(routeManager.pubGeometry ?? []).count){ pageIndex in
                            
                            if(pageIndex >= 0 && pageIndex <= (routeManager.pubGeometry ?? []).count){
                                value.scrollTo(pageIndex)
                            }
                            
                            self.loadDataForPage(index: pageIndex)
                        }
                    }
                    Spacer().frame(height: 10)
                    
                    if isOpen{
                        if !routeManager.isLoading{
                            ForEach(0..<routeManager.pubDirectionStops.count, id: \.self){ index in
                                HStack{
                                    ZStack{
                                        Rectangle()
                                            .frame(width: 5, alignment: .center)
                                            .foregroundColor(Color(hex: routeItem.route.color ?? "#13C1C1"))
                                            .offset(y: index == 0 ? 40 : 0)
                                            .offset(y: index == (routeManager.pubDirectionStops.count-1) ? -40 : 0)
                                        
                                        Circle().strokeBorder(Color(hex: routeItem.route.color ?? "#13C1C1"), lineWidth: 5)
                                            .frame(width: 30, height: 30, alignment: .center)
                                            .background(Circle().foregroundColor(Color.white))
                                        
                                    }
                                    .padding(.trailing, 20)
                                    Button(action: {
                                        //MARK: Fix it later
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
                                                .multilineTextAlignment(.leading)
                                                .font(.footnote)
                                                .foregroundColor(Color.black)
                                                .padding(.vertical, 5)
                                            Spacer()
                                        }
                                    })
                                    Spacer()
                                }
                                .padding(.trailing, 5)
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
