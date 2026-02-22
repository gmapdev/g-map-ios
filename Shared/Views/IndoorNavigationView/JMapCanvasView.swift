//
//  JMapCanvasView.swift
//

import Foundation
import SwiftUI
import MapKit

class JMapManager: NSObject, ObservableObject {
    
    @Inject var auth0Provider: LoginAuthProvider
    
    @Published var pubLastUpdated = Date().timeIntervalSince1970
    @Published var pubOrigin = "current location"
    @Published var pubDestination = ""
    @Published var pubIsLoadingMap = true
    @Published var pubAudioAlertDialog = false
    @Published var pubAudioAlert = false
    @Published var pubPresentTurnbyTurnNote = false
    @Published var pubSelectedFloor: JMapFloor?                            // This is used to load the selected floor
    @Published var pubPresentStepsPanel: Bool = false                    // This is used to present the step panel with steps by steps view
    @Published var pubPresentDirectionPanel: Bool = false               // This is used to present the direction view for Indoor Navigation, speaker view.
    @Published var pubIsNearByVenue : Bool = false                      // This is used to represent the current location is near by the venue
    @Published var pubCurrentNavigationNote: TurnByTurnNote?            // This is used to hold the current navigation note to show direction
    @Published var pubCurrentDistanceToNextNote: Float?
    @Published var pubSearchableDestinationList: [String] = []      // This List will be Updated based on the Searching text from Search Origin/Destination
    @Published var pubIsRerouting: Bool = false                    // Spinner/disable state when attempting to re-route
    @Published var pubIsShowMapLabels: Bool = true                  // This is to control the Map labels
    @Published var pubIsActiveIndoorNavigation = false              // This is used to indicate Indoor Navigation has Active Route Directions
    
    @Published var counter: Int = 0               // Published variable to track time
    private var universalTimer: Timer?            // Universal timer to trigger functions simultaneously
    
    // This is used to hold the access level of User to get the route based on the selection of Mobility Profile
    @Published var pubAccessLevel: Int = 100
    
    @Published var isUserExploringMap: Bool = false
    
    public var allAvailableDestinations = [JMapDestination]()               // This is used to store all the Available Destinations for Indoor Map
    public var allAvailableAmenities = [JMapAmenity]()                      // This is used to store all the Available Amenities for Indoor Map
    public var allAvailLocations : [String] = []
    public var turnByTurnInstructions = [TurnByTurnNote]()                  // This is used to hold all the instructions for current searched Route.
    public var pixelPhysicDistanceRatio = [Int: Double]()                   // [mapId: mmDistance/pixelDistance]()
    
    
    private var playedTurnByTurnNoteId = ""
    public var triggerableLocations : [TriggerableLocations]?
    private var lastTriggeredLocation:TriggerableLocations?
    
    public var mainIndoorEntranceLocations: [IndoorMainEntranceLocation]?   // This is used to store all the available main Entrance for Indoor Map with onboard popup information as well.
    public var lastTriggeredMainEntranceLocation:IndoorMainEntranceLocation?
    
    public var isArrivedToastPresented = false
    public var entrance_exit_checking_interval_secs = FeatureConfig.shared.indoor_entrance_exit_checking_interval_secs
    public var checking_active_route_entrance = FeatureConfig.shared.indoor_checking_active_route_entrance
    public var currentLocation_upcoming_point_threshold_feet = FeatureConfig.shared.currentLocation_upcoming_point_threshold_feet
    
    // For the Indoor Simulation
    private var currentRouteIndex: Int = 0
    private var currentPointIndex: Int = 0
    private var currentMapId: Int?
    
    private var currentIndoorJMapPoint: JMapPoint?
    
    public static var venueId: Int32 = 2450 // GJAC
    public static let customerId:Int32 = Int32(FeatureConfig.shared.jibesream_customer_id)
    public static let endpointURL = FeatureConfig.shared.jibestream_endpoint_url
    public static let clientId = FeatureConfig.shared.jibestream_client_id
    public static let clientSecret = FeatureConfig.shared.jibestream_client_secret
    
    public var canvas: JMapCanvas?
    fileprivate var userLocation = CGPoint(x: 0, y: 0)
    fileprivate var jMap : JMap?
    fileprivate var core : JMapJCore?
    fileprivate var control : JMapController?
    fileprivate var navKit : JMapNavigation?
    fileprivate var paths : [JMapPathPerFloor] = []
    
    // Below Variable used to make User experince better when Indoor Navigation Triggering the ReRoute Popup
    var checkDeviationInterval = FeatureConfig.shared.indoor_nav_deviation_popup_wait_time_seconds
    var nextDeviationTimeStemp = Date().timeIntervalSince1970
    var maximumDeviationCancelCount = FeatureConfig.shared.indoor_nav_deviation_popup_count_max_number
    var deviationCancelCounter = 0
    var deviationDistanceInMM = FeatureConfig.shared.indoor_nav_deviation_distance_mm
    
    // Entrance and Exit Locations from the CFG Server
    var indoorEntranceandExitListURL = FeatureConfig.shared.indoor_entrance_exit_list_url
    var indoorMainEntranceList = FeatureConfig.shared.indoor_main_entrance_list
    var indoorTriggerableLocationsList = FeatureConfig.shared.indoor_triggerable_locations
    var indoorEntranceExitPopupDistanceMM = FeatureConfig.shared.indoor_entrance_exit_popup_distance_mm
    var entrancesAndExits : [EntranceExitLocation]?
    var entrancesAndExitsasDestination = [JMapDestination]()
    
    var currentLocationShouldUpdateInSeconds = FeatureConfig.shared.current_location_should_update_in_seconds
    var currentInstructionShouldUpdateInSeconds = FeatureConfig.shared.current_instruction_should_update_in_seconds
    var snapToWayfindPathThresholdInMeter = FeatureConfig.shared.snap_to_wayfind_path_threshold_in_meter
    
    
    var currentFloor = JMapFloor()
    fileprivate var simulatedRoute : [Int : [CGPoint]] = [:]
    
    /// This timer is used to move the current location when the simulatorIsEnabled becomes to true
    fileprivate var simulatorTimer: Timer?
    
    /// Shared.
    /// - Parameters:
    ///   - JMapManager: Parameter description
    public static var shared: JMapManager = {
        let mgr = JMapManager()
        mgr.getTriggerableLocation()
        mgr.getIndoorEntranceLocations()
        mgr.getEntranceAndExit()
        return mgr
    }()
    
    /// Initialization
    /// Initialization.
    func initialization(){
        /// Initializes a new instance.
        let options  = JMapOptions.init()
        options.customerId = JMapManager.customerId
        options.venueId = JMapManager.venueId
        options.host = JMapManager.endpointURL
        options.clientId = JMapManager.clientId
        options.clientSecret = JMapManager.clientSecret
        options.stage = self.canvas
        options.applyDisplayMode = true
        options.clearCacheData = true
        options.autoReloadCache = true
        self.jMap = JMap(options: options)
        self.jMap?.delegate = self
        
        // Start the Indoor Navigation Extends SDK
        IndoorNavigationManager.shared.startIndoorExtendsSDK()
        
        auth0Provider.getUserInfo {}
    }
    
    /// Find destination.
    /// - Parameters:
    ///   - name: Parameter description
    /// - Returns: JMapDestination?
    func findDestination(name: String) -> JMapDestination? {
        let destinations = self.allAvailableDestinations
        for destination in destinations {
            if let dstname = destination.name,
               dstname.lowercased() == name.lowercased() {
                return destination
            }
        }
        return nil
    }
    
    /// Find amenity.
    /// - Parameters:
    ///   - name: Parameter description
    /// - Returns: JMapAmenity?
    func findAmenity(name: String) -> JMapAmenity? {
        let amens = self.allAvailableAmenities
        for amen in amens {
            if let amenName = amen.name,
               amenName.lowercased() == name.lowercased() {
                return amen
            }
        }
        return nil
    }
    
    /// Clear drawing
    /// Clears drawing.
    func clearDrawing(){
        if let control = self.control {
            control.clearWayfindingPath()
            self.pubOrigin = "current location"
            self.pubDestination = ""
            self.deviationCancelCounter = 0
        }
    }
    
    /// Highlight units
    /// Highlight units.
    func highlightUnits() {
        if let control = JMapManager.shared.control {
            
            allAvailLocations.removeAll()
            allAvailableDestinations.removeAll()
            allAvailableAmenities.removeAll()
            
            // Fetching All the Destinations from SDK
            let destinations : [JMapDestination] = control.activeVenue!.destinations!.getAll()
            for destination : JMapDestination in destinations {
                allAvailableDestinations.append(destination)
                allAvailLocations.append(destination.name ?? "")
            }
            // Fetching All the Amenities from SDK
            let amenities : [JMapAmenity] = control.activeVenue!.amenities!.getAll()
            for amenity : JMapAmenity in amenities {
                allAvailableAmenities.append(amenity)
            }
            
            self.pubSearchableDestinationList = allAvailLocations
            DispatchQueue.main.async{
                self.pubLastUpdated = Date().timeIntervalSince1970
            }
            let style : JMapStyle = JMapStyle()
            style.setFill(UIColor.clear)
            style.setStroke(UIColor.black)
            style.setLineWidth(1)
            let dests = self.allAvailableDestinations
            for destination : JMapDestination in dests {
                control.getUnitsFrom(destination, completionHandler: { (units, error) in
                    if let error = error {
                        OTPLog.log(level: .error, info: "failed to get units from destination")
                        OTPLog.log(level: .error, info: "Error: \(error.errorDescription)")
                    } else {
                        control.styleShapes(units, withStyling: style)
                    }
                })
            }
            
        }
    }
    
    /// Search destinations.
    /// - Parameters:
    ///   - searchText: Parameter description
    /// Searches destinations.
    func searchDestinations(searchText: String) {
        if searchText.isEmpty {
            self.pubSearchableDestinationList = self.allAvailLocations
        }else {
            self.pubSearchableDestinationList = self.allAvailLocations.filter {
                $0.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    /// Locate me
    /// Locate me.
    func locateMe(){
        if let control = JMapManager.shared.control {
            if self.isUserExploringMap{
                self.isUserExploringMap = false
                ToastManager.show(message: "Follow me function enabled")
            }
            
            if currentFloor != control.currentFloor!{
                renderFloor(floor: currentFloor)
            }
            if !isUserExploringMap {
                control.updateUserLocation(userLocation, floorMap: control.currentMap!, orientation: 0, confidenceRadius: 100)

                if let currentm = control.currentMap{
                   let ratio = currentm.mmPerPixel
                    let threshold = Float(self.snapToWayfindPathThresholdInMeter * 1000) / Float(truncating: ratio ?? 1)
                    control.userLocation.snapToWayfindingPath(withThreshold: Float(threshold))
                }
            }
        }
    }

    func startUniversalTimer() {
        stopUniversalTimer()

        universalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.counter += 1

            // MARK: - Update Current Instruction Every Configured Seconds
            if self.counter % currentInstructionShouldUpdateInSeconds == 0, pubPresentDirectionPanel {
                if let currentJMapPoint = self.currentIndoorJMapPoint {
                    self.updateInstruction(
                        x: CGFloat(currentJMapPoint.x),
                        y: CGFloat(currentJMapPoint.y),
                        z: CGFloat(currentJMapPoint.z)
                    )
                }
            }

            // MARK: - Update Current Location Every Configured Seconds
            if self.counter % currentLocationShouldUpdateInSeconds == 0, !isUserExploringMap {
                if !IndoorNavigationManager.shared.pubSimulateIndoorNavigation{
                    if let control = JMapManager.shared.control, let currentMap = control.currentMap {
                        control.updateUserLocation(userLocation, floorMap: currentMap, orientation: 0, confidenceRadius: 100)
                        
                        if let ratio = currentMap.mmPerPixel {
                            let threshold = Float(self.snapToWayfindPathThresholdInMeter * 1000) / Float(truncating: ratio)
                            control.userLocation.snapToWayfindingPath(withThreshold: threshold)
                        }
                    }
                }
            }

            // MARK: - Check Entrance/Exit at Configured Interval
            if self.counter % entrance_exit_checking_interval_secs == 0 {
                if isSearchforExit() || !checking_active_route_entrance {
                    checkingUserIsNearEtranceExit()
                }
            }
        }
    }

    // Stop the timer
    /// Stops universal timer.
    func stopUniversalTimer() {
        universalTimer?.invalidate()
        universalTimer = nil
        isArrivedToastPresented = false
        counter = 0
    }
    
    // MARK: - Updates user's location on the Indoor Map (Called at 32Hz (1/32 seconds))
    /// Updates user location.
    /// - Parameters:
    ///   - lat: Double
    ///   - lon: Double
    ///   - floor: Int
    func updateUserLocation(lat: Double, lon: Double, floor: Int) {
        guard let control = JMapManager.shared.control else { return }

        // Convert GPS coordinates (lat/lon) to the indoor map's local coordinate system
        let geoPoint = CGPoint(x: lon, y: lat)
        let convertedPoint = JMapUtils.convert(geoPoint, fromProjection: "EPSG:4326", toProjection: "jmap:local", in: control.activeVenue)

        // Update the user's location
        self.userLocation = convertedPoint

        // If the user is **not** manually exploring the map, update to the correct floor
        if !isUserExploringMap {
            if let matchedFloor = self.floors().first(where: { Int(truncating: $0.id) == floor }) {
                if matchedFloor != control.currentFloor {
                    renderFloor(floor: matchedFloor)
                }
                currentFloor = matchedFloor
            } else {
                currentFloor = control.currentFloor ?? JMapFloor()
            }
        }

        // Assign the current JMapPoint and floor ID
        if let validJMapPoint = JMapPoint(x: Float(convertedPoint.x), y: Float(convertedPoint.y), z: Float(floor)) {
            self.currentIndoorJMapPoint = validJMapPoint
        }
        
        self.currentMapId = floor
    }

    
    /// This is used to get next Navigation Note
    /// Fetches next navigation note.
    /// - Returns: TurnByTurnNote?
    func fetchNextNavigationNote() -> TurnByTurnNote? {
        guard let currentNote = pubCurrentNavigationNote,
              let currentIndex = turnByTurnInstructions.firstIndex(of: currentNote),
              currentIndex + 1 < turnByTurnInstructions.count else {
            return nil
        }

        return turnByTurnInstructions[currentIndex + 1]
    }


    // check the origin and destination is available, then, start to plot the route.
    /// Calculates routes.
    /// - Parameters:
    ///   - completion: @escaping ((Bool, String
    /// - Returns: Void))
    func calculateRoutes(completion:@escaping ((Bool, String)->Void)){
        guard JMapManager.shared.control != nil else {
            AlertManager.shared.presentAlert(message: "Indoor Navigation is not ready, can not find route.")
            completion(false, "Indoor Navigation is not ready, can not find route.")
            return
        }

        guard !pubOrigin.isEmpty, !pubDestination.isEmpty else {
            AlertManager.shared.presentAlert(message: "Indoor Navigation From and To can not be empty.")
            completion(false, "Indoor Navigation From and To can not be empty.")
            return
        }

        guard let destinationWaypoint = findDestination(name: pubDestination)?.waypoints?.first else {
            AlertManager.shared.presentAlert(message: "Cannot find your entered destination.")
            completion(false, "Cannot find your entered destination.")
            return
        }

        let originWaypoint: JMapWaypoint?

        if pubOrigin.lowercased() == "current location" {
            // Get the closest waypoint to the user's current location
            guard let closestWaypoint: JMapWaypoint = self.control?.activeVenue?.getClosestWaypointToCoordinate(on: (self.control?.currentMap)!, withCoordinate: (self.control?.userLocation.position)!) else {
                completion(false, "Cannot find current location")
                return
            }
            originWaypoint = closestWaypoint
        } else {
            // Get waypoint from entered origin location
            guard let originWaypointFirst = findDestination(name: pubOrigin)?.waypoints?.first else {
                AlertManager.shared.presentAlert(message: "Cannot find your entered origin.")
                completion(false, "Cannot find your entered origin.")
                return
            }
            originWaypoint = originWaypointFirst
        }

        // Check both waypoints and draw the path
        if let wp1 = originWaypoint{
            drawPath(from: wp1, to: destinationWaypoint)
            completion(true, "Success")
        } else {
            AlertManager.shared.presentAlert(message: "Indoor Navigation is not ready, cannot find the route.")
            completion(false, "Cannot find your entered origin.")
        }
    }

    /// Add label to.
    /// - Parameters:
    ///   - map: Parameter description
    ///   - waypoint: Parameter description
    ///   - text: Parameter description
    func addLabelTo(map: JMapMap, waypoint:JMapWaypoint, text:String) {
            /// Label.
            /// - Parameters:
            ///   - UILabel: Parameter description
            var label:UILabel {
                let label = UILabel()
                /// X: 0, y: 0, width: 20, height: 20
                label.frame = CGRect.init(x: 0, y: 0, width: 20, height: 20)
                label.backgroundColor = .yellow
                label.textColor = .black
                label.text = text;
                return label
            }
        
        DispatchQueue.main.async {[weak self] in
            let point = CGPoint(x: (waypoint.coordinates?.first?.doubleValue)!, y: (waypoint.coordinates?.last?.doubleValue)!)
            self?.control?.addComponent(label, to: map, at: point, rotateWithMap: true, scaleWithMap: true)
        }
        
    }
    
    // This function will draw polyline on the Indoor Map and also Get the Directions/Instruction for Route.
    /// Draws path.
    /// - Parameters:
    ///   - from: JMapWaypoint
    ///   - to: JMapWaypoint
    func drawPath(from: JMapWaypoint, to: JMapWaypoint) {

        self.pubAccessLevel = MobileQuestionnairViewModel.shared.hasMobilityOrVisionNeeds() ? 0 : 100
        self.pubCurrentNavigationNote = nil
        if let control = JMapManager.shared.control {
            self.simulatedRoute.removeAll()
            control.clearWayfindingPath()
            self.paths = control.wayfindBetweenWaypoint(from, andWaypoint: to, withAccessibility: pubAccessLevel, withObstacle: nil)
            if self.paths.isEmpty {
                if self.pubPresentDirectionPanel {
                    self.pubPresentDirectionPanel = false
                    self.clearDrawing()
                    self.stopIndoorSimulator()
                }
                AlertManager.shared.presentAlert(message: "CXApp was unable to generate a route. Please try searching again.")
            }
            
            control.userLocation.position = CGPoint(x: from.coordinates!.first!.doubleValue, y: from.coordinates!.last!.doubleValue)
            control.drawWayfindingPaths(paths)
            
            // Extracting Simulating Points
            for path in self.paths {
                if let points = path.mapPoints, let mapId = path.mapId{
                    var mapPoints:[CGPoint] = []
                    for point in points {
                        if let p = point as? JMapPoint {
                           let x = CGFloat(p.x)
                           let y = CGFloat(p.y)
                            mapPoints.append(CGPointMake(x, y))
                        }
                    }
                    simulatedRoute[Int(truncating: mapId)] = mapPoints
                }
            }
            
            // Creating Path width and color
            let pathStyle : JMapStyle = JMapStyle()
            pathStyle.setFill(UIColor.clear)
            pathStyle.setStroke(Helper.shared.colourWithHexString(hexString: "#86CDF9"))
            pathStyle.setLineWidth(3)
            
            // Custom Label on the Route for the Instruction
			let labelStyle : JMapStyle = JMapStyle()
			labelStyle.setFill(UIColor.main)
			labelStyle.setStroke(UIColor.black)
			labelStyle.setLineWidth(1)
			
			self.navKit?.drawPath(withInstructions: paths, pathStyle: pathStyle, label: labelStyle, font: UIFont(name: "HelveticaNeue-Bold", size: 12, color: UIColor.black))
            
            let instructions = navKit?.createInstructions(fromPaths: paths)
            for path in paths {
                self.pixelPhysicDistanceRatio[path.mapId.intValue] = path.mmDistance.doubleValue/path.pixelDistance.doubleValue
            }
            var instructionWaypoints = [JMapWaypoint]()
            var textDirections = [String]()
            self.turnByTurnInstructions.removeAll()
            var newInstructions = [JMapInstruction]()

            for instruction: JMapInstruction in instructions! {
                if instruction.pixelDistance > 100 {
                    
                    let newInstruction = JMapInstruction()
                    newInstruction.decisionPoint = instruction.decisionPoint
                    newInstruction.direction = instruction.direction
                    newInstruction.text = instruction.text
                    
                    instruction.decisionPoint = nil
                    instruction.text = "Continue Forward"
                    
                    newInstructions.append(instruction)
                    newInstructions.append(newInstruction)
                } else {
                    newInstructions.append(instruction)
                }
            }
            
            for instruction: JMapInstruction in newInstructions {
                if instruction.decisionPoint != nil {
                    instructionWaypoints.append(instruction.decisionPoint!)
                }
                var floor: String?
                if self.floors().count > 1 {
                    if let mapId = instruction.decisionPoint?.mapId, let instructionFloor = floors().first(where: { $0.map?.id == mapId}){
                        floor = instructionFloor.shortName
                    }
                }
                var distance: Float = 0
                if let mmperPixel = control.currentMap?.mmPerPixel{
                    let floatmmperPixel = Float(truncating: mmperPixel)
                    let pixelDistance = Float(instruction.pixelDistance)
                    let distanceinMeters = ((floatmmperPixel * pixelDistance * 3.28084) / 1000)
                        
                    distance = distanceinMeters
                }
                let tbtNote = TurnByTurnNote(id: UUID().uuidString, instruction: instruction.text!, distance: distance, floor: floor, decisionPoint: instruction.decisionPoint ?? instruction.completionPoint, completionPoint: instruction.completionPoint)
                
                if pubCurrentNavigationNote == nil {
                    pubCurrentNavigationNote = tbtNote
                    pubCurrentDistanceToNextNote = tbtNote.distance
                }
                turnByTurnInstructions.append(tbtNote)
                textDirections.append(instruction.text!)
            }
            isArrivedToastPresented = false
            IndoorNavigationManager.shared.indoorExitEntranceDialogPresented = false
        }
    }
    
    /// Plot user location at center
    /// Plot user location at center.
    func plotUserLocationAtCenter() {
        if let control = JMapManager.shared.control {
            let mapX : Double = control.currentMap!.width!.doubleValue
            let mapY : Double = control.currentMap!.height!.doubleValue
            let center : CGPoint = CGPoint(x: mapX / 2, y: mapY / 2)
            self.userLocation = center
            control.updateUserLocation(userLocation, floorMap: control.currentMap!, orientation: 0, confidenceRadius: 100)
            
            // update the the center location to receiption desk
            if let destination = self.findDestination(name: "Reception"),
               let dests = destination.locations,
               dests.count > 0{
                let waypoints = control.currentMap!.waypoints!.getBy(destination)
                if waypoints.count > 0{
                    if let first = waypoints[0].coordinates?.first?.doubleValue,
                       let last = waypoints[0].coordinates?.last?.doubleValue {
                        self.userLocation = CGPoint(x: first, y: last)
                    }
                }
            }
            control.updateUserLocation(userLocation, floorMap: control.currentMap!, orientation: 0, confidenceRadius: 100)
        }
    }
    
    /// Re route with nearest way point.
    /// - Parameters:
    ///   - completion: Parameter description
    /// - Returns: Void)? = nil)
    func reRouteWithNearestWayPoint(completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.main.async { self.pubIsRerouting = true }
        defer { DispatchQueue.main.async { self.pubIsRerouting = false } }
        guard
            let destination = findDestination(name: self.pubDestination),
            let waypoints = destination.waypoints,
            let targetWaypoint = waypoints.first
        else {
            DispatchQueue.main.async {
                ToastManager.show(message: "Destination unavailable for re-route. Please select a destination and try again.")
            }
            completion?(false)
            return
        }

        // Ensure control and active venue exist
        guard let control = self.control, let activeVenue = control.activeVenue else {
            DispatchQueue.main.async {
                ToastManager.show(message: "Indoor map is not ready. Please try re-route again in a moment.")
            }
            completion?(false)
            return
        }

        // Prefer the current map; if unavailable, try to fall back to the target waypoint's map
        var searchMap: JMapMap?
        if let currentMap = control.currentMap {
            searchMap = currentMap
        } else if let mapId = targetWaypoint.mapId, let fallbackMap = activeVenue.maps?.getById(mapId.intValue) {
            searchMap = fallbackMap
        }

        guard let map = searchMap else {
            DispatchQueue.main.async {
                ToastManager.show(message: "Unable to access the current floor map for re-route.")
            }
            completion?(false)
            return
        }

        // Use the controller's user location position (non-optional CGPoint)
        let coordinate: CGPoint = control.userLocation.position

        if let nearestWaypointToUserLocation: JMapWaypoint = activeVenue.getClosestWaypointToCoordinate(on: map, withCoordinate: coordinate) {
            self.drawPath(from: nearestWaypointToUserLocation, to: targetWaypoint)
            DispatchQueue.main.async {
                ToastManager.show(message: "Route updated.")
            }
            completion?(true)
        } else {
            DispatchQueue.main.async {
                ToastManager.show(message: "Couldn't find a nearby path. Move closer to a corridor and try again.")
            }
            completion?(false)
        }
    }
    /// Update instruction.
    /// - Parameters:
    ///   - x: Parameter description
    ///   - y: Parameter description
    ///   - z: Parameter description
    func updateInstruction(x: CGFloat, y: CGFloat, z: CGFloat) {
        guard let control = JMapManager.shared.control, let currentMap = control.currentMap else { return }
        let ratio = pixelPhysicDistanceRatio[currentMap.id.intValue] ?? pixelPhysicDistanceRatio.first?.value ?? 1.0
        guard let currentPoint = JMapPoint(x: Float(x), y: Float(y), z: Float(z)) else { return }
        self.currentIndoorJMapPoint = currentPoint
        if IndoorNavigationManager.shared.pubSimulateIndoorNavigation {
            let cp = CGPoint(x: CGFloat(currentPoint.x), y: CGFloat(currentPoint.y))
            control.updateUserLocation(cp, floorMap: currentMap, orientation: 0, confidenceRadius: 100)
        }
        updateInstructionsByPoint(currentPoint: currentPoint, ratio: ratio)

    }
    /// Update instructions by point.
    /// - Parameters:
    ///   - currentPoint: Parameter description
    ///   - ratio: Parameter description
    /// Updates instructions by point.
    func updateInstructionsByPoint(currentPoint: JMapPoint, ratio: Double) {
        guard let currentMapId = currentMapId else { return }
        let upcomingNotes = getUpcomingNavigationNotes(limit: 2)
        for note in ([pubCurrentNavigationNote] + upcomingNotes) {
            guard let note = note else { continue }
            guard let completionCoords = note.completionPoint.coordinates, completionCoords.count >= 2,
                  let completionX = completionCoords[0] as? NSNumber,
                  let completionY = completionCoords[1] as? NSNumber,
                  let notePoint = JMapPoint(x: completionX.floatValue, y: completionY.floatValue, z: Float(currentMapId)) else {
                continue
            }
            if isPoint(currentPoint, nearTo: notePoint, thresholdInFeet: Float(currentLocation_upcoming_point_threshold_feet)) {
                if pubCurrentNavigationNote != note {
                    pubCurrentNavigationNote = note
                    isArrivedToastPresented = false
                }
                break
            }
        }

        if let lastNote = turnByTurnInstructions.last {
            guard let completionCoords = lastNote.completionPoint.coordinates, completionCoords.count >= 2,
                  let completionX = completionCoords[0] as? NSNumber,
                  let completionY = completionCoords[1] as? NSNumber,
                  let notePoint = JMapPoint(x: completionX.floatValue, y: completionY.floatValue, z: Float(currentMapId)) else {
                return
            }
            if isPoint(currentPoint, nearTo: notePoint, thresholdInFeet: Float(currentLocation_upcoming_point_threshold_feet)) {
                if pubCurrentNavigationNote != lastNote, !isArrivedToastPresented {
                    pubCurrentNavigationNote = TurnByTurnNote(
                        id: UUID().uuidString,
                        instruction: "You have arrived.",
                        distance: 0,
                        floor: lastNote.floor,
                        decisionPoint: lastNote.decisionPoint,
                        completionPoint: lastNote.completionPoint
                    )
                    isArrivedToastPresented = true
                    triggerHapticFeedback()
                }
            }
        }
        if let currentNote = pubCurrentNavigationNote {
            guard let decisionCoords = currentNote.decisionPoint.coordinates, decisionCoords.count >= 2,
                  let decisionX = decisionCoords[0] as? NSNumber,
                  let decisionY = decisionCoords[1] as? NSNumber,
                  let decisionPoint = JMapPoint(x: decisionX.floatValue, y: decisionY.floatValue, z: Float(currentMapId)) else { return }

            if isPoint(currentPoint, nearTo: decisionPoint, thresholdInFeet: Float(currentLocation_upcoming_point_threshold_feet)),
               playedTurnByTurnNoteId != currentNote.id {
                triggerHapticFeedback()
                announceInstruction(currentNote.instruction)
                playedTurnByTurnNoteId = currentNote.id
            }
        }
        let currentPointCG = CGPoint(x: CGFloat(currentPoint.x), y: CGFloat(currentPoint.y))
        updateDistance(currentPoint: currentPointCG, ratio: ratio)
    }



    // MARK: - Get Next Navigation Notes (Limit to `count`)
    /// Retrieves upcoming navigation notes.
    /// - Parameters:
    ///   - limit: Int
    /// - Returns: [TurnByTurnNote]
    func getUpcomingNavigationNotes(limit: Int) -> [TurnByTurnNote] {
        guard let currentNote = pubCurrentNavigationNote,
              let currentIndex = turnByTurnInstructions.firstIndex(of: currentNote) else {
            return []
        }

        let startIndex = currentIndex + 1
        let endIndex = min(startIndex + limit, turnByTurnInstructions.count)
        return Array(turnByTurnInstructions[startIndex..<endIndex])
    }

    // MARK: - Play Instruction Announcement
    /// Announce instruction.
    /// - Parameters:
    ///   - instruction: String
    func announceInstruction(_ instruction: String) {
        if pubAudioAlert {
            TravelIQAudio.shared.playAudio(fromText: instruction, parameters: nil, highPriority: false, ignoreError: true) { _, _, _ in }
        }
    }

    // MARK: - Haptic Feedback for Instruction Change
    /// Trigger haptic feedback.
    func triggerHapticFeedback() {
        let isHapticEnabled = ProfileManager.shared.isHapticFeedbackOpen
        if isHapticEnabled{
            UINotificationFeedbackGenerator().notificationOccurred(AppSession.shared.hapticFeedbackStyle)
        }
    }

    /// Update distance.
    /// - Parameters:
    ///   - currentPoint: Parameter description
    ///   - ratio: Parameter description
    func updateDistance(currentPoint: CGPoint, ratio: Double) {
        guard let currentNavNote = pubCurrentNavigationNote else {
            return
        }
        
        let referenceNote = getRelevantNavigationNote()
        
        guard let coordinates = referenceNote.completionPoint.coordinates,
              coordinates.count >= 2,
              let xValue = coordinates[0] as? CGFloat,
              let yValue = coordinates[1] as? CGFloat else {
            return
        }
        let notePoint = CGPoint(x: xValue, y: yValue)
        let distanceToNextNote = hypot(currentPoint.x - notePoint.x, currentPoint.y - notePoint.y)
        pubCurrentDistanceToNextNote = Float(distanceToNextNote * ratio * 0.00328084)
    }
    /// Retrieves relevant navigation note.
    /// - Returns: TurnByTurnNote
    func getRelevantNavigationNote() -> TurnByTurnNote {
        if let nextNote = fetchNextNavigationNote() {
            return nextNote
        }
        return pubCurrentNavigationNote ?? turnByTurnInstructions.last ?? TurnByTurnNote(id: "", instruction: "", distance: 0, floor: nil, decisionPoint: JMapWaypoint(), completionPoint: JMapWaypoint())
    }

    /// Is point.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - nearTo: Parameter description
    ///   - thresholdInFeet: Parameter description
    /// - Returns: Bool
    private func isPoint(_ point1: JMapPoint, nearTo point2: JMapPoint, thresholdInFeet: Float) -> Bool {
        let p1 = CGPoint(x: CGFloat(point1.x), y: CGFloat(point1.y))
        let p2 = CGPoint(x: CGFloat(point2.x), y: CGFloat(point2.y))
        let distance = hypot(p1.x - p2.x, p1.y - p2.y)
        let mapId = control?.currentMap?.id.intValue
        let ratio = mapId.flatMap { pixelPhysicDistanceRatio[$0] } ?? pixelPhysicDistanceRatio.values.first ?? 1.0
        let newDistance = distanceInFeet(distance, ratio: ratio)
        return newDistance <= thresholdInFeet
    }

    /// Distance in feet.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - ratio: Parameter description
    /// - Returns: Float
    private func distanceInFeet(_ distance: Double, ratio: Double) -> Float {
        return Float(distance * ratio * 0.00328084)
    }

    /// Check deviation of route
    /// - Returns: Bool
    /// Checks deviation of route.
    func checkDeviationOfRoute() -> Bool {
        let isDeviated = self.navKit?.hasUserVeeredOffRoute(self.paths, threshold: deviationDistanceInMM) ?? false
        return isDeviated
    }
    
    /// Is searchfor exit
    /// - Returns: Bool
    /// Checks if searchfor exit.
    func isSearchforExit() -> Bool{
        if let configuredEntrancesExits = self.entrancesAndExits{
            let selectedDestination = pubDestination
            for item in configuredEntrancesExits{
                if item.name == selectedDestination{
                    return true
                }
            }
        }
        return false
    }
    /// Checking user is near etrance exit.
    func checkingUserIsNearEtranceExit(){
        if let currentJMapPoint = self.currentIndoorJMapPoint {
                let (isNear, entranceExitName) = isUserNearExitOrEntrance(currentJMapPoint, assignedEntranceExitNames: checking_active_route_entrance ? [self.pubDestination] : nil)
            if isNear {
                let foundEntranceExitName = entrancesAndExits?.first(where: {$0.name == entranceExitName})
                if let foundName = foundEntranceExitName {
                    if let msg = foundName.message {
                        IndoorNavigationManager.shared.pubIndoorExitDialogBoxMessage = msg
                    }else{
                        IndoorNavigationManager.shared.pubIndoorExitDialogBoxMessage = IndoorNavigationManager.shared.indoorExitDialogBoxMessage
                    }
                }
                if !IndoorNavigationManager.shared.indoorExitEntranceDialogPresented {
                    IndoorNavigationManager.shared.pubPresentIndoorExitDirectionDialog = true
                    IndoorNavigationManager.shared.indoorExitEntranceDialogPresented = true
                }else {
                    OTPLog.log(level: .info, info: "User is not nearby any entrance or exits, for spacial popup.")
                }
            }
        }
    }
    
    /// Is user near exit or entrance.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - assignedEntranceExitNames: Parameter description
    /// - Returns: (Bool,String?)
    func isUserNearExitOrEntrance(_ currentPoint: JMapPoint, assignedEntranceExitNames: [String]? = nil) -> (Bool,String?){
        guard let entranceExits = entrancesAndExits else { return (false, nil) }

        if entrancesAndExitsasDestination.isEmpty {
            let entranceNames = Set(entranceExits.compactMap { $0.name })
            var assignedEntExtNames = assignedEntranceExitNames ?? allAvailableDestinations.map({$0.name ?? ""})
            entrancesAndExitsasDestination = allAvailableDestinations.filter {
                if let name = $0.name {
                    return entranceNames.contains(name) && assignedEntExtNames.contains(name)
                }
                return false
            }
        }
        for destination in entrancesAndExitsasDestination {
            guard let waypoint = destination.waypoints?.first,
                  let mapId = waypoint.mapId,
                  let coordinates = waypoint.coordinates,
                  coordinates.count >= 2 else { continue }
            
            if let entranceExitPoint = JMapPoint(
                x: Float(truncating: coordinates[0]),
                y: Float(truncating: coordinates[1]),
                z: Float(truncating: mapId)
            ) {
                let thresholdFeet = Double(indoorEntranceExitPopupDistanceMM) * 0.00328084
                if isPoint(currentPoint, nearTo: entranceExitPoint, thresholdInFeet: Float(thresholdFeet)) {
                    return (true,destination.name)
                }
            }
        }
        
        return (false, nil)
    }

    /// This is used to load the floors for a given venue id
    /// so that we can show the proper UI
    /// Floors.
    /// - Returns: [JMapFloor]
    func floors() -> [JMapFloor]{
        if let control = JMapManager.shared.control {
            let allFloors = control.activeVenue?.buildings?.getAllFloors()
            if let floors = allFloors {
                return floors
            }
        }
        return []
    }
    
    /// This is used to render the floors from the floor picker.
    /// Renders floor.
    /// - Parameters:
    ///   - floor: JMapFloor
    func renderFloor(floor: JMapFloor) {
        if let control = JMapManager.shared.control {
            if let floorMap = floor.map {
                let id = floorMap.id.intValue
                if let map : JMapMap = control.activeVenue?.maps?.getById(id){
                    control.show(map, completionHandler: { (error) in
                        if let error = error {
                            OTPLog.log(level: .error, info: "failed to load and render the floor")
                            OTPLog.log(level: .error, info: "Error: \(error.errorDescription)")
                        }
                    })
                    self.pubSelectedFloor = floor
                }
            }
        }
    }
    /// This is used to get the Destination name with their floor's name appended at end.
    /// Retrieves destination name with floor string.
    /// - Parameters:
    ///   - location: String
    /// - Returns: String
    func getDestinationNameWithFloorString(_ location: String) -> String {
        var locName = location
        var floorShortName = ""
        
        if self.floors().count > 1 {
            if let destination = findDestination(name: location), let floor = getFloorFromDestination(destination: destination){
                floorShortName = floor.shortName ?? ""
            } else if let amenity = findAmenity(name: location), let floor = getFloorFromAmenity(amenity: amenity){
                floorShortName = floor.shortName ?? ""
            }
            locName.append(" - \(floorShortName)")
            return locName
        }
        return locName
    }
    
    /// This is used to get the JMapFloor from the JMapDestination
    /// Retrieves floor from destination.
    /// - Parameters:
    ///   - destination: JMapDestination
    /// - Returns: JMapFloor?
    func getFloorFromDestination(destination: JMapDestination) -> JMapFloor? {
        let mapID = destination.waypoints?.first?.mapId ?? destination.locations?.first?.mapId
        guard let mapID = mapID else {
            return nil
        }
        for floor in self.floors() {
            if let floorMapId = floor.map?.id, floorMapId == mapID {
                return floor
            }
        }
        return nil
    }
    /// This is used to get the JMapFloor from the JMapAmenity
    /// Retrieves floor from amenity.
    /// - Parameters:
    ///   - amenity: JMapAmenity
    /// - Returns: JMapFloor?
    func getFloorFromAmenity(amenity: JMapAmenity) -> JMapFloor? {
        let mapID = amenity.waypoints?.first?.mapId ?? amenity.locations?.first?.mapId
        guard let mapID = mapID else {
            return nil
        }
        for floor in self.floors() {
            if let floorMapId = floor.map?.id, floorMapId == mapID {
                return floor
            }
        }
        return nil
    }
    
    /// This is used to get the total distance of the indoor nav
    /// Total distance.
    /// - Returns: Float
    func totalDistance() -> Float {
        return self.turnByTurnInstructions.reduce(0) { $0 + $1.distance }
    }
    
    /// Direction icon name.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: String
    func directionIconName(_ instruction: String?) -> String{
        if let instruction = instruction, instruction.lowercased().contains("left") {
            return "direction_left_icon"
        }
        if let instruction = instruction, instruction.lowercased().contains("right") {
            return "direction_right_icon"
        }
        if let instruction = instruction, instruction.lowercased().contains("arrive") || instruction.lowercased().contains("arrived"){
            return "map_to_icon"
        }
        if let instruction = instruction{
            return "direction_straight_icon"
            
        }
        return "direction_location_question"
    }
    
    /// Get distance in feet.
    /// - Parameters:
    ///   - from: Parameter description
    /// - Returns: Float?
    func getDistanceInFeet(from pixelDistance: Float) -> Float? {
        guard let control = JMapManager.shared.control,
              let mmPerPixel = control.currentMap?.mmPerPixel else {
            return nil
        }
        
        let floatmmperPixel = Float(truncating: mmPerPixel)
        let distanceInFeet = (floatmmperPixel * pixelDistance * 3.28084) / 1000
        return distanceInFeet
    }

    
    // MARK: - GeoFence Detection
    /// This is used to check the GeoFence with current Location
    /// Checks geo fence detection.
    /// - Parameters:
    ///   - currentLocations: [CLLocation]
    func checkGeoFenceDetection(currentLocations: [CLLocation]){
        
        if let triggerLocations = self.triggerableLocations,
           let currentLocation = currentLocations.last{
            
            var findTriggerableLocation: TriggerableLocations?
            for triggerPoint in triggerLocations {
                if triggerPoint.type == "polygon" {
                    if let polygon = triggerPoint.coordinates {
                        let isInsidePolygon = Helper.shared.isInPolygon(polygon: polygon, location: currentLocation)
                        if isInsidePolygon {
                            findTriggerableLocation = triggerPoint
                            IndoorNavigationManager.shared.pubJMapVenueId = Int32(triggerPoint.venueID)
                            break
                        }
                    }
                } else {
                    let targetLocation = CLLocation(latitude: triggerPoint.latitude, longitude: triggerPoint.longitude)
                    let distance = currentLocation.distance(from: targetLocation)
                    if Int(distance) <= triggerPoint.radiusInMeters {
                        findTriggerableLocation = triggerPoint
                        IndoorNavigationManager.shared.pubJMapVenueId = Int32(triggerPoint.venueID)
                        break
                    }
                }
            }
            if let trigger = findTriggerableLocation {
                var findBefore = false
                if let lastTrigger = self.lastTriggeredLocation {
                    findBefore = lastTrigger.address == trigger.address
                }
                if !findBefore {
                    self.lastTriggeredLocation = trigger
                    UIApplication.shared.dismissKeyboard()
                    IndoorNavigationManager.shared.pubPresentIndoorNavDialog = true
                }
                if !self.pubIsNearByVenue {
                    self.pubIsNearByVenue = true
                    HomeViewModel.shared.pubLastUpdated = Date().timeIntervalSince1970
                }
                
            } else {
                if self.pubIsNearByVenue {
                    self.pubIsNearByVenue = false
                    HomeViewModel.shared.pubLastUpdated = Date().timeIntervalSince1970
                }
            }
            
        } else {
            OTPLog.log(level: .warning, info: "Can not find any Triggerable Locations..!")
        }
    }
    
    // This will used to get the Triggerable Location from the S3 Server
    /// Retrieves triggerable location.
    func getTriggerableLocation(){
        
        let url = self.indoorTriggerableLocationsList
        
        guard let url = URL(string: url) else {
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                OTPLog.log(level: .error, info: "Error: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    let decodedData = try JSONDecoder().decode([TriggerableLocations].self, from: data)
                    self.triggerableLocations = decodedData
                } catch {
                    OTPLog.log(level: .error, info: "Error decoding jmap_triggerable_locations JSON: \(error.localizedDescription)")
                    return
                }
            }
        }.resume()
    }
    
    /// Check main entrancefor indoor nav.
    /// - Parameters:
    ///   - currentLocations: Parameter description
    /// Checks main entrancefor indoor nav.
    func checkMainEntranceforIndoorNav(currentLocations: [CLLocation]) {
        
        let currentVenueId = IndoorNavigationManager.shared.pubJMapVenueId
        
        guard
            let mainEntrances = self.mainIndoorEntranceLocations,
            let currentLocation = currentLocations.last
        else {
            OTPLog.log(level: .warning, info: "Cannot find any Indoor Entrance Locations with Description to show")
            return
        }

        if let entrance = mainEntrances.first(where: { item in
            item.venueID == currentVenueId &&
            currentLocation.distance(
                from: CLLocation(latitude: item.mainLatitude, longitude: item.mainLongitude)
            ) <= Double(item.radiusInMeter)
        }) {
            if self.lastTriggeredMainEntranceLocation?.place != entrance.place {
                IndoorNavigationManager.shared.pubIndoorEntranceDialogTitle = entrance.popupTitle
                IndoorNavigationManager.shared.pubIndoorEntranceDialogMessage = entrance.popupMessage
                self.lastTriggeredMainEntranceLocation = entrance
                IndoorNavigationManager.shared.pubPresentIndoorEntranceDialog = true
            }
        }
    }
    
    // This will used to get the Main Entrance Location from the S3 Server to trigger the one time popup for Indoor Nav
    /// Retrieves indoor entrance locations.
    func getIndoorEntranceLocations(){
        
        let url = self.indoorMainEntranceList
        guard let url = URL(string: url) else {
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                OTPLog.log(level: .error, info: "Error: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    let decodedData = try JSONDecoder().decode([IndoorMainEntranceLocation].self, from: data)
                    self.mainIndoorEntranceLocations = decodedData
                } catch {
                    OTPLog.log(level: .error, info: "Error decoding indoor_main_entrance_popup JSON: \(error.localizedDescription)")
                    return
                }
            }
        }.resume()
    }
    
    /// Get entrance and exit
    /// Retrieves entrance and exit.
    func getEntranceAndExit(){
        guard let url = URL(string: self.indoorEntranceandExitListURL) else {
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                OTPLog.log(level: .error, info: "Error: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    let decodedData = try JSONDecoder().decode([EntranceExitLocation].self, from: data)
                    self.entrancesAndExits = decodedData
                } catch {
                    OTPLog.log(level: .error, info: "Error decoding indoor_entrance_exit_list JSON: \(error.localizedDescription)")
                    return
                }
            }
        }.resume()
    }
}

// MARK: - Indoor Simulation
extension JMapManager{
    /// Start indoor simulator
    /// Starts indoor simulator.
    public func startIndoorSimulator() {
        simulatorTimer?.invalidate()
        simulatorTimer = Timer.scheduledTimer(timeInterval: 1.8, target: self, selector: #selector(simulateNextPoint), userInfo: nil, repeats: true)
    }

    /// Stop indoor simulator
    /// Stops indoor simulator.
    public func stopIndoorSimulator() {
        simulatorTimer?.invalidate()
        self.simulatedRoute.removeAll()
        simulatorTimer = nil
        currentRouteIndex = 0
        currentPointIndex = 0
        plotUserLocationAtCenter()
    }


    /// Simulate next point
    /// Simulate next point.
    @objc private func simulateNextPoint() {
        guard !simulatedRoute.isEmpty else {
            return
        }

        guard let control = JMapManager.shared.control else { return }
        let routeKeys = Array(simulatedRoute.keys).sorted()
        
        guard currentRouteIndex < routeKeys.count else {
            return
        }
        
        let mapId = routeKeys[currentRouteIndex]
        let points = simulatedRoute[mapId] ?? []
        
        if currentMapId != mapId {
            if let floor = floors().first(where: { Int($0.map?.id ?? 0) == mapId }) {
                renderFloor(floor: floor)
                currentMapId = mapId
            }
        }

        if currentPointIndex < points.count {
            let point = points[currentPointIndex]
            currentPointIndex += 1
            updateInstruction(x: point.x, y: point.y, z: CGFloat(currentMapId ?? 0))
        } else {
            currentPointIndex = 0
            currentRouteIndex += 1
        }
    }
}

// MARK: - Indoor SDK JMapDelegate
extension JMapManager: JMapDelegate {
    /// Initializes a new instance.

    /// Jmap initialized.
    /// - Parameters:
    ///   - _: Parameter description
    func jmapInitialized(_ error: JMapError?) {
        OTPLog.log(level: .info, info: "map is loaded. \(String(describing: error))")
        if error != nil {
            OTPLog.log(level: .error, info: "Error: \(error?.message ?? "JMap init error.")")
        } else {
            self.control = self.jMap?.controller
            self.highlightUnits()
            self.plotUserLocationAtCenter()
            self.toggleMapLabels(true)
            
            let navKitOptions = ["layersOfInterest": ["Units", "Elevators"]]
            guard let control = self.control else { return }
            self.navKit = JMapNavigation(controller: control, andOptions: navKitOptions)
            self.navKit?.angleThreshold = 50
            
            let floors = self.floors()
            if floors.count > 0 {
                for i in 0..<floors.count {
                    let floor = floors[i]
                    if let crtFloor = self.control?.currentFloor,
                       let shortFloor = floor.shortName,
                       crtFloor.shortName == shortFloor {
                       self.pubSelectedFloor = floor
                       break
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.pubIsLoadingMap = false
        }
    }
    
    /// Jmap parsed all maps.
    /// - Parameters:
    ///   - _: Parameter description
    func jmapParsedAllMaps(_ error: JMapError?) {
        OTPLog.log(level: .info, info: "map is parsed. \(String(describing: error))")
    }
    
    /// Toggles the visibility of all map labels and unit contents across the active venue
    /// - Parameter isVisible: true to show labels, false to hide them
    /// Toggles map labels.
    /// - Parameters:
    ///   - isVisible: Bool
    func toggleMapLabels(_ isVisible: Bool) {
        guard let mapControl = JMapManager.shared.control,
              let venueMaps = mapControl.activeVenue?.maps?.getAll() else {
            return
        }
        
        venueMaps.forEach { map in
            mapControl.getUnitsFrom(map) { units, error in
                guard error == nil else { return }
                
                units.forEach { unit in
                    isVisible ? mapControl.showUnitContents(unit) : mapControl.hideUnitContents(unit)
                }
            }
        }
        
        if isVisible {
            mapControl.showAllTextMapLabels()
            mapControl.showAllImageMapLabels()
            mapControl.applyDisplayModeToAllUnits()
        } else {
            mapControl.hideAllTextMapLabels()
            mapControl.hideAllImageMapLabels()
        }
    }
    
}

struct JMapCanvasView: UIViewRepresentable {
    
    var canvas: JMapCanvas = JMapCanvas(frame: .zero)
    
    /// Make coordinator
    /// - Returns: JMapCanvasView.Coordinator
    /// Make coordinator.
    func makeCoordinator() -> JMapCanvasView.Coordinator {
        Coordinator(self)
    }
    
    /// Make u i view.
    /// - Parameters:
    ///   - context: Parameter description
    /// - Returns: JMapCanvas
    func makeUIView(context: Context)-> JMapCanvas {
        JMapManager.shared.canvas = canvas
        JMapManager.shared.initialization()
        return canvas
    }
    
    /// Update u i view.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - context: Parameter description
    func updateUIView(_ uiView: JMapCanvas, context: UIViewRepresentableContext<JMapCanvasView>) {}
    
    final class Coordinator: NSObject {
        var parent: JMapCanvasView
        /// _ parent:  j map canvas view
        /// Initializes a new instance.
        /// - Parameters:
        ///   - parent: JMapCanvasView
        init(_ parent: JMapCanvasView){
            self.parent = parent
        }
    }
}
