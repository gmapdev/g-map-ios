//
//  MapSettingsView.swift
//

import SwiftUI

class MapStyleItem: Identifiable, ObservableObject {
    let id: String = UUID().uuidString
    var name: String = ""
    @State var isSelected: Bool = false
    
    /// Name:  string, is selected:  bool
    /// Initializes a new instance.
    /// - Parameters:
    ///   - name: String
    ///   - isSelected: Bool
    init(name: String, isSelected: Bool) {
        self.name = name
        self.isSelected = isSelected
    }
}

struct MapLayerItem: Identifiable {
    let id: String = UUID().uuidString
    var name: String = ""
    var icon: String = ""
    var isSelected: Bool = true
	var type: MarkerType
    
    /// Name:  string, icon:  string, is selected:  bool, type:  marker type
    /// Initializes a new instance.
    /// - Parameters:
    ///   - name: String
    ///   - icon: String
    ///   - isSelected: Bool
    ///   - type: MarkerType
    init(name: String, icon: String, isSelected: Bool, type: MarkerType) {
        self.name = name
        self.icon = icon
        self.isSelected = isSelected
		self.type = type
    }
}

final class MapSettingsItems: ObservableObject {
    @Published var mapStyles: [MapStyleItem] = MapSettingsItems.styles
}

extension MapSettingsItems {
    /// Styles.
    /// - Parameters:
    ///   - [MapStyleItem]: Parameter description
    static var styles: [MapStyleItem] {
        [MapStyleItem(name: "Streets", isSelected: false),
         MapStyleItem(name: "Satellite", isSelected: false)]
    }
    
    /// Layers.
    /// - Parameters:
    ///   - [MapLayerItem]: Parameter description
    static var layers: [MapLayerItem] {
        [MapLayerItem(name: "Transit stops", icon: "ic_bus", isSelected: true, type: .transitStop),MapLayerItem(name: "Park + Ride".localized(), icon: "ic_parking_circle", isSelected: false, type: .parkingAndRides),MapLayerItem(name: "Shared Vehicles".localized(), icon: "ic_scooter", isSelected: false, type: .sharedScootersStop)]
    }
}

struct MapSettingsView: View {
	@ObservedObject var mapManager = MapManager.shared
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ScrollView{
            HStack{
                TextLabel("Map Details".localized(), .semibold, .subheadline)
                    .foregroundColor(Color.white)
                    .padding(.bottom, 10)
                Spacer()
            }
            if AccessibilityManager.shared.pubIsLargeFontSize {
                HStack{
                    VStack {
                        ForEach((0..<self.mapManager.layers.count), id:\.self) {
                            LayerToggleView(layerItem: self.$mapManager.layers[$0])
                        }
                    }
                    .padding(.leading, 2)
                    Spacer()
                }
            }  else {
                HStack {
                    ForEach((0..<self.mapManager.layers.count), id:\.self) {
                        LayerToggleView(layerItem: self.$mapManager.layers[$0])
                    }
                    Spacer()
                }
            }
            HorizontalLine(color: Color.white).padding(.top, 5)
            HStack{
                TextLabel("Map Type".localized(), .semibold, .subheadline)
                    .foregroundColor(Color.white)
                    .padding(.top, 10)
                Spacer()
                
            }
            
            if AccessibilityManager.shared.pubIsLargeFontSize {
                HStack {
                    VStack(spacing: 15){
                        Toggle(isOn: Binding<Bool>(
                            get:{
                                return self.mapManager.streetViewMapStyle
                            },
                            set:{
                                self.mapManager.streetViewMapStyle = $0
                                self.mapManager.satelliteViewMapStyle = !$0
                                self.mapManager.switchMapViewStyle(style: self.mapManager.streetViewMapStyle ? .streets : .satellite)
                            }
                        )) {
                        }.toggleStyle(CheckMarkCircleToggleStyle(label: MapStyle.streets.rawValue.capitalizingFirstLetter()))
                            .background(Color.main)
                        
                        Toggle(isOn: Binding<Bool>(
                            get:{
                                return self.mapManager.satelliteViewMapStyle
                            },
                            set:{
                                self.mapManager.satelliteViewMapStyle = $0
                                self.mapManager.streetViewMapStyle = !$0
                                self.mapManager.switchMapViewStyle(style: self.mapManager.satelliteViewMapStyle ? .satellite : .streets)
                            }
                        )) {
                        }.toggleStyle(CheckMarkCircleToggleStyle(label: MapStyle.satellite.rawValue.capitalizingFirstLetter()))
                            .background(Color.main)
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                HStack(spacing: 15){
                    Toggle(isOn: Binding<Bool>(
                        get:{
                            return self.mapManager.streetViewMapStyle
                        },
                        set:{
                            self.mapManager.streetViewMapStyle = $0
                            self.mapManager.satelliteViewMapStyle = !$0
                            self.mapManager.switchMapViewStyle(style: self.mapManager.streetViewMapStyle ? .streets : .satellite)
                        }
                    )) {
                    }.toggleStyle(CheckMarkCircleToggleStyle(label: MapStyle.streets.rawValue.capitalizingFirstLetter()))
                        .background(Color.main)
                    
                    Toggle(isOn: Binding<Bool>(
                        get:{
                            return self.mapManager.satelliteViewMapStyle
                        },
                        set:{
                            self.mapManager.satelliteViewMapStyle = $0
                            self.mapManager.streetViewMapStyle = !$0
                            self.mapManager.switchMapViewStyle(style: self.mapManager.satelliteViewMapStyle ? .satellite : .streets)
                        }
                    )) {
                    }.toggleStyle(CheckMarkCircleToggleStyle(label: MapStyle.satellite.rawValue.capitalizingFirstLetter()))
                        .background(Color.main)
                    Spacer()
                }
            }
            HStack{
                Spacer()
                TextLabel("V\(Bundle.main.fullVersion)")
                    .foregroundColor(Color.white)
                    .font(.caption)
            }
            .padding(.bottom)
            Spacer()
        }.frame(minHeight: 300, alignment: .center)
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color.main)
    }
	
}

struct LayerToggleView: View{
	@ObservedObject var mapManager = MapManager.shared
	@Binding var layerItem: MapLayerItem
 /// Body.
 /// - Parameters:
 ///   - some: Parameter description
	var body: some View {
		Toggle(isOn:  Binding<Bool>(
			get:{
				return self.layerItem.isSelected
			},
			 set:{
                self.layerItem.isSelected = $0
                 if !(self.layerItem.isSelected) {
                     if layerItem.type == .sharedScootersStop {
                         mapManager.removeAnnotationLayer(layerName: "sharedBikeStop")
                         mapManager.removeAnnotationLayer(layerName: "sharedScootersStop")
                     }else {
                         mapManager.removeAnnotationLayer(layerName: self.layerItem.type.rawValue)
                     }
                 }
                 mapManager.renderMarkerInMap()
			 }
		 )) {
		}
         .toggleStyle(CheckMarkSquareToggleStyle(label: layerItem.name, icon: layerItem.icon))
         .addAccessibility(text: accesibilityNameText().localized())
	}
    
    /// Accesibility name text
    /// - Returns: String
    /// Accesibility name text.
    func accesibilityNameText() -> String {
        var text = layerItem.name
        if layerItem.name == "Park + Ride"{
            text = "Park and Ride".localized()
        }
        return layerItem.isSelected ? "%1 on, double tap to turn off".localized(text) : "%1 off, double tap to turn on".localized(text)
    }
}

struct MapSettingsView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        MapSettingsView()
    }
}


