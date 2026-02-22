//
//  MapManager.swift
//

import Foundation
import Combine
import SwiftUI
import Mapbox
import MapKit

public struct GraphQLMapPlotItem {
    public var annotations: [MGLGeneralAnnotation]?
    public var overlays: [GraphQLMGLGeneralPolyline]?
}

/// This is used to plot the middle marker for the route.
public struct RouteSpecialPoint {
    var coordinate: CLLocationCoordinate2D
    var color: UIColor?
    var info: String
}

/// This is used to prepare the segment in the route
public struct RouteSegment {
    var routeType: Mode
    var routeColor: UIColor
    var coorindates: [CLLocationCoordinate2D]
}

/// This is used to control the map size
public enum MapSize {
    case half
    case full
}

struct PlanTripPlotItems {
    let segments: [RouteSegment]
    let origin: CLLocationCoordinate2D?
    let destination: CLLocationCoordinate2D?
    let specialRoutePoint: [RouteSpecialPoint]?
}

struct RoutePlotItems {
    let segments: [RouteSegment]
}

struct ViewArea{
    let topRight: CGPoint
    let bottomLeft: CGPoint
}

struct PlotArea{
    let sw: CLLocationCoordinate2D
    let ne: CLLocationCoordinate2D
}

class MapManager: ObservableObject, AutocompleteService, ParkAndRideService{
    
    @Published var pubIsInTripPlan = false
    @Published var pubIsInTripPlanDetail = false
    @Published var pubLastMapUpdate = Date().timeIntervalSince1970
    @Published var mapSize = MapSize.full
    @Published var streetViewMapStyle = true
    @Published var satelliteViewMapStyle = false
    @Published var layers = [MapLayerItem]()
    @Published var isMapSettings = false
    @Published var isLocateMe = false
    @Published var pubSearchRoute = false
    @Published var isSearchingPlace = false
    @Published var pubHideAddressBar = false
    @Published var pubHideStopSearchBar = false
    @Published var pubCompassPosition = CGPoint(x: 15, y: 20)
    @Published var pubShowUsersCurrentLocation = true
    @Published var pubLastUpdatedTimestamp = Date().timeIntervalSince1970
    @Published var pubMapCamera = MGLMapCamera()
    
    var plantTripPlotItems:PlanTripPlotItems?
    var graphQLPlanTripPlotItems: GraphQLPlanTripPlotItems?
    var routePlotItems:RoutePlotItems?
    
    var mapContext : MGLMap.Coordinator?
    
    // This is used to control and guarantee, no one will change the value when we try to update the markers
    /// Initializes a new instance.
    /// - Parameters:
    ///   - label: "ibigroup.map.marker.refresh"
    private var markersLock = DispatchQueue.init(label: "ibigroup.map.marker.refresh")
    /// Label: "ibigroup.map.marker.datasource.locker"
    /// Initializes a new instance.
    /// - Parameters:
    ///   - label: "ibigroup.map.marker.datasource.locker"
    private var markerDataSourceLocker = DispatchQueue.init(label: "ibigroup.map.marker.datasource.locker")
    
    // MGLMap instance to be shared for all the other pages
    private var mglMap: MGLMap?
    private var routeBounds: MGLCoordinateBounds?
    
    // This is used to hold zoom level threshold for refresh the markers
    public var thresholdZoomLevelForRefresh: [String: Double] = {
        return [
            MarkerType.transitStop.rawValue: 14.0,
            MarkerType.parkingAndRides.rawValue: 0.0,
            MarkerType.sharedScootersStop.rawValue: 14.0,
            MarkerType.sharedBikeStop.rawValue: 14.0,
        ]
    }()
    
    private var cancellableSet = Set<AnyCancellable>()
    var service: APIServiceProtocol = APIService()
    var autoCompleteResult: Autocomplete?
    
    // This is used to hold all the annotations which we want to draw and present
    private var routeMarkers = [MGLGeneralAnnotation]()
    private var segmentRoutePolylines = [GraphQLMGLGeneralPolyline]()
    
    private var mapMarkers = [MGLGeneralAnnotation]()
    private var mapScooterMarkers = [MGLGeneralAnnotation]()
    private var mapBikeMarkers = [MGLGeneralAnnotation]()
    
    // for map view to control the displaying of marker based on different zoom level
    public var preMapMarkers = [MGLGeneralAnnotation]()
    
    // Used to hold the MapView entity so that we can easily access
    public lazy var mapView: MGLMapView = {
        return MGLMapView()
    }()
    
    // This is used to hold the route customized layer
    private var styleRouteSourceIdentifiers = [String]()
    private var styleRouteLayerIdentifiers = [String]()
    
    // This is used to hold the annotation customized layer
    private var styleAnnotationSourceIdentifiers = [String]()
    public var styleAnnotationLayerIdentifiers = [String]()
    
    var stops: [Stop] = []
    var stopMarker = MGLGeneralAnnotation()
    var simulatedUserLocationMarker = MGLGeneralAnnotation()
    var realTimeBusMarker = MGLGeneralAnnotation()
    var realTimeBusMarkersGroup = [MGLGeneralAnnotation()]
    var tapMapCalloutMarker = MGLGeneralAnnotation()
    var fromMarker: MGLGeneralAnnotation?
    var toMarker: MGLGeneralAnnotation?
    var loadStopsFirstTime = false
    
    // Shared instance to hold and control the map related operations
    public static var shared: MapManager = {
        let mgr = MapManager()
        return mgr
    }()
    
    /// Initializes a new instance.
    init() {
        var newMapLayers = [MapLayerItem]()
        for layer in MapSettingsItems.layers {
            let layerItem = MapLayerItem(name: layer.name, icon: layer.icon, isSelected: layer.isSelected, type: layer.type)
            newMapLayers.append(layerItem)
        }
        layers.append(contentsOf: newMapLayers)
    }
    // MARK: Updated for Polyline
    var plotAnnotations: GraphQLMapPlotItem? {
        willSet{
            guard let item = plotAnnotations else {
                return
            }
            if let overlays = item.overlays {
                self.mapView.removeOverlays(overlays)
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.pubLastMapUpdate = Date().timeIntervalSince1970
            }
        }
        
        didSet {
            guard let item = plotAnnotations else {
                return
            }
            
            if let annotations = item.annotations {
                self.drawAnnotations(allFeatures: annotations)
            }
            
            if let overlays = item.overlays {
                self.mapView.addOverlays(overlays)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.pubLastMapUpdate = Date().timeIntervalSince1970
            }
        }
    }
    
    var graphQLPlotRouteItem : GraphQLMapPlotItem? {
        willSet{
            
            DispatchQueue.main.async { [weak self] in
                self?.pubLastMapUpdate = Date().timeIntervalSince1970
            }
        }
        
        didSet {
            guard let item = graphQLPlotRouteItem else {
                return
            }
            
            if let overlays = item.overlays, overlays.count > 0 {
                self.drawPolyline(polylines: overlays)
            }
            
            if let annotations = item.annotations {
                self.mapView.addAnnotations(annotations)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.pubLastMapUpdate = Date().timeIntervalSince1970
            }
        }
    }
    
    /// Follow me.
    /// - Parameters:
    ///   - enable: Parameter description
    public func followMe(enable: Bool){
        if enable {
            self.mapView.userTrackingMode = .followWithHeading
            if let userLocation = self.mapView.userLocation {
                var latitude: Double = userLocation.coordinate.latitude
                var longitude: Double = userLocation.coordinate.longitude
                let defaultLocation = BrandConfig.shared.default_location
                if latitude == -180 || longitude == -180{
                    latitude = defaultLocation.latitude
                    longitude = defaultLocation.longitude
                }
                let currentCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                self.mapView.setCenter(currentCoordinate, animated: false)
                if LiveRouteManager.shared.pubIsRouteActivated && self.mapView.zoomLevel < 14.6 {
                        self.mapView.zoomLevel = 14.6
                }
            }
        }else{
            self.mapView.userTrackingMode = .none
        }
        isLocateMe = enable
    }
    
    /// Zoom in map
    /// Zoom in map.
    public func zoomInMap(){
        if self.mapView.zoomLevel + 2 >= 19 {
            return
        }
        mapView.zoomLevel += 1
    }
    
    /// Zoom out map
    /// Zoom out map.
    public func zoomOutMap(){
        if self.mapView.zoomLevel - 2 <= 1 {
            return
        }
        mapView.zoomLevel -= 1
    }
    
    /// Shared map instance for all the pages to use
    /// Map.
    /// - Returns: MGLMap
    public func map() -> MGLMap {
        
        guard let map = self.mglMap else {
            let sharedMapInstance = MGLMap()
            self.mglMap = sharedMapInstance
            self.mglMap?.mapView.compassView.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.mglMap?.mapView.compassViewPosition = .bottomLeft
                self.mglMap?.mapView.compassViewMargins = self.pubCompassPosition
                self.mglMap?.mapView.compassView.isHidden = false
            }
            return sharedMapInstance
        }
        map.mapView.compassView.isHidden = true
        map.mapView.setNeedsLayout()
        map.mapView.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.mglMap?.mapView.compassViewPosition = .bottomLeft
            self.mglMap?.mapView.compassViewMargins = self.pubCompassPosition
            self.mglMap?.mapView.compassView.isHidden = false
        }
        return map
    }
    
    /// Udate compass position.
    /// - Parameters:
    ///   - newPosition: Parameter description
    public func udateCompassPosition(newPosition: CGPoint){
        self.pubCompassPosition = newPosition
    }
    
    /// Center the route if needed
    /// Center route.
    public func centerRoute(){
        let dispatchTime = DispatchTime.now() + (TripViewerViewModel.shared.pubIsShowingTripViewer ? 1 : 0 )
        /// Top: 40, left: 40, bottom: 40, right: 40
        var edgeInset:UIEdgeInsets = UIEdgeInsets.init(top: 40, left: 40, bottom: 40, right: 40)
        if(MapManager.shared.pubIsInTripPlan){
            /// Top: 70, left: 100, bottom: 70, right: 100
            /// Initializes a new instance.
            /// - Parameters:
            ///   - top: 70
            ///   - left: 100
            ///   - bottom: 70
            ///   - right: 100
            edgeInset = UIEdgeInsets.init(top: 70, left: 100, bottom: 70, right: 100)
        }
        
        DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
            if let routeBounds = self.routeBounds {
                let camera = MapManager.shared.mapView.camera(MapManager.shared.mapView.camera, fitting: routeBounds, edgePadding: edgeInset)
                self.mapView.setCamera(camera, animated: false)
            }
        })
        
    }
    
    /// Distance btw two coords.
    /// - Parameters:
    ///   - topRight: Parameter description
    ///   - bottomLeft: Parameter description
    /// - Returns: Double
    private func distanceBtwTwoCoords(topRight: CLLocationCoordinate2D, bottomLeft: CLLocationCoordinate2D) -> Double{
        return sqrt(pow((topRight.longitude - bottomLeft.longitude), 2) + pow((topRight.latitude - bottomLeft.latitude), 2))
    }
    
    /// Distance btw two points.
    /// - Parameters:
    ///   - x: Parameter description
    ///   - y: Parameter description
    /// - Returns: Double
    private func distanceBtwTwoPoints(x: Double, y: Double) -> Double{
        return sqrt(pow((x), 2) + pow((y), 2))
    }
    
    /// Distance btw two c g points.
    /// - Parameters:
    ///   - swCGPoint: Parameter description
    ///   - neCGPoint: Parameter description
    /// - Returns: Double
    private func distanceBtwTwoCGPoints(swCGPoint: CGPoint, neCGPoint: CGPoint) -> Double{
        return sqrt(pow((swCGPoint.x - neCGPoint.x), 2) + pow((swCGPoint.y - neCGPoint.y), 2))
    }
    
    /// Get center from two coords.
    /// - Parameters:
    ///   - sw: Parameter description
    ///   - ne: Parameter description
    /// - Returns: CLLocationCoordinate2D
    private func getCenterFromTwoCoords(sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D) -> CLLocationCoordinate2D{
        let centerLat = sw.latitude - (sw.latitude - ne.latitude) / 2
        let centerLon = sw.longitude + (ne.longitude - sw.longitude) / 2
        return CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
    }
    
    /// Set center area.
    /// - Parameters:
    ///   - oriViewArea: Parameter description
    ///   - withGeoBounds: Parameter description
    ///   - mapViewHeight: Parameter description
    ///   - mapViewWidth: Parameter description
    ///   - edgeInset: Parameter description
    ///   - left: Parameter description
    ///   - bottom: Parameter description
    ///   - right: Parameter description
    public func setCenterArea(oriViewArea: ViewArea, withGeoBounds: MGLCoordinateBounds, mapViewHeight: Double, mapViewWidth: Double, edgeInset:UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom:0, right: 0)){
        let viewArea = oriViewArea
        
        //Define the mapView center and distance across the region
        let mapViewCenterX = mapViewWidth / 2
        let mapViewCenterY = mapViewHeight / 2
        let mapViewDistance = distanceBtwTwoPoints(x: mapViewWidth, y: mapViewHeight)
        
        //Define the view area's bounds, center, and distance across the area
        let viewBoundsHeight = viewArea.bottomLeft.y - viewArea.topRight.y
        let viewBoundsWidth = viewArea.topRight.x - viewArea.bottomLeft.x
        let viewBoundsCenterX = viewArea.bottomLeft.x + (viewArea.topRight.x - viewArea.bottomLeft.x) / 2
        let viewBoundsCenterY = viewArea.topRight.y + (viewArea.bottomLeft.y - viewArea.topRight.y) / 2
        let viewBoundsDistance = distanceBtwTwoPoints(x: viewBoundsWidth, y: viewBoundsHeight)
        
        DispatchQueue.main.async {
            let routeBounds = withGeoBounds
            //Retrieve the bounds and center of plotted area
            let sw = CLLocationCoordinate2DMake(routeBounds.sw.latitude, routeBounds.sw.longitude)
            let ne = CLLocationCoordinate2DMake(routeBounds.ne.latitude, routeBounds.ne.longitude)
            let plotCenter = self.getCenterFromTwoCoords(sw: sw, ne: ne)
            
            
            let referenceTopRight = CGPoint(x: mapViewWidth, y: 0)
            let referenceBottomLeft = CGPoint(x: 0, y: mapViewHeight)
            
            //calculate the center of the plotted area
            let camera = MapManager.shared.mapView.camera(MapManager.shared.mapView.camera, fitting: routeBounds, edgePadding: edgeInset)
            self.mapView.setCamera(camera, animated: false)
            self.mapView.setCenter(plotCenter, animated: false)
            
            //calculate the reference center and distance after moving the camera
            let referenceTopRightCoord = self.mapView.convert(referenceTopRight, toCoordinateFrom: nil)
            let referenceBottomLeftCoord = self.mapView.convert(referenceBottomLeft, toCoordinateFrom: nil)
            let refCenter = self.getCenterFromTwoCoords(sw: referenceBottomLeftCoord, ne: referenceTopRightCoord)
            let referenceDistance = self.distanceBtwTwoCoords(topRight: referenceTopRightCoord, bottomLeft: referenceBottomLeftCoord)
            
            
            //resize the plotted area
            let swCGPoint = self.mapView.convert(sw, toPointTo: nil)
            let neCGPoint = self.mapView.convert(ne, toPointTo: nil)
            let distance = self.distanceBtwTwoCGPoints(swCGPoint: swCGPoint, neCGPoint: neCGPoint)
            
            //calculate the final bounds based on ratio between reference bounds and view bounds
            let distanceRatio = distance / mapViewDistance
            let areaRatio: Double = viewBoundsDistance / mapViewDistance
            let differenceRatio = distanceRatio / areaRatio
            let finalCoordLength = differenceRatio * referenceDistance / 2
            let finalNewNE = CLLocationCoordinate2D(latitude: refCenter.latitude + finalCoordLength , longitude: refCenter.longitude + finalCoordLength)
            let finalNewSW = CLLocationCoordinate2D(latitude: refCenter.latitude - finalCoordLength , longitude: refCenter.longitude - finalCoordLength)
            let finalPlotBound = MGLCoordinateBounds(sw: finalNewSW, ne: finalNewNE)
            let finalBoundsCamera = MapManager.shared.mapView.camera(MapManager.shared.mapView.camera, fitting: finalPlotBound, edgePadding: edgeInset)
            self.mapView.setCamera(finalBoundsCamera, animated: false)
            self.mapView.setCenter(plotCenter, animated: false)
            
            
            //move the plotted area to view area (reverse calculation)
            let upTopRightY: CGFloat = mapViewHeight / 2 - viewBoundsHeight
            let downTopRightY: CGFloat = mapViewHeight - viewBoundsHeight
            let upBottomLeftY: CGFloat = mapViewHeight / 2
            let downBottomLeftY: CGFloat = mapViewHeight
            var trY: CGFloat = upTopRightY
            var blY: CGFloat = upBottomLeftY
            if viewBoundsCenterY < mapViewCenterY {
                trY = downTopRightY
                blY = downBottomLeftY
            }
            let newTopRight = CGPoint(x: viewArea.topRight.x, y: trY)
            let newBottomLeft = CGPoint(x: viewArea.bottomLeft.x, y: blY)
            let newViewArea = ViewArea(topRight: newTopRight, bottomLeft: newBottomLeft)
            
            //calculate the center of the view area
            let viewCenterX = newViewArea.bottomLeft.x + (newViewArea.topRight.x - newViewArea.bottomLeft.x) / 2
            let viewCenterY = newViewArea.topRight.y + (newViewArea.bottomLeft.y - newViewArea.topRight.y) / 2
            let viewCenter = CGPoint(x: viewCenterX, y: viewCenterY)
            
            //convert view center to coordinates
            let viewCenterCoord = self.mapView.convert(viewCenter, toCoordinateFrom: nil)
            let viewSW = self.mapView.convert(newViewArea.bottomLeft, toCoordinateFrom: nil)
            let viewNE = self.mapView.convert(newViewArea.topRight, toCoordinateFrom: nil)
            let viewBounds = MGLCoordinateBounds(sw: viewSW, ne: viewNE)
            
            let newViewCamera = MapManager.shared.mapView.camera(MapManager.shared.mapView.camera, fitting: viewBounds, edgePadding: edgeInset)
            self.mapView.setCamera(newViewCamera, animated: false)
            self.mapView.setCenter(viewCenterCoord, animated: false)
            
        }
    }
    
    /// Set center area.
    /// - Parameters:
    ///   - viewArea: Parameter description
    ///   - mapViewHeight: Parameter description
    ///   - mapViewWidth: Parameter description
    ///   - edgeInset: Parameter description
    ///   - left: Parameter description
    ///   - bottom: Parameter description
    ///   - right: Parameter description
    public func setCenterArea(viewArea: ViewArea, mapViewHeight: Double, mapViewWidth: Double, edgeInset:UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom:0, right: 0)){
        if let routeBounds = self.routeBounds {
            setCenterArea(oriViewArea: viewArea, withGeoBounds: routeBounds, mapViewHeight: mapViewHeight, mapViewWidth: mapViewWidth, edgeInset: edgeInset)
        }
    }
    
    /// Center cooridnate in deep level.
    /// - Parameters:
    ///   - location: Parameter description
    ///   - zoomLevel: Parameter description
    ///   - withDelay: Parameter description
    public func centerCooridnateInDeepLevel(location: CLLocationCoordinate2D, zoomLevel: Double = 16, withDelay: Double? = 1.5){
        DispatchQueue.main.asyncAfter(deadline: .now() + (withDelay ?? 0)) {
            self.mapView.setCenter(location, zoomLevel: zoomLevel, animated: true)
        }
    }
    
    /// Add simulated location.
    /// - Parameters:
    ///   - coordinate: Parameter description
    /// Adds simulated location.
    public func addSimulatedLocation(coordinate: CLLocationCoordinate2D){
        simulatedUserLocationMarker = MGLGeneralAnnotation(title: "", coordinate: coordinate)
        simulatedUserLocationMarker.markerType = .simulatedUserLocation
        var modeImage = "ic_saved"
        simulatedUserLocationMarker.imageName = modeImage
        mapView.addAnnotation(simulatedUserLocationMarker)
    }
    
    /// Remove simulated location
    /// Removes simulated location.
    public func removeSimulatedLocation(){
        mapView.removeAnnotation(simulatedUserLocationMarker)
    }
    
    /// This function is used to render the marker in map base on the StopMarker
    /// Adds stop marker.
    /// - Parameters:
    ///   - coordinates: CLLocationCoordinate2D
    public func addStopMarker(coordinates: CLLocationCoordinate2D){
        stopMarker = MGLGeneralAnnotation(title: "", coordinate: coordinates)
        stopMarker.markerType = .busStopMarker
        var modeImage = "ic_marker_bus"
        let origin = StopViewerViewModel.shared.pubStopViewerOrigin ?? .map
        
        switch origin {
        case .tripDetail:
            if let selectedLeg = StopViewerViewModel.shared.itineraryStop{
                modeImage = ModeManager.shared.getImageIconforSearchRoute(leg: selectedLeg, type: .marker)
            }
            break
        case .route:
            if let selectedRoute = RouteManager.shared.selectedRoute, let mode = selectedRoute.searchMode{
                modeImage = mode.marker_image
            }
            break
        case .map:
            if let seletedStopMode = StopViewerViewModel.shared.pubSelectedStopMode {
                modeImage = seletedStopMode.marker_image
            }
            break
        case .stopViewer:
            break
        }
        
        stopMarker.imageName = modeImage
        
        mapView.addAnnotation(stopMarker)
    }
    
    /// Re draw from to markers
    /// Re draw from to markers.
    public func reDrawFromToMarkers(){
        if let annotationsInMap = mapView.annotations {
            for annotation in annotationsInMap {
                mapView.deselectAnnotation(annotation, animated: false)
            }
        }
        if let annotations = mapView.annotations {
            mapView.removeAnnotations(annotations)
        }
        if SearchManager.shared.from != nil{
            if let location = SearchManager.shared.from?.geometry?.coordinate{
                MapManager.shared.previewFromMarker(coordinates: location, withDelay: 0)
            }
        }
        if SearchManager.shared.to != nil{
            if let location = SearchManager.shared.to?.geometry?.coordinate{
                MapManager.shared.previewToMarker(coordinates: location, withDelay: 0)
            }
        }
    }
    
    /// De select annotations
    /// De select annotations.
    public func deSelectAnnotations(){
        if let annotations = MapManager.shared.mapView.annotations {
            for annotation in annotations {
                mapView.deselectAnnotation(annotation, animated: false)
            }
            mapView.removeAnnotations(annotations)
        }
    }
    
    /// Force clean map re draw route
    /// Force clean map re draw route.
    public func forceCleanMapReDrawRoute(){
        cleanPlotRoute()
        if mapView != nil {
            if let annotationsInMap = mapView.annotations {
                for annotation in annotationsInMap {
                    mapView.deselectAnnotation(annotation, animated: false)
                }
            }
            if let annotations = mapView.annotations {
                mapView.removeAnnotations(annotations)
            }
            DispatchQueue.main.async {
                if (TabBarMenuManager.shared.currentItemTab == .planTrip){
                    if let tripPlanItem = TripPlanningManager.shared.pubSelectedItinerary{
                        TripPlanningManager.shared.didSelectItem(tripPlanItem)
                    }
                }
                else{
                    if let directionGeoData = RouteManager.shared.selectedDirectionLegGeoData, let route = RouteManager.shared.selectedRoute{
                        RouteManager.shared.showGeoRouteOnMap(geoPoints: directionGeoData, route: route)
                    }
                }
            }
        }else{
            return
        }
    }
    
    
    /// Do preview from marker.
    /// - Parameters:
    ///   - coordinates: Parameter description
    public func doPreviewFromMarker(coordinates: Coordinate){
        if let _ = fromMarker { self.removePreviewFromMarker() }
        let location = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
        fromMarker = MGLGeneralAnnotation(title: "", coordinate: location)
        fromMarker?.markerType = .previewFromMarker
        fromMarker?.imageName = "ic_origin"
        if let fromMarker = fromMarker {
            mapView.addAnnotation(fromMarker)
            let viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:Helper.shared.getDefaultMapViewHeight()/2), bottomLeft: CGPoint(x:0, y:Helper.shared.getDefaultMapViewHeight()))
            let geoBounds = self.getGeoBoundsForFromToMarker()
            MapManager.shared.setCenterArea(oriViewArea: viewArea, withGeoBounds: geoBounds, mapViewHeight: Helper.shared.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width)
        }
    }
    
    /// This function is used to render the marker in map base on the Start and Destination location
    /// Preview from marker.
    /// - Parameters:
    ///   - coordinates: Coordinate
    ///   - withDelay: Double = 0.3
    public func previewFromMarker(coordinates: Coordinate, withDelay: Double = 0.3){
        if(withDelay == 0){
            doPreviewFromMarker(coordinates: coordinates)
        }else{
            DispatchQueue.main.asyncAfter(deadline: .now() + withDelay) {
                self.doPreviewFromMarker(coordinates: coordinates)
            }
        }
    }
    
    /// Do preview to marker.
    /// - Parameters:
    ///   - coordinates: Parameter description
    public func doPreviewToMarker(coordinates: Coordinate){
        if let _ = toMarker {self.removePreviewToMarker() }
        let location = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
        toMarker = MGLGeneralAnnotation(title: "", coordinate: location)
        toMarker?.markerType = .previewToMarker
        toMarker?.imageName = "ic_destination"
        if let toMarker = toMarker {
            mapView.addAnnotation(toMarker)
            let viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:Helper.shared.getDefaultMapViewHeight()/2), bottomLeft: CGPoint(x:0, y:Helper.shared.getDefaultMapViewHeight()))
            let geoBounds = self.getGeoBoundsForFromToMarker()
            MapManager.shared.setCenterArea(oriViewArea: viewArea, withGeoBounds: geoBounds, mapViewHeight: Helper.shared.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width)
        }
    }
    
    /// Preview to marker.
    /// - Parameters:
    ///   - coordinates: Parameter description
    ///   - withDelay: Parameter description
    public func previewToMarker(coordinates: Coordinate, withDelay: Double = 0.5){
        if(withDelay == 0){
            doPreviewToMarker(coordinates: coordinates)
        }else{
            DispatchQueue.main.asyncAfter(deadline: .now() + withDelay) {
                self.doPreviewToMarker(coordinates: coordinates)
            }
        }
    }
    
    /// Render route direction stop marker.
    /// - Parameters:
    ///   - stops: Parameter description
    /// Renders route direction stop marker.
    public func renderRouteDirectionStopMarker(stops: [Stop]){
        for stop in stops{
            let coordinate = CLLocationCoordinate2D(latitude: stop.lat, longitude: stop.lon)
            let marker = MGLGeneralAnnotation(title: "", coordinate: coordinate)
            marker.markerType = .directionStopMarker
            marker.imageName = "bus_stop_white"
            mapView.addAnnotation(marker)
        }
    }
    
    // radius is in km
    /// Retrieves geo bounds for single point.
    /// - Parameters:
    ///   - point: CLLocationCoordinate2D
    ///   - radius: Double
    /// - Returns: MGLCoordinateBounds
    private func getGeoBoundsForSinglePoint(point: CLLocationCoordinate2D ,radius: Double) -> MGLCoordinateBounds{
        let RADIUS_EARTH:Double = 6371 // in km
        let latitudeNE = point.latitude + CLLocationDegrees(radius / RADIUS_EARTH)
        let longitudeNE = point.longitude + CLLocationDegrees(radius / RADIUS_EARTH / (cos(point.latitude) * .pi / 180))
        let latitudeSW = point.latitude - CLLocationDegrees(radius / RADIUS_EARTH)
        let longitudeSW = point.longitude - CLLocationDegrees(radius / RADIUS_EARTH / (cos(point.latitude) * .pi / 180))
        let sw = CLLocationCoordinate2D(latitude: latitudeSW, longitude: longitudeSW)
        let ne = CLLocationCoordinate2D(latitude: latitudeNE, longitude: longitudeNE)
        return MGLCoordinateBounds(sw: sw, ne: ne)
    }
    
    /// Get geo bounds for from to marker
    /// - Returns: MGLCoordinateBounds
    /// Retrieves geo bounds for from to marker.
    private func getGeoBoundsForFromToMarker() -> MGLCoordinateBounds{
        var coordinates = [CLLocationCoordinate2D]()
        var topRightLat: Double = 0
        var topRightLon: Double = 0
        var bottomLeftLat: Double = 0
        var bottomLeftLon: Double = 0
        
        if let fromMarker = fromMarker {
            coordinates.append(fromMarker.coordinate)
        }
        
        if let toMarker = toMarker {
            coordinates.append(toMarker.coordinate)
        }
        
        if coordinates.count > 1 {
            for coordinate in coordinates {
                if bottomLeftLat == 0 { bottomLeftLat = coordinate.latitude }
                if bottomLeftLon == 0 { bottomLeftLon = coordinate.longitude }
                if topRightLat == 0 { topRightLat = coordinate.latitude }
                if topRightLon == 0 { topRightLon = coordinate.longitude }
                
                if bottomLeftLat > coordinate.latitude {bottomLeftLat = coordinate.latitude}
                if bottomLeftLon > coordinate.longitude {bottomLeftLon = coordinate.longitude}
                if topRightLat < coordinate.latitude {topRightLat = coordinate.latitude}
                if topRightLon < coordinate.longitude {topRightLon = coordinate.longitude}
            }
            
            let sw = CLLocationCoordinate2D(latitude: bottomLeftLat, longitude: bottomLeftLon)
            let ne = CLLocationCoordinate2D(latitude: topRightLat, longitude: topRightLon)
            
            return MGLCoordinateBounds(sw: sw, ne: ne)
        }else{
            return getGeoBoundsForSinglePoint(point: coordinates[0], radius: 1.5)
        }
    }
    
    /// Remove stop marker
    /// Removes stop marker.
    public func removeStopMarker(){
        mapView.removeAnnotation(stopMarker)
    }
    
    /// Remove tap map callout marker
    /// Removes tap map callout marker.
    public func removeTapMapCalloutMarker(){
        mapView.removeAnnotation(tapMapCalloutMarker)
    }
    
    /// Remove preview markers
    /// Removes preview markers.
    public func removePreviewMarkers() {
        removePreviewFromMarker()
        removePreviewToMarker()
    }
    
    /// Remove preview from marker
    /// Removes preview from marker.
    public func removePreviewFromMarker(){
        if let fromMarker = fromMarker {
            mapView.removeAnnotation(fromMarker)
            self.fromMarker = nil
        }
        
    }
    
    /// Remove preview to marker
    /// Removes preview to marker.
    public func removePreviewToMarker(){
        if let toMarker = toMarker {
            mapView.removeAnnotation(toMarker)
            self.toMarker = nil
        }
    }
    
    /// Controls whether the user's current location puck is visible on the map.
    public func setUserLocationPuckVisible(_ isVisible: Bool) {
        pubShowUsersCurrentLocation = isVisible
        DispatchQueue.main.async {
            self.mapView.showsUserLocation = isVisible
        }
    }
    
    /// This function is used to render the marker in map base on the existing store
    /// Renders marker in map.
    /// - Parameters:
    ///   - withoutMarkers: Bool = false
    public func renderMarkerInMap(withoutMarkers: Bool = false) {
        DispatchQueue.main.async { [weak self ] in
            guard let self = self else { return }
            self.markersLock.sync {
                
                if self.mapMarkers.count > 0 {
                    
                    // prepare valid marker layers
                    var markersToRender = [MGLGeneralAnnotation]()
                    var layerStatus = [MarkerType: Bool]()
                    
                    for layer in self.layers {
                        layerStatus[layer.type] = layer.isSelected
                        if layer.type == .sharedScootersStop && layer.isSelected {
                            layerStatus[.sharedBikeStop] = layer.isSelected
                        }
                    }
                    if !self.mapMarkers.isEmpty {
                        for marker in self.mapMarkers {
                            if let markerType = marker.markerType, let isSelected = layerStatus[markerType], isSelected {
                                markersToRender.append(marker)
                            }
                        }
                    }
                    // MARK: Updated for Polyline
                    let markerItems = GraphQLMapPlotItem(annotations: markersToRender, overlays: nil)
                    self.preMapMarkers = self.plotAnnotations?.annotations ?? [MGLGeneralAnnotation]()
                    self.plotAnnotations = markerItems
                }
                
                // add new annotations if needed
                if self.routeMarkers.count > 0 || withoutMarkers {
                    let routeItem = GraphQLMapPlotItem(annotations: self.routeMarkers, overlays: self.segmentRoutePolylines)
                    self.graphQLPlotRouteItem = routeItem
                }
                
            }
        }
    }
    
    /// Layer status.
    /// - Parameters:
    ///   - layerName: Parameter description
    /// - Returns: Bool
    private func layerStatus(layerName: String) -> Bool {
        for layer in self.layers {
            if layer.name == layerName {
                return layer.isSelected
            }
        }
        return false
    }
    
    /// Layer status.
    /// - Parameters:
    ///   - layerType: Parameter description
    /// - Returns: Bool
    private func layerStatus(layerType: MarkerType) -> Bool {
        for layer in self.layers {
            if layer.type == .sharedScootersStop && layerType == .sharedBikeStop {
                return layer.isSelected
            }
            if layer.type == layerType {
                return layer.isSelected
            }
        }
        return false
    }
    
    /// Plot route.
    /// - Parameters:
    ///   - segments: Parameter description
    ///   - origin: Parameter description
    ///   - destination: Parameter description
    ///   - specialRoutePoint: Parameter description
    public func plotRoute(segments: [RouteSegment], origin: CLLocationCoordinate2D? = nil, destination: CLLocationCoordinate2D? = nil, specialRoutePoint: [RouteSpecialPoint]? = nil){
        
        // Invalid polyline, no need to plot the route
        if segments.count <= 0 {
            return
        }
        
        // Prepare the annotations
        var annotations = [MGLGeneralAnnotation]()
        if let _ = origin {
            let startCoordinates = segments[0].coorindates[0]
            let startPin = MGLGeneralAnnotation(title: "", coordinate: startCoordinates)
            startPin.markerType = .markerInRouteForFrom
            startPin.imageName = MGLMap.routeStartMarker
            annotations.append(startPin)
        }
        
        if let _ = destination {
            let endCoordinates = segments[segments.count - 1].coorindates[segments[segments.count - 1].coorindates.count - 1]
            let endPin = MGLGeneralAnnotation(title: "", coordinate: endCoordinates)
            endPin.markerType = .markerInRouteForTo
            endPin.imageName = MGLMap.routeEndMarker
            annotations.append(endPin)
        }
        
        // prepare special points if we have
        if let specialRoutePoint = specialRoutePoint {
            for point in specialRoutePoint {
                let pin = MGLGeneralAnnotation(title: "", coordinate: point.coordinate)
                pin.markerType = .specialMarkerInRoute
                pin.imageName = MGLMap.busStopMarker
                pin.info = point.info
                pin.fillColor = point.color
                annotations.append(pin)
            }
        }
        
        var bottomLeftLatitude: Double = 0
        var bottomLeftLongitude: Double = 0
        var topRightLatitude: Double = 0
        var topRightLongitude: Double = 0
        
        
        // Prepare the route coordinate
        // MARK: Updated for Polyline
        var polylines = [GraphQLMGLGeneralPolyline]()
        
        // calculate the boundary
        for segment in segments {
            
            for coordinate in segment.coorindates {
                // For Bounds
                if bottomLeftLatitude == 0 { bottomLeftLatitude = coordinate.latitude }
                if bottomLeftLongitude == 0 { bottomLeftLongitude = coordinate.longitude }
                if topRightLatitude == 0 { topRightLatitude = coordinate.latitude }
                if topRightLongitude == 0 { topRightLongitude = coordinate.longitude }
                
                if bottomLeftLatitude > coordinate.latitude {bottomLeftLatitude = coordinate.latitude}
                if bottomLeftLongitude < coordinate.longitude {bottomLeftLongitude = coordinate.longitude}
                if topRightLatitude < coordinate.latitude {topRightLatitude = coordinate.latitude}
                if topRightLongitude > coordinate.longitude {topRightLongitude = coordinate.longitude}
            }
            // MARK: Updated for Polyline
            let polyline = GraphQLMGLGeneralPolyline(coordinates: segment.coorindates, count: UInt(segment.coorindates.count))
            polyline.routeType = segment.routeType.rawValue
            polyline.color = segment.routeColor
            polylines.append(polyline)
        }
        
        
        let sw = CLLocationCoordinate2DMake(bottomLeftLatitude, bottomLeftLongitude)
        let ne = CLLocationCoordinate2DMake(topRightLatitude, topRightLongitude)
        routeBounds = MGLCoordinateBounds(sw: sw, ne: ne)
        
        self.routeMarkers.removeAll()
        if annotations.count > 0 {
            self.routeMarkers.append(contentsOf:annotations)
        }
        
        self.segmentRoutePolylines.removeAll()
        self.segmentRoutePolylines.append(contentsOf:polylines)
        
        self.renderMarkerInMap(withoutMarkers: (annotations.count == 0))
        
        reCenterRouteBounds()
        
    }
    
    /// Graph q l plot route.
    /// - Parameters:
    ///   - segments: Parameter description
    ///   - origin: Parameter description
    ///   - destination: Parameter description
    ///   - specialRoutePoint: Parameter description
    public func graphQLPlotRoute(segments: [GraphQLRouteSegment], origin: CLLocationCoordinate2D? = nil, destination: CLLocationCoordinate2D? = nil, specialRoutePoint: [GraphQLRouteSpecialPoint]? = nil){
        
        // Invalid polyline, no need to plot the route
        if segments.count <= 0 {
            return
        }
        
        // Prepare the annotations
        var annotations = [MGLGeneralAnnotation]()
        if let _ = origin {
            let startCoordinates = segments[0].coorindates[0]
            let startPin = MGLGeneralAnnotation(title: "", coordinate: startCoordinates)
            startPin.markerType = .markerInRouteForFrom
            startPin.imageName = MGLMap.routeStartMarker
            annotations.append(startPin)
        }
        
        if let _ = destination {
            let endCoordinates = segments[segments.count - 1].coorindates[segments[segments.count - 1].coorindates.count - 1]
            let endPin = MGLGeneralAnnotation(title: "", coordinate: endCoordinates)
            endPin.markerType = .markerInRouteForTo
            endPin.imageName = MGLMap.routeEndMarker
            annotations.append(endPin)
        }
        
        // prepare special points if we have
        if let specialRoutePoint = specialRoutePoint {
            for point in specialRoutePoint {
                let pin = MGLGeneralAnnotation(title: "", coordinate: point.coordinate)
                pin.markerType = .specialMarkerInRoute
                pin.imageName = MGLMap.busStopMarker
                pin.info = point.info
                pin.fillColor = point.color
                annotations.append(pin)
            }
        }
        
        var bottomLeftLatitude: Double = 0
        var bottomLeftLongitude: Double = 0
        var topRightLatitude: Double = 0
        var topRightLongitude: Double = 0
        
        
        // Prepare the route coordinate
        var graphQLPolylines = [GraphQLMGLGeneralPolyline]()
        
        // calculate the boundary
        for segment in segments {
            
            for coordinate in segment.coorindates {
                // For Bounds
                if bottomLeftLatitude == 0 { bottomLeftLatitude = coordinate.latitude }
                if bottomLeftLongitude == 0 { bottomLeftLongitude = coordinate.longitude }
                if topRightLatitude == 0 { topRightLatitude = coordinate.latitude }
                if topRightLongitude == 0 { topRightLongitude = coordinate.longitude }
                
                if bottomLeftLatitude > coordinate.latitude {bottomLeftLatitude = coordinate.latitude}
                if bottomLeftLongitude < coordinate.longitude {bottomLeftLongitude = coordinate.longitude}
                if topRightLatitude < coordinate.latitude {topRightLatitude = coordinate.latitude}
                if topRightLongitude > coordinate.longitude {topRightLongitude = coordinate.longitude}
            }
            
            let polyline = GraphQLMGLGeneralPolyline(coordinates: segment.coorindates, count: UInt(segment.coorindates.count))
            polyline.routeType = segment.routeType
            polyline.color = segment.routeColor
            graphQLPolylines.append(polyline)
        }
        
        
        let sw = CLLocationCoordinate2DMake(bottomLeftLatitude, bottomLeftLongitude)
        let ne = CLLocationCoordinate2DMake(topRightLatitude, topRightLongitude)
        routeBounds = MGLCoordinateBounds(sw: sw, ne: ne)
        
        self.routeMarkers.removeAll()
        if annotations.count > 0 {
            self.routeMarkers.append(contentsOf:annotations)
        }
        
        self.segmentRoutePolylines.removeAll()
        self.segmentRoutePolylines.append(contentsOf: graphQLPolylines)
        
        self.renderMarkerInMap(withoutMarkers: (annotations.count == 0))
        
        reCenterRouteBounds()
        
    }
    
    /// Re center route bounds
    /// Re center route bounds.
    public func reCenterRouteBounds(){
        if let routeBounds = self.routeBounds {
            DispatchQueue.main.async {
                /// Top: 60, left: 60, bottom: 60, right:60), animated: true, completion handler: nil
                /// Initializes a new instance.
                /// - Parameters:
                ///   - edgePadding: .init(top: 60, left: 60, bottom: 60, right:60
                self.mapView.setVisibleCoordinateBounds(routeBounds, edgePadding: .init(top: 60, left: 60, bottom: 60, right:60), animated: true, completionHandler: nil)
            }
        }
    }
    
    /// Re center route bounds to bottom
    /// Re center route bounds to bottom.
    public func reCenterRouteBoundsToBottom(){
        if let routeBounds = self.routeBounds {
            
        }
    }
    
    
    /// Remove markers in data source.
    /// - Parameters:
    ///   - _: Parameter description
    public func removeMarkersInDataSource(_ type: MarkerType){
        let markers = self.mapMarkers
        var annotationToRemove = [MGLGeneralAnnotation]()
        for marker in markers {
            if let markerType = marker.markerType, markerType == type {
                annotationToRemove.append(marker)
            }
        }
        if annotationToRemove.count > 0 {
            self.mapView.removeAnnotations(annotationToRemove)
        }
    }
    
    /// Remove shared vehicles markers in data source.
    /// - Parameters:
    ///   - _: Parameter description
    public func removeSharedVehiclesMarkersInDataSource(_ type: MarkerType, _ markers: [MGLGeneralAnnotation]){
        var annotationToRemove = [MGLGeneralAnnotation]()
        for marker in markers {
            if let markerType = marker.markerType, markerType == type {
                annotationToRemove.append(marker)
            }
        }
        if annotationToRemove.count > 0 {
            self.mapView.removeAnnotations(annotationToRemove)
        }
    }
    
    /// Remove annotation layer.
    /// - Parameters:
    ///   - layerName: Parameter description
    /// Removes annotation layer.
    public func removeAnnotationLayer(layerName: String){
        
        for identifier in self.styleAnnotationLayerIdentifiers {
            if identifier.contains(layerName) {
                if let layer = self.mapView.style?.layer(withIdentifier: identifier){
                    self.mapView.style?.removeLayer(layer)
                }
            }
        }
        self.styleAnnotationLayerIdentifiers.removeAll(where: {$0.contains(layerName)})
        
        for identifier in self.styleAnnotationSourceIdentifiers {
            if identifier.contains(layerName) {
                if let source = self.mapView.style?.source(withIdentifier: identifier){
                    self.mapView.style?.removeSource(source)
                }
            }
        }
        self.styleAnnotationSourceIdentifiers.removeAll(where: {$0.contains(layerName)})
        
    }
    
    /// Remove route layer
    /// Removes route layer.
    private func removeRouteLayer(){
        
        for identifier in self.styleRouteLayerIdentifiers {
            if let layer = self.mapView.style?.layer(withIdentifier: identifier){
                self.mapView.style?.removeLayer(layer)
            }
        }
        
        self.styleRouteLayerIdentifiers.removeAll()
        
        for identifier in self.styleRouteSourceIdentifiers {
            if let source = self.mapView.style?.source(withIdentifier: identifier){
                self.mapView.style?.removeSource(source)
            }
        }
        
        self.styleRouteSourceIdentifiers.removeAll()
        
    }
    
    /// Draw annotations.
    /// - Parameters:
    ///   - allFeatures: Parameter description
    /// Draws annotations.
    public func drawAnnotations(allFeatures: [MGLPointFeature]) {
        
        guard let style = self.mapView.style else { return }
        
        var featuresSet = [String: [MGLPointFeature]]()
        var featureImageNameSet = [String: String]()
        var featureImageResizeSet = [String: CGFloat]()
        var featureValidLevelSet = [String: Double]()
        for pointFeature in allFeatures {
            if let markerType = pointFeature.attributes["markerType"] as? String {
                if let _ = featuresSet[markerType] {
                    featuresSet[markerType]?.append(pointFeature)
                }else{
                    featuresSet[markerType] = [MGLPointFeature]()
                    featuresSet[markerType]?.append(pointFeature)
                }
                featureImageNameSet[markerType] = pointFeature.attributes["imageName"] as? String ?? ""
                featureImageResizeSet[markerType] = pointFeature.attributes["resize"] as? CGFloat ?? 20.0
                featureValidLevelSet[markerType] = pointFeature.attributes["validLevel"] as? Double ?? 0.0
            }
        }
        
        for key in featuresSet.keys{
            
            guard let features = featuresSet[key], let imageName = featureImageNameSet[key], let resize = featureImageResizeSet[key], let validLevel = featureValidLevelSet[key] else {
                assertionFailure("can not find proper key for the feature")
                continue
            }
            
            let  icon = UIImage(named: imageName)?.resizeImage(resize, resize).withRenderingMode(.alwaysOriginal) ?? UIImage()
            
            if let type = MarkerType(rawValue: key), layerStatus(layerType: type){}else{ continue }
            if self.mapView.zoomLevel < validLevel { continue }
            
            let timestamp = Date().timeIntervalSince1970
            let typeIdentifier = key
            let source = MGLShapeSource(identifier: "clusteredFeatures-\(typeIdentifier)-\(timestamp)", features: features, options: [.clustered: false, .clusterRadius: 10])
            style.addSource(source)
            style.setImage(icon, forName: key)
            self.styleAnnotationSourceIdentifiers.append("clusteredFeatures-\(typeIdentifier)-\(timestamp)")
            
            let annotationLayer = MGLSymbolStyleLayer(identifier: "annotationLayer-\(typeIdentifier)-\(timestamp)", source: source)
            annotationLayer.iconImageName = NSExpression(forConstantValue: key)
            annotationLayer.iconColor = NSExpression(forConstantValue: UIColor.darkGray.withAlphaComponent(0.9))
            annotationLayer.predicate = NSPredicate(format: "cluster != YES")
            annotationLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
            let segementLevels = self.segmentRoutePolylines.count>0 ? self.segmentRoutePolylines.count : 3
            let index = style.layers.count-segementLevels > 0 ? style.layers.count-segementLevels : 0
            style.insertLayer(annotationLayer, at: (UInt)(index))
            self.styleAnnotationLayerIdentifiers.append("annotationLayer-\(typeIdentifier)-\(timestamp)")
            
            let stops = [20: UIColor.lightGray,50: UIColor.orange,100: UIColor.red,200: UIColor.purple]
            
            let circlesLayer = MGLCircleStyleLayer(identifier: "clusteredFeatures-\(typeIdentifier)-\(timestamp)", source: source)
            circlesLayer.circleRadius = NSExpression(forConstantValue: NSNumber(value: Double(icon.size.width) / 2))
            circlesLayer.circleOpacity = NSExpression(forConstantValue: 0.75)
            circlesLayer.circleStrokeColor = NSExpression(forConstantValue: UIColor.white.withAlphaComponent(0.75))
            circlesLayer.circleStrokeWidth = NSExpression(forConstantValue: 2)
            circlesLayer.circleColor = NSExpression(format: "mgl_step:from:stops:(point_count, %@, %@)", UIColor.lightGray, stops)
            circlesLayer.predicate = NSPredicate(format: "cluster == YES")
            style.addLayer(circlesLayer)
            self.styleAnnotationLayerIdentifiers.append("clusteredFeatures-\(typeIdentifier)-\(timestamp)")
            
            let numbersLayer = MGLSymbolStyleLayer(identifier: "clusteredFeatureNumbers-\(typeIdentifier)-\(timestamp)", source: source)
            numbersLayer.textColor = NSExpression(forConstantValue: UIColor.white)
            numbersLayer.textFontSize = NSExpression(forConstantValue: NSNumber(value: Double(icon.size.width) / 2))
            numbersLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
            numbersLayer.text = NSExpression(format: "CAST(point_count, 'NSString')")
            
            numbersLayer.predicate = NSPredicate(format: "cluster == YES")
            style.addLayer(numbersLayer)
            self.styleAnnotationLayerIdentifiers.append("clusteredFeatureNumbers-\(typeIdentifier)-\(timestamp)")
        }
    }
    
    /// Draw polyline.
    /// - Parameters:
    ///   - polylines: Parameter description
    /// Draws polyline.
    private func drawPolyline(polylines: [GraphQLMGLGeneralPolyline]){
        guard let style = self.mapView.style else { return }

        var idx:Double = 0
        let timestamp: Double = Date().timeIntervalSince1970
        for polyline in polylines {
            idx += 1
            
            let sourceIdentifier = "line-\(timestamp + idx)"
            let source = MGLShapeSource(identifier: sourceIdentifier, shape: polyline, options: nil)
            style.addSource(source)
            styleRouteSourceIdentifiers.append(sourceIdentifier)
            
            let layerIdentifier = "line-layer-\(timestamp + idx)"
            let layer = MGLLineStyleLayer(identifier: layerIdentifier, source: source)
            layer.lineJoin = NSExpression(forConstantValue: "round")
            layer.lineCap = NSExpression(forConstantValue: "round")
            if TripViewerViewModel.shared.pubIsShowingTripViewer{
                layer.lineColor = NSExpression(forConstantValue: UIColor.polylineOverlay)
                layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",[14: 8, 18: 10])
                layer.lineOpacity = NSExpression(forConstantValue: 0.7)
            }else{
                layer.lineColor = NSExpression(forConstantValue: polyline.color ?? UIColor.lightGray)
                layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",[14: 3, 18: 10])
            }
            if let markerType = polyline.routeType, markerType != Mode.bus.rawValue, markerType != Mode.subway.rawValue, markerType != Mode.tram.rawValue {
                layer.lineDashPattern = NSExpression(forConstantValue: [3, 1.5])
            }else{
                layer.lineDashPattern = NSExpression(forConstantValue: [3, 0])
            }
            let index = style.layers.count-5 > 0 ? style.layers.count-5 : 0
            style.insertLayer(layer, at: (UInt)(index))
            styleRouteLayerIdentifiers.append(layerIdentifier)
        }
    }
    
    /// Clean plot route
    /// Cleans plot route.
    public func cleanPlotRoute(){
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let item = self.graphQLPlotRouteItem{
                if let annotations = item.annotations {
                    if let annotationsInMap = self.mapView.annotations {
                        for annotation in annotationsInMap {
                            self.mapView.deselectAnnotation(annotation, animated: false)
                        }
                    }
                    self.mapView.removeAnnotations(annotations)
                    self.routeMarkers.removeAll()
                    self.graphQLPlotRouteItem?.annotations?.removeAll()
                    self.graphQLPlotRouteItem?.annotations = nil
                }
                if let _ = item.overlays {
                    self.removeRouteLayer()
                    self.segmentRoutePolylines.removeAll()
                    self.graphQLPlotRouteItem?.overlays?.removeAll()
                    self.graphQLPlotRouteItem?.overlays = nil
                }
            }
        }
    }
    
    /// Switch map view style.
    /// - Parameters:
    ///   - style: Parameter description
    func switchMapViewStyle(style:MapStyle) {
        
        if style == .satellite {
            let satelliteStyleURL = URL(string: "mapbox://styles/jdarton/ckmcej10b3qso17qm1lvnttee")
            self.mapView.styleURL = satelliteStyleURL
        }else {
            let lightUrl = URL(string: "mapbox://styles/mapbox/light-v10")
            self.mapView.styleURL = lightUrl
        }
        DispatchQueue.main.async { [weak self] in
            self?.pubLastMapUpdate = Date().timeIntervalSince1970
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: {
            if let pointFeatures = MapManager.shared.plotAnnotations?.annotations {
                MapManager.shared.drawAnnotations(allFeatures: pointFeatures)
            }
        })
    }
    
    /// From to destionation.
    /// - Parameters:
    ///   - isFrom: Parameter description
    ///   - latitude: Parameter description
    ///   - longitude: Parameter description
    ///   - title: Parameter description
    ///   - completion: Parameter description
    /// - Returns: Void)?)
    func fromToDestionation(isFrom: Bool, latitude: Double, longitude: Double, title: String?, completion:(()->Void)?){
        if isFrom {
            self.fromToDestionationDetail(isFrom: isFrom, latitude: latitude, longitude: longitude, title: title, completion: completion)
        }else{
            if SearchManager.shared.from == nil {
                if let userLocation = MapManager.shared.mapView.userLocation {
                    let from = userLocation.coordinate
                    MapManager.shared.reverseLocation(latitude: from.latitude, longitude: from.longitude, completion: { autoComplete in
                        if let autocomplete = autoComplete, autocomplete.features.count > 0 {
                            if let feature = autocomplete.features.first {
                                SearchManager.shared.from = feature
                                MapFromToViewModel.shared.pubFromString = feature.properties.label
                                MapFromToViewModel.shared.pubFromDisplayString = feature.properties.label
                                self.fromToDestionationDetail(isFrom: isFrom, latitude: latitude, longitude: longitude, title: title, completion: completion)
                            }
                        }
                    })
                }
            }else{
                self.fromToDestionationDetail(isFrom: isFrom, latitude: latitude, longitude: longitude, title: title, completion: completion)
            }
        }
    }
    
    /// From to destionation detail.
    /// - Parameters:
    ///   - isFrom: Parameter description
    ///   - latitude: Parameter description
    ///   - longitude: Parameter description
    ///   - title: Parameter description
    ///   - completion: Parameter description
    /// - Returns: Void)?)
    private func fromToDestionationDetail(isFrom: Bool, latitude: Double, longitude: Double, title: String?, completion:(()->Void)?){
        if MapManager.shared.pubSearchRoute{
            MapManager.shared.pubSearchRoute = false
            MapManager.shared.pubIsInTripPlan = false
            MapManager.shared.pubIsInTripPlanDetail = false
            MapManager.shared.pubHideAddressBar = false
        }
        MapManager.shared.reverseLocation(latitude: latitude, longitude: longitude, completion: { autoComplete in
            if let autocomplete = autoComplete, autocomplete.features.count > 0 {
                if var feature = autocomplete.features.first {
                    if let title = title {
                        feature.properties.label = title
                    }
                    if isFrom {
                        SearchManager.shared.from = feature
                        MapFromToViewModel.shared.pubFromString = feature.properties.label
                        MapFromToViewModel.shared.pubFromDisplayString = feature.properties.label
                    }
                    else {
                        SearchManager.shared.to = feature
                        MapFromToViewModel.shared.pubToString = feature.properties.label
                        MapFromToViewModel.shared.pubToDisplayString = feature.properties.label
                    }
                    DispatchQueue.main.async {
                        MapManager.shared.pubSearchRoute = true
                    }
                }
            }else{
                let stringCoordinates = String(latitude) + " , " + String(longitude)
                if isFrom {
                    SearchManager.shared.from = Autocomplete.Feature(properties: Autocomplete.Properties(id: "", name: "", label: stringCoordinates, gid: "", layer: "", source: "", source_id: "", accuracy: "", modes: [], street: "", neighbourhood: "", locality: "", region_a: "", secondaryLabels: []), geometry: Autocomplete.Geometry(type: "", coordinate: Coordinate(latitude: latitude, longitude: longitude)), id: "")
                    MapFromToViewModel.shared.pubFromString = stringCoordinates
                    MapFromToViewModel.shared.pubFromDisplayString = stringCoordinates
                }
                else {
                    SearchManager.shared.to = Autocomplete.Feature(properties: Autocomplete.Properties(id: "", name: "", label: stringCoordinates, gid: "", layer: "", source: "", source_id: "", accuracy: "", modes: [], street: "", neighbourhood: "", locality: "", region_a: "", secondaryLabels: []), geometry: Autocomplete.Geometry(type: "", coordinate: Coordinate(latitude: latitude, longitude: longitude)), id: "")
                    MapFromToViewModel.shared.pubToString = stringCoordinates
                    MapFromToViewModel.shared.pubToDisplayString = stringCoordinates
                }
                DispatchQueue.main.async {
                    MapManager.shared.pubSearchRoute = true
                }
            }
            
            DispatchQueue.main.async {
                completion?()
            }
        })
    }
    
    /// Reverse location.
    /// - Parameters:
    ///   - latitude: Parameter description
    ///   - longitude: Parameter description
    ///   - completion: Parameter description
    /// - Returns: Void))
    func reverseLocation(latitude: Double, longitude: Double, completion:@escaping ((_ autoComplete : Autocomplete?)->Void)){
        if BrandConfig.shared.app_identifier == "gmap" || BrandConfig.shared.app_identifier == "sound-transit"{
            let cancellable = reverseV2(latitude: latitude, longitude: longitude)
                .sink(receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        OTPLog.log(level: .error, info: "Handle error: \(error)")
                        completion(nil)
                    case .finished:
                        completion(self.autoCompleteResult)
                        break
                    }
                    
                }) { [self] (response) in
                    self.autoCompleteResult = mapResponseToAutoComplete(geoData: response)
                }
            cancellableSet.insert(cancellable)
        }else{
            let cancellable = reverse(latitude: latitude, longitude: longitude)
                .sink(receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        OTPLog.log(level: .error, info: "Handle error: \(error)")
                        completion(nil)
                    case .finished:
                        completion(self.autoCompleteResult)
                        break
                    }
                    
                }) { (response) in
                    self.autoCompleteResult = response
                }
            cancellableSet.insert(cancellable)
        }
    }
    
    // Mapping function to Map reverseLocationV2 resposne to AutoComplete
    /// Map response to auto complete.
    /// - Parameters:
    ///   - geoData: [AutocompleteV2]
    /// - Returns: Autocomplete
    func mapResponseToAutoComplete(geoData: [AutocompleteV2]) -> Autocomplete {
        var features: [Autocomplete.Feature] = []
        for response in geoData {
            let properties = Autocomplete.Properties(id: response.rawGeocodedFeature.id, name: response.name, label: response.label, gid: response.rawGeocodedFeature.gid, layer: response.rawGeocodedFeature.layer, source: response.rawGeocodedFeature.source, source_id: response.rawGeocodedFeature.sourceID, accuracy: response.rawGeocodedFeature.accuracy, modes: [], street: response.rawGeocodedFeature.street, neighbourhood: response.rawGeocodedFeature.neighbourhood, locality: response.rawGeocodedFeature.locality, region_a: response.rawGeocodedFeature.regionA, secondaryLabels: [])
            let coordinate = Coordinate(lat: response.lat, long: response.lon)
            let geo = Autocomplete.Geometry(type: "Point", coordinate: coordinate)
            let feature = Autocomplete.Feature(properties: properties, geometry: geo, id: "")
            features.append(feature)
        }
        return  Autocomplete(features: features)
    }
    
    /// Update parking and rides feeds
    /// Updates parking and rides feeds.
    func updateParkingAndRidesFeeds(){
        let cancellable = parkAndRide(maxTransitDistance: 1000)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    OTPLog.log(level: .error, info: "Handle error: \(error)")
                case .finished:
                    break
                }

            }) { (response) in
                let level = self.thresholdZoomLevelForRefresh[MarkerType.parkingAndRides.rawValue] ?? 0.0
                var features = [MGLGeneralAnnotation]()
                for parkRide in response {
                    let coordinates = CLLocationCoordinate2DMake(parkRide.coordinate.latitude, parkRide.coordinate.longitude)
                    let annotation = MGLGeneralAnnotation(title: parkRide.name, coordinate: coordinates)
                    annotation.markerType = .parkingAndRides
                    annotation.imageName = MGLMap.parkingMarker
                    annotation.attributes = ["title": parkRide.name, "markerType": MarkerType.parkingAndRides.rawValue, "imageName":MGLMap.parkingMarker, "resize": 40.0, "validLevel":level]
                    features.append(annotation)
                }
                self.markerDataSourceLocker.sync {
                    self.removeMarkersInDataSource(.parkingAndRides)
                    self.mapMarkers.append(contentsOf: features)
                    self.renderMarkerInMap()
                }
            }
        cancellableSet.insert(cancellable)
    }
    
    /// Update shared vehicles feeds
    /// Updates shared vehicles feeds.
    func updateSharedVehiclesFeeds(){
        MapAnnotationsFeedProvider.shared.getRentalVehicleLocations { locations in
            if let locations = locations{
                let scooterLevel = self.thresholdZoomLevelForRefresh[MarkerType.sharedScootersStop.rawValue] ?? 0.0
                let bikeLevel = self.thresholdZoomLevelForRefresh[MarkerType.sharedScootersStop.rawValue] ?? 0.0
                var bikeFeatures = [MGLGeneralAnnotation]()
                var scooterFeatures = [MGLGeneralAnnotation]()
                for location in locations{
                    if let lat = location.lat, let lon = location.lon, let name = location.name{
                        
                        let coordinates = CLLocationCoordinate2DMake(lat, lon)
                        let annotation = MGLGeneralAnnotation(title: name, coordinate: coordinates)
                        
                        var title = ""
                        var icon = ""
                        var networkName = ""
                        if let type = location.vehicleType, let formFector = type.formFactor{
                            if let network = location.network{
                                switch (network){
                                case .limeSeattle: networkName = "LIME"
                                case .linkSeattle: networkName = "Link"
                                case .birdSeattleWashington: networkName = "Bird"
                                }
                            }
                            if formFector == .scooter{
                                icon = MGLMap.sharedVehicleScooter
                                title = "E-Scooter:"
                                annotation.markerType = .sharedScootersStop
                                annotation.imageName = icon
                                annotation.attributes = ["title": "\(title) \(networkName)",
                                                         "markerType": MarkerType.sharedScootersStop.rawValue,
                                                         "imageName":icon,
                                                         "resize": 40.0,
                                                         "validLevel":scooterLevel]
                                
                                scooterFeatures.append(annotation)
                            }else {
                                icon = MGLMap.sharedVehicleBike
                                title = "Free-floating bike:"
                                annotation.markerType = .sharedBikeStop
                                annotation.imageName = icon
                                annotation.attributes = ["title": "\(title) \(networkName)",
                                                         "markerType": MarkerType.sharedBikeStop.rawValue,
                                                         "imageName":icon,
                                                         "resize": 40.0,
                                                         "validLevel":bikeLevel]
                                
                                bikeFeatures.append(annotation)
                            }
                        }
                        
                    }
                }
                self.markerDataSourceLocker.sync {
                    self.removeSharedVehiclesMarkersInDataSource(.sharedScootersStop, self.mapScooterMarkers)
                    self.removeSharedVehiclesMarkersInDataSource(.sharedBikeStop, self.mapBikeMarkers)
                    self.mapScooterMarkers.append(contentsOf: scooterFeatures)
                    self.mapBikeMarkers.append(contentsOf: bikeFeatures)
                    self.mapMarkers.append(contentsOf: self.mapScooterMarkers)
                    self.mapMarkers.append(contentsOf: self.mapBikeMarkers)
                    self.renderMarkerInMap()
                }
            }
        }
    }
    
    /// Update transit stop feeds
    /// Updates transit stop feeds.
    func updateTransitStopFeeds(){
        if MapAnnotationsFeedProvider.shared.agencyFeed == nil || MapAnnotationsFeedProvider.shared.agencyFeed == []{
            MapAnnotationsFeedProvider.shared.getAgancyFeed { _ in }
        }

        MapAnnotationsFeedProvider.shared.getMapStops { filteredStopList in
            if let filteredStopList = filteredStopList {
                self.stops = filteredStopList
                MapViewModel.shared.consolidateStops(comingStops: filteredStopList)
                let level = self.thresholdZoomLevelForRefresh[MarkerType.transitStop.rawValue] ?? 14.0
                var features = [MGLGeneralAnnotation]()
                
                // Adding Agency data to annotaion
                let agencyFeed = MapAnnotationsFeedProvider.shared.agencyFeed
                
                for stop in filteredStopList {
                    let coordinates = CLLocationCoordinate2DMake(stop.lat, stop.lon)
                    let annotation = MGLGeneralAnnotation(title: stop.name, coordinate: coordinates)
                    annotation.markerType = .transitStop
                    annotation.imageName = MGLMap.busStopMarker
                    
                    let agencyId = Stop.findDisplayCompanyId(stop.id)
                    let publisherName = agencyFeed?.first(where: { $0.feedId.lowercased() == agencyId.lowercased()})?.publisher.name ?? ""
                    annotation.attributes = ["title": stop.name, "stopID": stop.id, "stopCode": stop.code ?? "", "agencyName": publisherName, "markerType": MarkerType.transitStop.rawValue, "imageName":MGLMap.busStopMarker, "resize": 20.0,"validLevel":level]

                    features.append(annotation)
                }
    
                self.markerDataSourceLocker.sync {
                    self.removeMarkersInDataSource(.transitStop)
                    self.mapMarkers.append(contentsOf: features)
                    self.renderMarkerInMap()
                }
            }
        }
    }
    
    /// Show realtime bus.
    /// - Parameters:
    ///   - busData: Parameter description
    ///   - pattern: Parameter description
    func showRealtimeBus(busData: [RealTimeBus], pattern: String){
        for data in busData{
            let timeStamp = data.seconds
            let vehicleId = data.vehicleId
            let speed = data.speed.rounded()
            let seconds = Date().timeIntervalSince1970 - timeStamp
            let time = seconds.convertSecondsToMinutesAndSeconds()
            var title = "Vehicle \(vehicleId)\n\(time) ago"
            if speed != 0{
                title = "Vehicle \(vehicleId)\n\(time) ago \nTraveling at \(speed) mph"
            }
            realTimeBusMarker = MGLGeneralAnnotation(title: title, coordinate: CLLocationCoordinate2D(latitude: data.lat, longitude: data.lon))
            realTimeBusMarker.markerType = .realTimeBusMarker
            if let mode = data.mode {
                realTimeBusMarker.imageName = mode.marker_image
            }else {
                realTimeBusMarker.imageName = "ic_realtime_bus"
            }
            realTimeBusMarker.attributes = ["title": time]
            mapView.addAnnotation(realTimeBusMarker)
            
            realTimeBusMarkersGroup.append(realTimeBusMarker)
        }
    }
    
    /// Remove real time bus marker
    /// Removes real time bus marker.
    public func removeRealTimeBusMarker(){
        RouteManager.shared.stopRealtimeBusUpdates()
        mapView.removeAnnotations(realTimeBusMarkersGroup)
        realTimeBusMarkersGroup.removeAll()
    }
}
