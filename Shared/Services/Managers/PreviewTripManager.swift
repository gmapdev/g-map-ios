//
//  PreviewTripManager.swift
//

import Foundation
import SwiftUI
import Mapbox

public struct PreviewTripStep {
	
	// This is the preview step Id which is assigned by the Itineray itself when the object is created.
	public var previewStepId: String
	
	// This is used to track what is the index for the parent element, normally, it is the leg section.
	public var parentStepIndex: Int
	
	// This is the text that we need to display for this step
	public var description: String
	
	// This is the sign for this step of the directions
	public var directions: String
	
	// This is used to define whether we need image for this step
	public var image: String?
	
	// This is used to define which mode current step is.
	public var mode: String
    
    // This is used to hold Distance for current step
    public var distance: Double?
	
	// Trip Leg for zoom in / zoom out
	public var leg: GraphQLTripLeg
    
}

class PreviewTripManager: ObservableObject {
	
	/// TTS is enabled, when we move to previous/next, we need to announce the step
	@Published var pubEnableTTSText: Bool = false
	@Published var pubLastUpdated = Date().timeIntervalSince1970
	
	/// This is used to define which step of the current preview is presented.
	public var currentStepIndex: Int = 0
	
	/// This variable hold all the steps for the current selected preview trip
	public var currentTripSteps = [PreviewTripStep]()
	
 /// Shared.
 /// - Parameters:
 ///   - PreviewTripManager: Parameter description
	public static var shared: PreviewTripManager = {
		let mgr = PreviewTripManager()
		return mgr
	}()
    
    /// Is first leg first step
    /// - Returns: Bool
    /// Checks if first leg first step.
    public func isFirstLegFirstStep() -> Bool{
        if currentStepIndex - 1 < 0 {
            return true
        }else{
            return false
        }
    }
    /// Is last leg last step
    /// - Returns: Bool
    /// Checks if last leg last step.

    /// - Returns: Bool
    public func isLastLegLastStep() -> Bool{
        if currentStepIndex == currentTripSteps.count - 1{
            return true
        }else{
            return false
        }
    }
	
 /// Previous step
 /// - Returns: String
 /// Previous step.
	public func previousStep() -> String {
		if currentStepIndex - 1 >= 0 {
			currentStepIndex = currentStepIndex - 1
			self.pubLastUpdated = Date().timeIntervalSince1970
		}
		
		let ctrip = currentTripSteps[self.currentStepIndex]

		if self.pubEnableTTSText {
			TravelIQAudio.shared.stop()
			TravelIQAudio.shared.playAudio(fromText: ctrip.description, parameters: nil, highPriority: false, ignoreError: true){ state, errorMessage, parameters in}
		}
		
		showSegment(leg: ctrip.leg)
		
		return ctrip.previewStepId
	}
	
 /// Next step
 /// - Returns: String
 /// Next step.
	public func nextStep() -> String {
		
		if currentStepIndex + 1 < currentTripSteps.count {
			currentStepIndex = currentStepIndex + 1
			self.pubLastUpdated = Date().timeIntervalSince1970
		}
		
		let ctrip = currentTripSteps[self.currentStepIndex]
		
		if self.pubEnableTTSText {
			TravelIQAudio.shared.stop()
			TravelIQAudio.shared.playAudio(fromText: ctrip.description, parameters: nil, highPriority: false, ignoreError: true){ state, errorMessage, parameters in}
		}
		
		showSegment(leg: ctrip.leg)
		
		return ctrip.previewStepId
	}
	
	/// This function is used to adjust the preview item text
 /// Adjust first selected section.
 /// - Parameters:
 ///   - previewStepId: String
	public func adjustFirstSelectedSection(previewStepId: String) {
		for i in 0..<self.currentTripSteps.count {
			let step = self.currentTripSteps[i]
			if let psid = step.leg.leg?.previewStepId, psid == previewStepId {
				currentStepIndex = i
				self.pubLastUpdated = Date().timeIntervalSince1970
				break
			}
		}
	}
	
	/// Reset and calcualte the current preview steps from step index 0
 /// Calculates current preview steps.
 /// - Parameters:
 ///   - itinerary: OTPItinerary
	public func calculateCurrentPreviewSteps(itinerary: OTPItinerary){
		
		// clear the steps for the new itinerary calculation.
		self.currentTripSteps.removeAll()
		self.currentStepIndex = 0
		
		// start to populate the steps
		var stepIndex = 0
		let legs = itinerary.legs?.map({GraphQLTripLeg(leg: $0)}) ?? []
		for i in 0..<legs.count {
			if let leg = legs[i].leg {
				let previewStepId = leg.previewStepId ?? "n/a"
				let parentStepIndex = stepIndex
				let mode = leg.searchMode?.mode ?? ""
				let modeDesc = mode.count > 0 ? "\(mode) to" : ""
				let legName = legName(leg: legs[i])
				let description = "\(modeDesc) \(legName)"
				let stepParentItem = PreviewTripStep(previewStepId: previewStepId, parentStepIndex: stepIndex, description: description, directions: "", mode: mode, leg: GraphQLTripLeg(leg:leg))
				
				// add the main section step item for this instruction
				self.currentTripSteps.append(stepParentItem)
				
				// decide to add the step instruction for the preview
				if let steps = leg.steps {
					for x in 0..<steps.count {
						let step = steps[x]
						let gqlStep = GraphQLTripDirection(step: step)
                        let direction = directionDescription(tripDirection:gqlStep, withDistance: false)
						let image = getDirectionImage(tripDirection: gqlStep)
                        let stepItem = PreviewTripStep(previewStepId: previewStepId, parentStepIndex: parentStepIndex, description: direction, directions: direction, image:image, mode: mode,distance: step.distance, leg: GraphQLTripLeg(leg:leg))
						self.currentTripSteps.append(stepItem)
						stepIndex = stepIndex + 1
					}
				}else{
					stepIndex = stepIndex + 1
				}
			}
		}
	}
	
 /// Get direction image.
 /// - Parameters:
 ///   - tripDirection: Parameter description
 /// - Returns: String
	public func getDirectionImage(tripDirection: GraphQLTripDirection?) -> String {
		if let tripDirection = tripDirection, let step = tripDirection.step, let relativeDirection = step.relativeDirection {
			switch relativeDirection {
				case .depart: return "direction_straight_icon"
				case .left: return "direction_left_icon"
				case .right: return "direction_right_icon"
				case .uturnRight: return "direction_turn_right_icon"
				case .uturnLeft: return "direction_turn_left_icon"
				case .hardLeft: return "direction_left_hard_icon"
				case .hardRight: return "direction_right_hard_icon"
				case .slightlyLeft: return "direction_left_slight_icon"
				case .slightlyRight: return "direction_right_slight_icon"
				case .continue: return "direction_straight_icon"
				case .circleClockwise: return ""
				case .circleCounterclockwise: return ""
				case .elevator: return ""
				default: return ""
			}
		}
		return ""
	}
	
    /// Direction description.
    /// - Parameters:
    ///   - tripDirection: Parameter description
    ///   - withDistance: Parameter description
    /// - Returns: String
    public func directionDescription(tripDirection: GraphQLTripDirection?, withDistance : Bool = true) -> String{
		var description = ""
		if let tripDirection = tripDirection, let step = tripDirection.step{
            let distance = withDistance ? Helper.shared.formattedDistanceDescription(step.distance) : ""
			if step
				.relativeDirection == .depart {
                description = "Head %1 on %2 %3".localized("\((step.absoluteDirection?.rawValue.lowercased().capitalizingFirstLetter().replacingOccurrences(of: "_", with: " ") ?? "").localized())", "\(step.streetName ?? "")", distance)
				return description
			}
			let direction = step.relativeDirection?.rawValue.lowercased().capitalizingFirstLetter().replacingOccurrences(of: "_", with: " ")
			
            description = "%1 on %2 %3".localized("\((direction ?? "").localized())", "\(step.streetName ?? "")", distance)
			description = description.replacingOccurrences(of: "_", with: " ")
		}
		return description
	}
	
 /// Leg name.
 /// - Parameters:
 ///   - leg: Parameter description
 ///   - isFirst: Parameter description
 /// - Returns: String
	public func legName(leg: GraphQLTripLeg, isFirst: Bool = false) -> String {
		var name = leg.leg?.from?.name ?? "N/A"
		if isFirst {
			name = LiveRouteManager.shared.pubIsRouteActivated ? LiveRouteManager.shared.getFromNameOfTrip() : SearchManager.shared.from?.properties.label ?? ""
		}
		// MARK: Added this custom logic to fix the issue reported, may need to change in future
		if name == "Default vehicle type" {
			var returnTitle = ""
			if let leg = leg.leg, let from = leg.from, let retnal = from.rentalVehicle{
				if let network = retnal.network {
					if network == Network.birdSeattleWashington.rawValue {
						returnTitle = "Bird"
					}
					if network == Network.limeSeattle.rawValue {
						returnTitle = "LIME"
					}
					if network == Network.linkSeattle.rawValue {
						returnTitle = "LINK"
					}
				}
				if let vehicleType = retnal.vehicleType, let formFactor = vehicleType.formFactor, let propulsionType = vehicleType.propulsionType {
					if formFactor == .scooter && propulsionType == "ELECTRIC" {
						returnTitle = returnTitle.appending(" E-Scooter")
					}
					
					if formFactor == .bicycle {
						returnTitle = returnTitle.appending(" Shared bike")
					}
				}
				
			}
			return returnTitle
		}
		return name
	}
	
 /// Show segment.
 /// - Parameters:
 ///   - leg: Parameter description
 /// Shows segment.
	public func showSegment(leg: GraphQLTripLeg){
		let sw = CLLocationCoordinate2DMake(leg.leg?.from?.lat ?? 0.0, leg.leg?.from?.lon ?? 0.0)
		let ne = CLLocationCoordinate2DMake(leg.leg?.to?.lat ?? 0.0, leg.leg?.to?.lon ?? 0.0)
		let bounds = MGLCoordinateBounds(sw: sw, ne: ne)
		
		let centerRouteView = LiveRouteManager.shared.pubIsRouteActivated && LiveRouteManager.shared.pubIsPreviewMode
		DispatchQueue.main.async {
			let viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:0), bottomLeft: CGPoint(x:0, y: Helper.shared.getDeafultViewHeight(heightPosition: centerRouteView ? .middle : .bottom) ))
			let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
			MapManager.shared.setCenterArea(oriViewArea: viewArea,withGeoBounds: bounds, mapViewHeight: Helper.shared.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width, edgeInset: edgeInsets)
		}
	}
    
    
}
