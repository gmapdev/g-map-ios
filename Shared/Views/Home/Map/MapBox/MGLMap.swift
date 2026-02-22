//
//  MGLMap.swift
//

import Foundation
import UIKit
import SwiftUI
import Mapbox
// Prepare the extension for the MGLPointAnnotationView to support the zIndex and image.
public class MGLGeneralAnnotationView: MGLAnnotationView {
    var imageView: UIImageView!
    
    /// Reuse identifier:  string?, image:  u i image
    /// Initializes a new instance.
    /// - Parameters:
    ///   - reuseIdentifier: String?
    ///   - image: UIImage
    required init(reuseIdentifier: String?, image: UIImage) {
        /// Reuse identifier: reuse identifier
        /// Initializes a new instance.
        /// - Parameters:
        ///   - reuseIdentifier: reuseIdentifier
        super.init(reuseIdentifier: reuseIdentifier)
        
        self.imageView = UIImageView(image: image.resizeImage(50, 50))
        self.addSubview(self.imageView)
        self.frame = self.imageView.frame
    }
    
    /// Initializes a new instance.
    /// - Parameters:
    ///   - aDecoder: NSCoder
    required init?(coder aDecoder: NSCoder) {
        /// Coder:) has not been implemented"
        /// Initializes a new instance.
        /// - Parameters:

        ///   - "init(coder: 
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Frame:  c g rect
    /// Initializes a new instance.
    /// - Parameters:
    ///   - frame: CGRect
    override init(frame: CGRect) {
        /// Frame: frame
        /// Initializes a new instance.
        /// - Parameters:
        ///   - frame: frame
        super.init(frame: frame)
    }
}

public class GraphQLMGLGeneralPolyline: MGLPolyline {
    var routeType: String?
    var color: UIColor?
    var payload: [String: Any]?
}

// Prepare the extension for the MGLPointAnnotation to support the pop up information
extension MGLPointAnnotation {
    /// Title:  string, coordinate:  c l location coordinate2 d
    /// Initializes a new instance.
    /// - Parameters:
    ///   - title: String
    ///   - coordinate: CLLocationCoordinate2D
    convenience init(title: String, coordinate: CLLocationCoordinate2D) {
        /// Initializes a new instance.
        self.init()
        self.title = title
        self.coordinate = coordinate
    }
    
    /// Stop:  stop
    /// Initializes a new instance.
    /// - Parameters:
    ///   - stop: Stop
    convenience init(stop: Stop) {
        /// Initializes a new instance.
        self.init()
        self.title = stop.name
        self.coordinate = stop.coordinate.coordinate2D
    }
}



// Marker Type for the mapview
public enum MarkerType: String {
    case transitStop = "transitStop"
    case parkingAndRides = "parkingAndRides"
    case sharedScootersStop = "sharedScootersStop"
    case sharedBikeStop = "sharedBikeStop"
    case markerInRouteForTo = "markerInRouteForTo"
    case markerInRouteForFrom = "markerInRouteForFrom"
    case specialMarkerInRoute = "specialMarkerInRoute"
    case individualMarker = "individualMarker"
    case busStopMarker = "busStopMarker"
    case simulatedUserLocation = "simulatedUserLocation"
    case previewFromMarker = "previewFromMarker"
    case previewToMarker = "previewToMarker"
    case realTimeBusMarker = "realTimeBusMarker"
    case realTimeBusSelectedMarker = "realTimeBusSelectedMarker"
    case tapSelectedMarker = "tapSelectedMarker"
    case directionStopMarker = "directionStopMarker"
}

// Prepare general annotation to hold different marker icon if needed
public class MGLGeneralAnnotation: MGLPointFeature {
    var markerType: MarkerType?
    var imageName: String?
    var info: String?
    var fillColor: UIColor?
    var params: [String: Any]?
}

extension MGLGeneralAnnotation {
    /// Display title.
    /// - Parameters:
    ///   - String?: Parameter description
    var displayTitle: String? {
        guard let params = params,
              let title = params["title"] as? String else {
            return nil
        }
        let newTitle = title.removePrefix("P+R")
        return newTitle.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 ? title : newTitle
    }
}

// Convert MGLMapView to UIViewRepresentable for SwiftUI
struct MGLMap: UIViewRepresentable {
    
    static let routeStartMarker = "ic_origin"
    static let routeEndMarker = "ic_destination"
    static let busStopMarker = "bus_stop"
    static let parkingMarker = "parking_icon"
    static let sharedVehicleBike = "ic_redcircle"
    static let sharedVehicleScooter = "ic_yellowcircle"


    let mapView: MGLMapView = MGLMapView(frame: .zero, styleURL: MGLStyle.lightStyleURL)

    /// Make u i view.
    /// - Parameters:
    ///   - context: Parameter description
    /// - Returns: MGLMapView
    func makeUIView(context: UIViewRepresentableContext<MGLMap>) -> MGLMapView {

        let initialLocation = BrandConfig.shared.default_location
        let zoomLevel = BrandConfig.shared.zoom_level
        mapView.delegate = context.coordinator

        // Fix deprecation warning: use automaticallyAdjustsContentInset instead of UIViewController.automaticallyAdjustsScrollViewInsets
        mapView.automaticallyAdjustsContentInset = false

        mapView.showsUserLocation = true
        mapView.showsUserHeadingIndicator = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        /// Initializes a new instance.
        /// - Parameters:
        ///   - zoomLevel: zoomLevel
        ///   - animated: false
        mapView.setCenter(initialLocation, zoomLevel: zoomLevel, animated: false)
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didMapTapped(_:)))
        mapView.addGestureRecognizer(singleTap)
        let doubleTap = UITapGestureRecognizer(target: self, action: nil)
        doubleTap.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTap)
        singleTap.require(toFail: doubleTap)
        if let gestures = self.mapView.gestureRecognizers {
            for gesture in gestures {
                if let _ = gesture as? UIPanGestureRecognizer {
                    gesture.addTarget(context.coordinator, action: #selector(Coordinator.didMapMoved(_:)))
                }
            }
        }
        
        
        MapManager.shared.mapView = mapView
        
        
        return mapView
    }
    
    /// Update u i view.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - context: Parameter description
    func updateUIView(_ uiView: MGLMapView, context: UIViewRepresentableContext<MGLMap>) {
    }
    
    /// Make coordinator
    /// - Returns: MGLMap.Coordinator
    func makeCoordinator() -> MGLMap.Coordinator {
        let ctx = Coordinator(self)
        MapManager.shared.mapContext = ctx
        return ctx
    }
    
    // MARK: - Configuring MGLMapView
    /// Style url.
    /// - Parameters:
    ///   - styleURL: URL
    /// - Returns: MGLMap
    func styleURL(_ styleURL: URL) -> MGLMap {
        mapView.styleURL = styleURL
        return self
    }
    
    /// Center coordinate.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: MGLMap
    func centerCoordinate(_ centerCoordinate: CLLocationCoordinate2D) -> MGLMap {
        mapView.centerCoordinate = centerCoordinate
        return self
    }
    
    /// Zoom level.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: MGLMap
    func zoomLevel(_ zoomLevel: Double) -> MGLMap {
        mapView.zoomLevel = zoomLevel
        return self
    }
    
    /// Dismiss callout from map
    /// Dismisses callout from map.
    func dismissCalloutFromMap(){
        MapManager.shared.mapContext?.calloutView?.dismissCallout(animated: false)
    }
    
    // MARK: - Implementing MGLMapViewDelegate
    final class Coordinator: NSObject, MGLMapViewDelegate, MGLCalloutViewDelegate {
        var control: MGLMap
        var calloutView: CustomCalloutView?
        var busCalloutView: CustomBusCalloutView?
        var preZoomLevel: Double = 0
        /// _ control:  m g l map
        /// Initializes a new instance.
        /// - Parameters:
        ///   - control: MGLMap
        init(_ control: MGLMap) {
            self.control = control
        }
        
        /// Did map moved.
        /// - Parameters:
        ///   - _: Parameter description
        /// Handles when did map moved.
        @objc public func didMapMoved(_ sender:UIGestureRecognizer) {
            MapManager.shared.followMe(enable: false)
        }
        
        /// Did map tapped.
        /// - Parameters:
        ///   - _: Parameter description
        /// Handles when did map tapped.
        @MainActor @objc public func didMapTapped(_ sender:UIGestureRecognizer) {
            if sender.state == .ended {
                
                let layerIdentifiers: Set = Set(MapManager.shared.styleAnnotationLayerIdentifiers.map{$0})
                let mapView = control.mapView
                let point = sender.location(in: sender.view!)
                let touchCoordinate = mapView.convert(point, toCoordinateFrom: sender.view!)
                
                var busInfo: String?
                let rectArea = CGRect(x: point.x, y: point.y, width: 1, height: 1)
                if let rectAnnotations = mapView.visibleAnnotations(in: rectArea) {
                    for annotation in rectAnnotations {
                        if let title = annotation.title, title != "" {
                            busInfo = title
                        }
                    }
                }
                
                if let busInfo = busInfo {
                    let busCoordinates = CLLocationCoordinate2D(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude)
                    let annotation = MGLGeneralAnnotation(title: busInfo, coordinate: busCoordinates)
                    annotation.markerType = .realTimeBusSelectedMarker
                    annotation.imageName = "ic_stop"
                    mapView.setCenter(CLLocationCoordinate2D(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude), animated: true)
                    mapView.selectAnnotation(annotation, animated: true, completionHandler: nil)
                }
                else{
                    if let calloutView = self.calloutView{
                        if calloutView.isOpened{
                            calloutView.dismissCallout(animated: false, action: calloutView.calloutDismissCompleted)
                            return
                        }
                        
                    }
                    
                    MapManager.shared.isMapSettings = false
                    
                    for feature in mapView.visibleFeatures(at: point, styleLayerIdentifiers: layerIdentifiers) where feature is MGLPointFeature {
                        guard let selectedFeature = feature as? MGLPointFeature else {
                            fatalError("Failed to cast selected feature as MGLPointFeature")
                        }
                        let latitude = selectedFeature.coordinate.latitude
                        let longitude = selectedFeature.coordinate.longitude
                        mapView.setCenter(CLLocationCoordinate2D(latitude: latitude, longitude: longitude), animated: true)
                        showCallout(feature: selectedFeature)
                        return
                    }
                    // To Stop From/To Popup Callout when app is in Live Tracking or Trip Preview
                    if !LiveRouteManager.shared.pubIsRouteActivated && !LiveRouteManager.shared.pubIsPreviewMode{
                        self.showCalloutWithGeoReverse(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude)
                    }
                    
                    
                }
                
            }
        }
        
        /// Get edge insects for callout
        /// - Returns: UIEdgeInsets
        /// Retrieves edge insects for callout.
        @MainActor private func getEdgeInsectsForCallout() -> UIEdgeInsets{
            /// Top: 0, left: 0, bottom: 0, right: 0
            /// Initializes a new instance.
            /// - Parameters:
            ///   - top: 0
            ///   - left: 0
            ///   - bottom: 0
            ///   - right: 0
            var edgeInsects = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
            
            if TabBarMenuManager.shared.currentViewTab == .planTrip{
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    /// Top: ( screen size.height()/2), left: 80, bottom: ( screen size.safe bottom() + 100), right: 80
                    /// Initializes a new instance.
                    /// - Parameters:
                    ///   - top: (ScreenSize.height(
                    edgeInsects = UIEdgeInsets.init(top: (ScreenSize.height()/2), left: 80, bottom: (ScreenSize.safeBottom() + 100), right: 80)
                }
            }
            
            if MapManager.shared.pubSearchRoute{
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    /// Top:  screen size.height() - 50, left: 80, bottom: 0, right: 80
                    /// Initializes a new instance.
                    /// - Parameters:
                    ///   - top: ScreenSize.height(
                    edgeInsects = UIEdgeInsets.init(top: ScreenSize.height() - 50, left: 80, bottom: 0, right: 80)
                } else {
                    /// Top: ( screen size.height()/2) + 250, left: 80, bottom: 90, right: 100
                    /// Initializes a new instance.
                    /// - Parameters:
                    ///   - top: (ScreenSize.height(
                    edgeInsects = UIEdgeInsets.init(top: (ScreenSize.height()/2) + 250, left: 80, bottom: 90, right: 100)
                }
            }
            
            if MapManager.shared.pubIsInTripPlanDetail{
                /// Top: 320, left: 80, bottom: ( screen size.height()/2) - 50, right: 80
                /// Initializes a new instance.
                /// - Parameters:
                ///   - top: 320
                ///   - left: 80
                ///   - bottom: (ScreenSize.height(
                edgeInsects = UIEdgeInsets.init(top: 320, left: 80, bottom: (ScreenSize.height()/2) - 50, right: 80)
            }
            
            if TripViewerViewModel.shared.pubIsShowingTripViewer {
                /// Top: 200, left: 80, bottom: 20, right: 80
                /// Initializes a new instance.
                /// - Parameters:
                ///   - top: 200
                ///   - left: 80
                ///   - bottom: 20
                ///   - right: 80
                edgeInsects = UIEdgeInsets.init(top: 200, left: 80, bottom: 20, right: 80)
            }
            
            if TabBarMenuManager.shared.currentViewTab == .routes{
                /// Top: 300, left: 80, bottom: ( screen size.height()/2) - 50, right: 80
                /// Initializes a new instance.
                /// - Parameters:
                ///   - top: 300
                ///   - left: 80
                ///   - bottom: (ScreenSize.height(
                edgeInsects = UIEdgeInsets.init(top: 300, left: 80, bottom: (ScreenSize.height()/2) - 50, right: 80)
            }
            
            if StopViewerViewModel.shared.pubIsShowingStopViewer {
                /// Top: 320, left: 80, bottom: 20, right: 80
                /// Initializes a new instance.
                /// - Parameters:
                ///   - top: 320
                ///   - left: 80
                ///   - bottom: 20
                ///   - right: 80
                edgeInsects = UIEdgeInsets.init(top: 320, left: 80, bottom: 20, right: 80)
            }
            
            return edgeInsects
        }
        
        /// Show callout with geo reverse.
        /// - Parameters:
        ///   - latitude: Parameter description
        ///   - longitude: Parameter description
        @MainActor func showCalloutWithGeoReverse(latitude: Double, longitude: Double){
            let edgeInsects = getEdgeInsectsForCallout()
            
            let isOpened = self.calloutView?.isOpened ?? false
            if !isOpened {
                let mapView = control.mapView
                MapManager.shared.reverseLocation(latitude: latitude, longitude: longitude) { autoComplete in
                    if let autoComplete = autoComplete, autoComplete.features.count > 0 {
                        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        let label = autoComplete.features.first?.properties.label ?? ""
                        DispatchQueue.main.async {
                            let annotation = MGLGeneralAnnotation(title: "", coordinate: coordinates)
                            annotation.markerType = .tapSelectedMarker
                            annotation.params = ["title":label]
                            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            let altitude = MapManager.shared.mapView.camera.altitude
                            let camera = MGLMapCamera(
                                lookingAtCenter: coordinate,
                                altitude: altitude,
                                pitch: 0,
                                heading: 0)
                            
                            mapView.setCamera(camera, withDuration: 0.5, animationTimingFunction: nil, edgePadding: edgeInsects, completionHandler: nil)
                            MapManager.shared.tapMapCalloutMarker = annotation
                            mapView.selectAnnotation(MapManager.shared.tapMapCalloutMarker, animated: true, completionHandler: nil)
                        }
                    }else{
                        let annotation = MGLGeneralAnnotation(title: "", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                        let stringCoordinates = String(latitude) + " , " + String(longitude)
                        annotation.markerType = .tapSelectedMarker
                        annotation.params = ["title":stringCoordinates]
                        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        let altitude = MapManager.shared.mapView.camera.altitude
                        let camera = MGLMapCamera(
                            lookingAtCenter: coordinate,
                            altitude: altitude,
                            pitch: 0,
                            heading: 0)
                        
                        mapView.setCamera(camera, withDuration: 0.5, animationTimingFunction: nil, edgePadding: edgeInsects, completionHandler: nil)
                        MapManager.shared.tapMapCalloutMarker = annotation
                        mapView.selectAnnotation(MapManager.shared.tapMapCalloutMarker, animated: true, completionHandler: nil)
                    }
                }
            }
        }
        
        
        /// Show callout.
        /// - Parameters:
        ///   - feature: Parameter description
        @MainActor func showCallout(feature: MGLPointFeature) {
            var edgeInsets = getEdgeInsectsForCallout()
            
            let isOpened = self.calloutView?.isOpened ?? false
            if !isOpened {
                let mapView = control.mapView
                let annotation = MGLGeneralAnnotation(title: "", coordinate: feature.coordinate)
                annotation.markerType = .tapSelectedMarker
                annotation.params = feature.attributes
                let coordinate = feature.coordinate
                let altitude = MapManager.shared.mapView.camera.altitude
                let camera = MGLMapCamera(
                    lookingAtCenter: coordinate,
                    altitude: altitude,
                    pitch: 0,
                    heading: 0)
                
                if !MapManager.shared.pubSearchRoute {
                    var top = (ScreenSize.height()/2)-140
                    if TabBarMenuManager.shared.currentViewTab == .routes {
                        top = -5;
                    }
                    edgeInsets = getEdgeInsectsForCallout()
                }
                else{
                    if TabBarMenuManager.shared.currentViewTab == .routes {
                        /// Top: -5, left: 0, bottom: 0, right: 0
                        /// Initializes a new instance.
                        /// - Parameters:
                        ///   - top: -5
                        ///   - left: 0
                        ///   - bottom: 0
                        ///   - right: 0
                        edgeInsets = UIEdgeInsets.init(top: -5, left: 0, bottom: 0, right: 0)
                    }
                    if StopViewerViewModel.shared.pubIsShowingStopViewer {
                        /// Top: 160, left: 0, bottom: 0, right: 0
                        /// Initializes a new instance.
                        /// - Parameters:
                        ///   - top: 160
                        ///   - left: 0
                        ///   - bottom: 0
                        ///   - right: 0
                        edgeInsets = UIEdgeInsets.init(top: 160, left: 0, bottom: 0, right: 0)
                    }
                }
                    mapView.setCamera(camera, withDuration: 0.5, animationTimingFunction: nil, edgePadding:edgeInsets, completionHandler: nil)
                MapManager.shared.tapMapCalloutMarker = annotation
                mapView.selectAnnotation(MapManager.shared.tapMapCalloutMarker, animated: true, completionHandler: nil)
            }
        }
        
        /// Get estimeted postion
        /// - Returns: CGFloat
        /// Retrieves estimeted postion.
        @MainActor func getEstimetedPostion() -> CGFloat{
            switch TabBarMenuManager.shared.currentViewTab{
            case .planTrip:
                if StopViewerViewModel.shared.pubIsShowingStopViewer {
                    return ((ScreenSize.height()/2) - 150)
                }else if TripViewerViewModel.shared.pubIsShowingTripViewer {
                    return ((ScreenSize.height()/2) - 170)
                }else if MapManager.shared.pubIsInTripPlanDetail {
                    return -5
                }
                return ((ScreenSize.height()/2) + 50)
            case .routes:
                return ((ScreenSize.height()/2) - 100)
            default:
                return 40
            }
        }
        
        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - didUpdate: Parameter description
        func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
            if let userLocation = mapView.userLocation, MapManager.shared.isLocateMe {
                mapView.setCenter(userLocation.coordinate, animated: true)
            }
        }
        
        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - annotationCanShowCallout: Parameter description
        /// - Returns: Bool
        func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
            if let annotation = annotation as? MGLGeneralAnnotation, annotation.markerType == .specialMarkerInRoute{
                return false
            }
            return true
        }
        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - calloutViewFor: Parameter description
        /// - Returns: MGLCalloutView?
        func mapView(_ mapView: MGLMapView, calloutViewFor annotation: MGLAnnotation) -> MGLCalloutView? {
            if let annotation = annotation as? MGLGeneralAnnotation, annotation.markerType == .realTimeBusMarker || annotation.markerType == .realTimeBusSelectedMarker{
                busCalloutView = CustomBusCalloutView(representedObject: annotation, title: annotation.title ?? "N/A")
                return busCalloutView
            }else{
                guard let generalAnnotation = annotation as? MGLGeneralAnnotation,
                      let params = generalAnnotation.params,
                      let title = generalAnnotation.displayTitle
                else { return nil }
                let stopID = params["stopID"] as? String ?? ""
                var displayStopCode = Stop.findDisplayStopId(stopID)
                if let stopCode = params["stopCode"] as? String, stopCode.count > 0 {
                    displayStopCode = stopCode
                }
                // Adding Agency Short Name front of the StopID/StopCode for callout View.
                if let agencyName = params["agencyName"] as? String, agencyName.count > 0{
                    displayStopCode = "\(agencyName) \(displayStopCode)"
                }

                calloutView = CustomCalloutView(representedObject: annotation, title: title, stopID: stopID, displayStopCode: displayStopCode)
                calloutView?.calloutDismissCompleted = {
                    mapView.deselectAnnotation(mapView.selectedAnnotations.first, animated: true)
                }
                calloutView?.stopViewerAction = {
                    StopViewerViewModel.shared.stop = MapManager.shared.stops.first(where: { $0.id == stopID })
                    mapView.deselectAnnotation(mapView.selectedAnnotations.first, animated: true)
                    StopViewerViewModel.shared.getGraphQLStopTimes()
                    StopViewerViewModel.shared.getGraphQLStopSchedules()
                    StopViewerViewModel.shared.pubIsShowingStopViewer = true
                    StopViewerViewModel.shared.pubKeepShowingStopViewer = true
                }
                CustomCalloutViewManager.shared.pubCalloutAgencyImages.removeAll()
                CustomCalloutViewManager.shared.calloutView = calloutView
                getShorterStopTimesQueryForOperators(stopID: stopID, calloutView: calloutView)

                return calloutView
            }
            
        }
        
        func getShorterStopTimesQueryForOperators(stopID: String, calloutView: CustomCalloutView?) {
            let api = OTPAPIRequest()
            let requestQuery = GraphQLQueries.shared.shorterStopTimesQueryForOperators
            
            let requestStopTime = RequestShorterStopTimesQueryForOperators(query: requestQuery, variables: ShorterStopTimesQueryForOperators(stopId: stopID))
            
            var jsonKeyPair : [String : Any]?
            do{
                let jsonData = try JSONEncoder().encode(requestStopTime)
                if let jsonKey = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    jsonKeyPair = jsonKey
                }
            }catch{
                OTPLog.log(level: .error, info: "can not convert the parameters to the proper body data.\(requestStopTime)")
            }
            
            api.request(method: .post, path: BrandConfig.shared.graphQL_base_url, params: jsonKeyPair, headers: [:], format: .JSON) { [self] data, error, response in
                
                guard let data = data else {
                    OTPLog.log(level:.info, info:"cannot receive the stop times response")
                    return
                }
                
                if let err = error {
                    OTPLog.log(level:.warning, info:"response from server for stop times is failed, \(err.localizedDescription)")
                    guard let _ = DataHelper.object(data) as? [String: Any] else {
                        OTPLog.log(level:.warning, info:"response from server for stop times is failed, invalid error json data")
                        return
                    }
                    return
                }
                
                do{
                    if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let data = jsonData["data"] as? [String : Any]{
                            if let stop = data["stop"] as? [String : Any] {
                                if let stoptimesForPatterns = stop["stoptimesForPatterns"] as? [[String: Any]] {
                                    DispatchQueue.main.async {
                                        var agencyImages: [UIImage?] = []
                                        if !stoptimesForPatterns.isEmpty {
                                            for stoptime in stoptimesForPatterns {
                                                if let pattern = stoptime["pattern"] as? [String: Any], let route = pattern["route"] as? [String: Any], let agency = route["agency"] as? [String: Any], let agencyName = agency["name"] as? String {
                                                    
                                                    var agencyImage: UIImage? = nil
                                                    if agencyName.count > 0 {
                                                        let mappedAgencyName = Helper.shared.mapAgencyNameAliase(agencyName: agencyName)
                                                        agencyImage = RouteViewerModel.shared.agencyLogos[mappedAgencyName.lowercased()]
                                                        agencyImages.append(agencyImage)
                                                    }
                                                    
                                                }
                                            }
                                        }
                                        
                                        let filteredImages = Helper.shared.removeTDuplicates(from: agencyImages)
                                        CustomCalloutViewManager.shared.calloutView?.setupAgencyIcons(agencyIcons: filteredImages)
                                    }
                                }
                            }
                        } else {
                            OTPLog.log(level:.error, info: "can not decode the data, \(error)")
                        }
                    }
                } catch {
                    OTPLog.log(level:.error, info: "can not decode the data, \(error.localizedDescription)")
                }
            }
        }
        

        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - leftCalloutAccessoryViewFor: Parameter description
        /// - Returns: UIView?
        func mapView(_ mapView: MGLMapView, leftCalloutAccessoryViewFor annotation: MGLAnnotation) -> UIView? {
            return nil
        }
        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - rightCalloutAccessoryViewFor: Parameter description
        /// - Returns: UIView?
        func mapView(_ mapView: MGLMapView, rightCalloutAccessoryViewFor annotation: MGLAnnotation) -> UIView? {
            return UIButton(type: .detailDisclosure)
        }
        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - didFinishLoading: Parameter description
        func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
            if AppConfig.shared.serverConfigUpdated && !MapManager.shared.loadStopsFirstTime {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    MapManager.shared.updateSharedVehiclesFeeds()
                    MapManager.shared.updateParkingAndRidesFeeds()
                    MapManager.shared.updateTransitStopFeeds()
                    MapManager.shared.loadStopsFirstTime = true
                }
            }
        }
        
        
        
        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - imageFor: Parameter description
        /// - Returns: MGLAnnotationImage?
        func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
            guard let annotation = annotation as? MGLGeneralAnnotation, let imageName = annotation.imageName else {
                return nil
            }
            if let image = UIImage(color: UIColor.clear), annotation.markerType == .realTimeBusSelectedMarker {
                return  MGLAnnotationImage(image:image, reuseIdentifier: "realTimeBusSelectedMarker")
                
            }
            if var image = UIImage(named: imageName){
                
                var imageSizeWidth: CGFloat = 20
                var imageSizeHeight: CGFloat = 20
                
                if annotation.markerType != .specialMarkerInRoute {
                    
                    if annotation.markerType == .busStopMarker {
                        image = image.resizeImage(20, 20)
                        image = image.roundCorners(cornerRadius: 10) ?? image
                        
                        imageSizeWidth = 30
                        imageSizeHeight = 30
                    }
                    
                    if annotation.markerType == .simulatedUserLocation {
                        image = image.resizeImage(20, 20)
                        image = image.roundCorners(cornerRadius: 10) ?? image
                        
                        imageSizeWidth = 30
                        imageSizeHeight = 30
                    }
                    
                    if  annotation.markerType == .realTimeBusMarker{
                        image = image.resizeImage(20, 20)
                        image = image.roundCorners(cornerRadius: 10) ?? image
                        imageSizeWidth = 30
                        imageSizeHeight = 30
                    }
                    if annotation.markerType == .previewToMarker {
                        imageSizeWidth = 30
                        imageSizeHeight = 30
                    }
                    if annotation.markerType == .previewFromMarker  || annotation.markerType == .markerInRouteForFrom  || annotation.markerType == .markerInRouteForTo {
                        imageSizeWidth = 25
                        imageSizeHeight = 25
                    }
                    if annotation.markerType == .directionStopMarker{
                        imageSizeWidth = 10
                        imageSizeHeight = 10
                    }
                    let resizedImage = image.resizeImage(imageSizeWidth, imageSizeHeight)
                    
                    return MGLAnnotationImage(image:resizedImage, reuseIdentifier: imageName)
                }
                else{
                    imageSizeWidth = 30
                    imageSizeHeight = 30
                    
                    if let info = annotation.info, info.count >= 4{
                        imageSizeWidth = CGFloat(info.count * 8)
                        imageSizeHeight = 30
                    }
                    let size = CGSize(width: imageSizeWidth, height: imageSizeHeight)
                    var resizedImage = image.resizeImage(size.width, size.height)
                    if let info = annotation.info, let fillColor = annotation.fillColor{
                        let renderer = UIGraphicsImageRenderer(size: CGSize(width:size.width, height:size.height))
                        let finalImage = renderer.image { ctx in
                            ctx.cgContext.setFillColor(fillColor.cgColor)
                            ctx.cgContext.setStrokeColor(fillColor.cgColor)
                            let rectangle = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                            ctx.cgContext.addEllipse(in: rectangle)
                            ctx.cgContext.drawPath(using: .fillStroke)
                            
                            let paragraphStyle = NSMutableParagraphStyle()
                            paragraphStyle.alignment = .center
                            let fillColorHex = Helper.shared.hexStringFromColor(color: fillColor)
                            var fontColor = UIColor.white
                            if let contrastColor = Helper.shared.getContrastColor(hexColor: fillColorHex).cgColor{
                                /// Cg color:contrast color
                                /// Initializes a new instance.
                                /// - Parameters:
                                ///   - cgColor: contrastColor
                                let uiColor = UIColor.init(cgColor:contrastColor)
                                fontColor = uiColor
                            }
                            let attrs = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 13)!,
                                         NSAttributedString.Key.paragraphStyle: paragraphStyle,
                                         NSAttributedString.Key.foregroundColor: fontColor]
                            info.draw(with: CGRect(x:0, y: 6, width: size.width, height: size.height), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                        }
                        let randomIdentifier = "\(Date().timeIntervalSince1970)"
                        return MGLAnnotationImage(image:finalImage, reuseIdentifier: randomIdentifier)
                    }
                    
                    resizedImage = image.resizeImage(20, 20)
                    return MGLAnnotationImage(image:resizedImage, reuseIdentifier: imageName)
                }
            }
            return nil
        }
        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - didDeselect: Parameter description
        @MainActor func mapView(_ mapView: MGLMapView, didDeselect annotation: MGLAnnotation) {
            
            if TabBarMenuManager.shared.currentItemTab == .routes {
                if let annotation = annotation as? MGLGeneralAnnotation,
                   annotation.markerType == .tapSelectedMarker {
                    mapView.removeAnnotations([annotation])
                }
                return
            }
            mapView.removeAnnotations([annotation])
        }
        
        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - viewFor: Parameter description
        /// - Returns: MGLAnnotationView?
        func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
            if annotation is MGLUserLocation && mapView.userLocation != nil {
                return CustomUserLocationAnnotationView()
            }
            return nil
        }
        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - strokeColorForShapeAnnotation: Parameter description
        /// - Returns: UIColor
        func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
            if let polyline = annotation as? GraphQLMGLGeneralPolyline, let color = polyline.color {
                return color
            }
            return .orange
        }
        
        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - regionWillChangeAnimated: Parameter description
        func mapView(_ mapView: MGLMapView, regionWillChangeAnimated animated: Bool){
        }
        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - didChange: Parameter description
        ///   - animated: Parameter description
        func mapView(_ mapView: MGLMapView, didChange mode: MGLUserTrackingMode, animated: Bool) {}
        
        /// Map view.
        /// - Parameters:
        ///   - _: Parameter description
        ///   - regionDidChangeAnimated: Parameter description
        func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
            
            var cmpZoomLevels = [Double]()
            for key in MapManager.shared.thresholdZoomLevelForRefresh.keys {
                if let val = MapManager.shared.thresholdZoomLevelForRefresh[key] {
                    if !cmpZoomLevels.contains(val) {
                        cmpZoomLevels.append(val)
                    }
                }
            }
            
            if preZoomLevel != mapView.zoomLevel {
                var refresh = false
                for val in cmpZoomLevels {
                    if val >= preZoomLevel && val <= mapView.zoomLevel {
                        refresh = true
                        break
                    }
                    
                    if val <= preZoomLevel && val >= mapView.zoomLevel {
                        refresh = true
                        break
                    }
                }
                preZoomLevel = mapView.zoomLevel
                
                if refresh {
                    if let pointFeatures = MapManager.shared.plotAnnotations?.annotations {
                        MapManager.shared.removeAnnotationLayer(layerName: "transitStop")
                        MapManager.shared.removeAnnotationLayer(layerName: "sharedScootersStop")
                        MapManager.shared.removeAnnotationLayer(layerName: "sharedBikeStop")
                        MapManager.shared.drawAnnotations(allFeatures: pointFeatures)
                    }
                }
            }
        }
    }
    
}

