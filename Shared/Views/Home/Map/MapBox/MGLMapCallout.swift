//
//  MGLMapCallout.swift
//

import Foundation
import Combine
import Mapbox
import SwiftUI

class CustomCalloutViewManager: ObservableObject {
    
    @Published var pubCalloutAgencyImages: [UIImage] = []
    var calloutView: CustomCalloutView?
    
    public static var shared: CustomCalloutViewManager = {
        let mgr = CustomCalloutViewManager()
        return mgr
    }()
    
}

class CustomBusCalloutView: UIView, MGLCalloutView  {

    var representedObject: MGLAnnotation

    // Allow the callout to remain open during panning.
    let dismissesAutomatically: Bool = false
    let isAnchoredToAnnotation: Bool = true

    // This is used to indicate the callout is open or not
    var isOpened = false

    // Required by MGLCalloutView protocol
    lazy var leftAccessoryView = UIView()
    lazy var rightAccessoryView = UIView()

    /// Center.
    /// - Parameters:
    ///   - CGPoint: Parameter description
    override var center: CGPoint {
        set {
            var newCenter = newValue
            newCenter.y -= bounds.midY
            super.center = newCenter
        }
        get {
            return super.center
        }
    }

    weak var delegate: MGLCalloutViewDelegate?

    let tipHeight: CGFloat = 10.0
    let tipWidth: CGFloat = 20.0

    let mainBody: UIView
    var calloutTitle: String = ""
    var numberOfLines = 2
    var bodyHeight = 50.0

    /// Represented object:  m g l annotation, title:  string
    /// Initializes a new instance.
    /// - Parameters:
    ///   - representedObject: MGLAnnotation
    ///   - title: String
    required init(representedObject: MGLAnnotation, title: String) {
        let components = title.components(separatedBy: "\n")
        numberOfLines = components.count
        bodyHeight = Double(numberOfLines * 25)
        self.representedObject = representedObject
        self.mainBody = UIView(frame: CGRect(x:0, y:0, width:300, height:bodyHeight))
        self.calloutTitle = title
        /// Frame: .zero
        /// Initializes a new instance.2
        /// - Parameters:
        ///   - frame: .zero
        super.init(frame: .zero)

        backgroundColor = .clear

        mainBody.backgroundColor = .white
        mainBody.tintColor = .white
        mainBody.layer.cornerRadius = 10.0
        mainBody.layer.shadowColor = UIColor.black.cgColor
        mainBody.layer.shadowOpacity = 1
        mainBody.layer.shadowOffset = CGSize(width: 1, height: 1)
        mainBody.layer.shadowRadius = 5
        
        preprareElements()

        addSubview(mainBody)
    }
    
    /// Initializes a new instance.
    /// - Parameters:
    ///   - coder: NSCoder
    required init?(coder: NSCoder) {
        /// Coder:) has not been implemented"
        /// Initializes a new instance.
        /// - Parameters:

        ///   - "init(coder: 
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Preprare elements
    /// Preprare elements.
    private func preprareElements(){
        let areaPadding:CGFloat = 20
        let areaWidth = self.mainBody.frame.size.width - areaPadding
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.frame = CGRect(x: 10, y: 0, width: areaWidth - 35, height: bodyHeight)
        titleLabel.numberOfLines = numberOfLines
        titleLabel.font = UIFont.systemFont(ofSize: 13)
        titleLabel.text = calloutTitle
        titleLabel.textColor = UIColor.black
        mainBody.addSubview(titleLabel)
        
        let cancelButton = UIButton(frame: CGRect(x: areaWidth - 15, y: 0, width: 30, height: 40))
        guard let cancleImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .heavy)) else {return}
        cancelButton.setImage(cancleImage.resizeImage(19, 17), for: .normal)
        cancelButton.addTarget(self, action: #selector(tapToCancel(_:)), for: .touchUpInside)
        mainBody.addSubview(cancelButton)
    }
    
    /// Tap to cancel.
    /// - Parameters:
    ///   - _: Parameter description
    @objc public func tapToCancel(_ sender: UIGestureRecognizer){
        dismissCallout(animated: true)
    }
    
    // MARK: - MGLCalloutView API
    /// Presents callout.
    /// - Parameters:
    ///   - rect: CGRect
    ///   - view: UIView
    ///   - constrainedRect: CGRect
    ///   - animated: Bool
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {

        delegate?.calloutViewWillAppear?(self)

        view.addSubview(self)
        mainBody.isUserInteractionEnabled = true

        // Prepare our frame, adding extra space at the bottom for the tip.
        let frameWidth = mainBody.bounds.size.width
        let frameHeight = mainBody.bounds.size.height + tipHeight
        let frameOriginX = rect.origin.x + (rect.size.width/2.0) - (frameWidth/2.0)
        let frameOriginY = rect.origin.y - frameHeight
        frame = CGRect(x: frameOriginX, y: frameOriginY, width: frameWidth, height: frameHeight)

        if animated {
            alpha = 0

            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.alpha = 1
                strongSelf.delegate?.calloutViewDidAppear?(strongSelf)
            }
        } else {
            delegate?.calloutViewDidAppear?(self)
        }
        
        isOpened = true
    }

    /// Dismiss callout.
    /// - Parameters:
    ///   - animated: Parameter description
    /// Dismisses callout.
    func dismissCallout(animated: Bool) {
        
        if superview != nil && isOpened == true{
            removeFromSuperview()
            isOpened = false
        }
    }
    
}


typealias VoidAction = (() -> Void)

class CustomCalloutView: UIView, MGLCalloutView  {
	var representedObject: MGLAnnotation

	// Allow the callout to remain open during panning.
	let dismissesAutomatically: Bool = false
	let isAnchoredToAnnotation: Bool = true

	// This is used to indicate the callout is open or not
	var isOpened = false

	// Dismiss callback
	var calloutDismissCompleted:(VoidAction)?

    // stopViewer button pressed
    var stopViewerAction: VoidAction?

	// Required by MGLCalloutView protocol
	lazy var leftAccessoryView = UIView()
	lazy var rightAccessoryView = UIView()

 /// Center.
 /// - Parameters:
 ///   - CGPoint: Parameter description
	override var center: CGPoint {
		set {
			var newCenter = newValue
			newCenter.y -= bounds.midY
			super.center = newCenter
		}
		get {
			return super.center
		}
	}

	weak var delegate: MGLCalloutViewDelegate?

	let tipHeight: CGFloat = 10.0
	let tipWidth: CGFloat = 20.0

	let mainBody: UIView
	var calloutTitle: String = ""
	var stopID: String = ""
	var displayStopCode: String = ""
    
    var titleButton: UIButton?
    var horizentalViewLine1: UIView?


 /// Represented object:  m g l annotation, title:  string, stop i d:  string, display stop code:  string
 /// Initializes a new instance.
 /// - Parameters:
 ///   - representedObject: MGLAnnotation
 ///   - title: String
 ///   - stopID: String
 ///   - displayStopCode: String
	required init(representedObject: MGLAnnotation, title: String, stopID: String, displayStopCode: String) {
		self.representedObject = representedObject
		self.stopID = stopID
		self.displayStopCode = displayStopCode
        self.mainBody = UIView(frame: CGRect(x:0,
                                             y:0,
                                             width: stopID.count > 0 ? ScreenSize.width() > 330 ? 330 : 300 : 300,
                                             height:stopID.count > 0 ? LiveRouteManager.shared.pubIsRouteActivated ? 95 : 140 : LiveRouteManager.shared.pubIsRouteActivated ? 80 : 115))
		self.calloutTitle = title
  /// Frame: .zero
  /// Initializes a new instance.
  /// - Parameters:
  ///   - frame: .zero
		super.init(frame: .zero)

		backgroundColor = .clear

		mainBody.backgroundColor = .white
		mainBody.tintColor = .white
		mainBody.layer.cornerRadius = 10.0
		mainBody.layer.shadowColor = UIColor.black.cgColor
		mainBody.layer.shadowOpacity = 1
		mainBody.layer.shadowOffset = CGSize(width: 1, height: 1)
		mainBody.layer.shadowRadius = 5
		
		preprareElements()

		addSubview(mainBody)
	}
    
    func setupAgencyIcons(agencyIcons: [UIImage?]) {
        
        if !agencyIcons.isEmpty {
            titleButton?.center.y = (titleButton?.center.y ?? 20) + 20
            horizentalViewLine1?.center.y = (horizentalViewLine1?.center.y ?? 20) + 10
        }
        
        for index in 0..<agencyIcons.count {
            let agencyImageButton = UIButton(frame: CGRect(x: (index == 0 ? 10 : 10 + (index * 30)), y: 8, width: 30, height: 30))
            guard let icon = agencyIcons[index] else {return}
            agencyImageButton.setImage(icon.resizeImage(30, 30), for: .normal)
            mainBody.addSubview(agencyImageButton)
        }

    }

    
    /// Preprare elements
    /// Preprare elements.
    private func preprareElements(){
        let areaPadding:CGFloat = 20
        let areaWidth = self.mainBody.frame.size.width - areaPadding
        let offset:CGFloat = areaPadding/2
        let labelGeneralHeight:CGFloat = 30
        
        let stopIDLabelWidth: CGFloat = 120
        let viewButtonWidth: CGFloat = 80
        
        for agencyImage in CustomCalloutViewManager.shared.pubCalloutAgencyImages {
            let agencyImageButton = UIButton(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
            let cancleImage = agencyImage
            agencyImageButton.setImage(cancleImage.resizeImage(20, 20), for: .normal)
            mainBody.addSubview(agencyImageButton)
        }

        
        // Title Label
        titleButton = UIButton(type: .custom)
        titleButton?.frame = CGRect(x: offset, y: offset, width: areaWidth - 20, height: 50)
        titleButton?.titleLabel?.numberOfLines = 2
        titleButton?.titleLabel?.textAlignment = NSTextAlignment.left
        titleButton?.contentHorizontalAlignment = .left;
        titleButton?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        titleButton?.setTitle(calloutTitle, for: .normal)
        titleButton?.setTitleColor(UIColor.black, for: .normal)
        titleButton?.addTarget(self, action: #selector(clickedTitleButtonView(_:)), for: .touchUpInside)
        if let titleButton = titleButton {
            mainBody.addSubview(titleButton)
        }

        let cancelButton = UIButton(frame: CGRect(x: areaWidth - offset, y: offset, width: 22, height: 20))
        guard let cancleImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .heavy)) else {return}
        cancelButton.setImage(cancleImage.resizeImage(22, 20), for: .normal)

        cancelButton.addTarget(self, action: #selector(tapToCancel(_:)), for: .touchUpInside)
        mainBody.addSubview(cancelButton)
        
        // Stop ID and view
        if stopID.count > 0{
            // Horizontal Line 1
            horizentalViewLine1 = UIView(frame: CGRect(x: offset, y: 60, width: 0, height: labelGeneralHeight))
            if let horizentalViewLine1 = horizentalViewLine1 {
                mainBody.addSubview(horizentalViewLine1)
            }
            let stopLabel = UILabel(frame: CGRect(x: 0, y: 0, width: widthOfString("Stop ID:".localized(), font: UIFont.systemFont(ofSize: 12)), height: labelGeneralHeight))
            stopLabel.text = "Stop ID:".localized()
            stopLabel.font = UIFont.boldSystemFont(ofSize: 12)
            stopLabel.heightAnchor.constraint(equalToConstant: labelGeneralHeight).isActive = true
            stopLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
            horizentalViewLine1?.addSubview(stopLabel)
            
            let stopIDLabel = UILabel(frame: CGRect(x: widthOfString("Stop ID:".localized(), font: UIFont.systemFont(ofSize: 12)), y: 0, width: stopIDLabelWidth, height: labelGeneralHeight))
            stopIDLabel.text = displayStopCode
            stopIDLabel.font = UIFont.boldSystemFont(ofSize: 12)
            stopIDLabel.heightAnchor.constraint(equalToConstant: labelGeneralHeight).isActive = true
            stopIDLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
            horizentalViewLine1?.addSubview(stopIDLabel)
        }

        // Hide the Action Buttons from the Callout View when LiveTracking is Enabled.
        if !LiveRouteManager.shared.pubIsRouteActivated{
            
            // Horizontal Line 2
            let horizentalStackViewLine2 = UIStackView(frame: CGRect(x: offset, y: stopID.count > 0 ? 100 : 70, width: areaWidth, height: labelGeneralHeight))
            horizentalStackViewLine2.translatesAutoresizingMaskIntoConstraints = true
            horizentalStackViewLine2.axis = .horizontal
            horizentalStackViewLine2.alignment = .center
            
            if stopID.count > 0{
                
                let StopViewerStackView = UIStackView(frame: CGRect(x: 0, y: 0, width: areaWidth/2, height: labelGeneralHeight))
                StopViewerStackView.clipsToBounds = true
                StopViewerStackView.layer.cornerRadius = 5
                StopViewerStackView.layer.borderWidth = 1
                StopViewerStackView.layer.borderColor = UIColor.lightGray.cgColor
                
                let stopViewButton = UIButton(type: .custom)
                stopViewButton.frame = CGRect(x: 0, y: 0, width: viewButtonWidth, height: labelGeneralHeight)
                stopViewButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                stopViewButton.setImage(UIImage(named: "ic_stop")?.resizeImage(25, 25), for: .normal)
                stopViewButton.setTitle(" Stop Viewer".localized(), for: .normal)
                stopViewButton.setTitleColor(UIColor.blue, for: .normal)
                stopViewButton.widthAnchor.constraint(lessThanOrEqualToConstant: 200).isActive = true
                stopViewButton.addTarget(self, action: #selector(clickedStopView(_:)), for: .touchUpInside)
                StopViewerStackView.addArrangedSubview(spacerView(width: 4, height: labelGeneralHeight))
                StopViewerStackView.addArrangedSubview(stopViewButton)
                StopViewerStackView.addArrangedSubview(spacerView(width: 6, height: labelGeneralHeight))
                horizentalStackViewLine2.addArrangedSubview(StopViewerStackView)
                horizentalStackViewLine2.addArrangedSubview(spacerView(width: 15, height: labelGeneralHeight))
                
            }
            else{
                horizentalStackViewLine2.addArrangedSubview(spacerView(width: 40, height: labelGeneralHeight))
            }
            // From Here
            let fromHereStackView = UIStackView(frame: CGRect(x: 0, y: 0, width: areaWidth/2, height: labelGeneralHeight))
            fromHereStackView.clipsToBounds = true
            fromHereStackView.layer.cornerRadius = 5
            fromHereStackView.layer.borderWidth = 1
            fromHereStackView.layer.borderColor = UIColor.lightGray.cgColor
            
            let  fromViewButton = UIButton(frame: CGRect(x: 0, y: 0, width: viewButtonWidth, height: labelGeneralHeight))
            fromViewButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            fromViewButton.setImage(UIImage(named: "ic_origin")?.resizeImage(20, 20), for: .normal)
            fromViewButton.setTitle(" From here".localized(), for: .normal)
            fromViewButton.setTitleColor(UIColor.blue, for: .normal)
            fromViewButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
            fromViewButton.addTarget(self, action: #selector(fromHere(_:)), for: .touchUpInside)
            fromHereStackView.addArrangedSubview(spacerView(width: 6, height: labelGeneralHeight))
            fromHereStackView.addArrangedSubview(fromViewButton)
            fromHereStackView.addArrangedSubview(spacerView(width: 6, height: labelGeneralHeight))
            horizentalStackViewLine2.addArrangedSubview(fromHereStackView)
            
            let toHereStackView = UIStackView(frame: CGRect(x: 0, y: 0, width: areaWidth/2, height: labelGeneralHeight))
            toHereStackView.clipsToBounds = true
            toHereStackView.layer.cornerRadius = 5
            toHereStackView.layer.borderWidth = 1
            toHereStackView.layer.borderColor = UIColor.lightGray.cgColor
            
            let  toViewButton = UIButton(frame: CGRect(x: 0, y:0, width: viewButtonWidth, height: labelGeneralHeight))
            toViewButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            toViewButton.setImage(UIImage(named: "ic_destination")?.resizeImage(20, 20), for: .normal)
            toViewButton.setTitle(" To here".localized(), for: .normal)
            toViewButton.setTitleColor(UIColor.blue, for: .normal)
            toViewButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
            toViewButton.addTarget(self, action: #selector(toHere(_:)), for: .touchUpInside)
            toHereStackView.addArrangedSubview(spacerView(width: 6, height: labelGeneralHeight))
            toHereStackView.addArrangedSubview(toViewButton)
            toHereStackView.addArrangedSubview(spacerView(width: 6, height: labelGeneralHeight))
            horizentalStackViewLine2.addArrangedSubview(spacerView(width: 15, height: labelGeneralHeight))
            horizentalStackViewLine2.addArrangedSubview(toHereStackView)
            
            horizentalStackViewLine2.addArrangedSubview(spacerView(width: stopID.count > 0 ? 0 : 50, height: labelGeneralHeight))
            mainBody.addSubview(horizentalStackViewLine2)
        }
    }
	
    func widthOfString(_ text: String, font: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width + 10
    }

    
    /// Spacer view.
    /// - Parameters:
    ///   - width: Parameter description
    ///   - height: Parameter description
    /// - Returns: UIView
    private func spacerView(width: CGFloat, height: CGFloat) -> UIView {
        let separatorView = UIView(frame: .zero)
        separatorView.backgroundColor = UIColor.clear
        separatorView.heightAnchor.constraint(equalToConstant: height).isActive = true
        separatorView.widthAnchor.constraint(equalToConstant: width).isActive = true
        return separatorView
    }
    
    /// Separator view.
    /// - Parameters:
    ///   - height: Parameter description
    /// - Returns: UIView
    private func separatorView(height: CGFloat) -> UIView {
        let separatorView = UIView(frame: .zero)
        separatorView.backgroundColor = UIColor.black
        separatorView.heightAnchor.constraint(equalToConstant: height).isActive = true
        separatorView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        return separatorView
    }
	
 /// From here.
 /// - Parameters:
 ///   - _: Parameter description
	@objc public func fromHere(_ sender: UIGestureRecognizer){
		let latitude = representedObject.coordinate.latitude
		let longitude = representedObject.coordinate.longitude
        MapManager.shared.pubShowUsersCurrentLocation = false
		MapManager.shared.fromToDestionation(isFrom: true, latitude: latitude, longitude: longitude, title: self.calloutTitle) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if TabBarMenuManager.shared.currentItemTab != .planTrip{
                    TabBarMenuManager.shared.currentItemTab = .planTrip
                    TabBarMenuManager.shared.currentViewTab = .planTrip
                    MapManager.shared.cleanPlotRoute()
                }
                self.dismissCallout(animated:false, action: self.calloutDismissCompleted)
				let location = Coordinate(latitude: latitude, longitude: longitude)
				MapManager.shared.previewFromMarker(coordinates: location)
            }
		}
        if StopViewerViewModel.shared.pubIsShowingStopViewer{
            MapManager.shared.removeStopMarker()
            StopViewerViewModel.shared.pubIsShowingStopViewer = false
        }
        TabBarMenuManager.shared.currentItemTab = .planTrip
        TabBarMenuManager.shared.currentViewTab = .planTrip
        MapManager.shared.cleanPlotRoute()
        TripPlanningManager.shared.isItineraryResult = true
        TripPlanningManager.shared.pubShowFullPage = true
        if LiveRouteManager.shared.pubIsRouteActivated {
            // If we are in the activated route mode, then, we disable it
            LiveRouteManager.shared.resetLiveTracking()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            MapManager.shared.reDrawFromToMarkers()
        }
        
	}
	
 /// To here.
 /// - Parameters:
 ///   - _: Parameter description
	@objc public func toHere(_ sender: UIGestureRecognizer){
		let latitude = representedObject.coordinate.latitude
		let longitude = representedObject.coordinate.longitude
		MapManager.shared.fromToDestionation(isFrom: false, latitude: latitude, longitude: longitude, title: self.calloutTitle) {
			DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if TabBarMenuManager.shared.currentItemTab != .planTrip{
                    TabBarMenuManager.shared.currentItemTab = .planTrip
                    TabBarMenuManager.shared.currentViewTab = .planTrip
                    MapManager.shared.cleanPlotRoute()
                }
                self.dismissCallout(animated:false, action: self.calloutDismissCompleted)
				let location = Coordinate(latitude: latitude, longitude: longitude)
				MapManager.shared.previewToMarker(coordinates: location)
			}
		}
        if StopViewerViewModel.shared.pubIsShowingStopViewer{
            MapManager.shared.removeStopMarker()
            StopViewerViewModel.shared.pubIsShowingStopViewer = false
        }
        TabBarMenuManager.shared.currentItemTab = .planTrip
        TabBarMenuManager.shared.currentViewTab = .planTrip
        MapManager.shared.cleanPlotRoute()
        TripPlanningManager.shared.isItineraryResult = true
        TripPlanningManager.shared.pubShowFullPage = true
        if LiveRouteManager.shared.pubIsRouteActivated {
            // If we are in the activated route mode, then, we disable it
            LiveRouteManager.shared.resetLiveTracking()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            MapManager.shared.reDrawFromToMarkers()
        }
        
	}
	
 /// Clicked title button view.
 /// - Parameters:
 ///   - _: Parameter description
	@objc public func clickedTitleButtonView(_ sender: UIGestureRecognizer){
        dismissCallout(animated: false, action: calloutDismissCompleted)
	}
	
 /// Clicked stop view.
 /// - Parameters:
 ///   - _: Parameter description
	@objc public func clickedStopView(_ sender: UIGestureRecognizer){
        dismissCallout(animated: false, action: stopViewerAction)
	}
	
 /// Tap to cancel.
 /// - Parameters:
 ///   - _: Parameter description
	@objc public func tapToCancel(_ sender: UIGestureRecognizer){
        dismissCallout(animated: false, action: calloutDismissCompleted)
	}

 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: NSCoder
	required init?(coder decoder: NSCoder) {
  /// Coder:) has not been implemented"
  /// Initializes a new instance.
  /// - Parameters:

  ///   - "init(coder: 
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - MGLCalloutView API
 /// Presents callout.
 /// - Parameters:
 ///   - rect: CGRect
 ///   - view: UIView
 ///   - constrainedRect: CGRect
 ///   - animated: Bool
	func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {

		delegate?.calloutViewWillAppear?(self)

		view.addSubview(self)
		mainBody.isUserInteractionEnabled = true

		// Prepare our frame, adding extra space at the bottom for the tip.
		let frameWidth = mainBody.bounds.size.width
		let frameHeight = mainBody.bounds.size.height + tipHeight
		let frameOriginX = rect.origin.x + (rect.size.width/2.0) - (frameWidth/2.0)
		let frameOriginY = rect.origin.y - frameHeight
		frame = CGRect(x: frameOriginX, y: frameOriginY, width: frameWidth, height: frameHeight)

		if animated {
			alpha = 0

			UIView.animate(withDuration: 0.2) { [weak self] in
				guard let strongSelf = self else {
					return
				}

				strongSelf.alpha = 1
				strongSelf.delegate?.calloutViewDidAppear?(strongSelf)
			}
		} else {
			delegate?.calloutViewDidAppear?(self)
		}
		
		isOpened = true
	}

 /// Dismiss callout.
 /// - Parameters:
 ///   - animated: Parameter description
 /// Dismisses callout.
	func dismissCallout(animated: Bool) {
		if (superview != nil) {
			removeFromSuperview()
			isOpened = false
		}
		
		// remove the pin in the map
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			let mapView = MapManager.shared.map().mapView
			mapView.deselectAnnotation(mapView.selectedAnnotations.first, animated: false)
		}
	}
    
    /// Dismiss callout.
    /// - Parameters:
    ///   - animated: Parameter description
    ///   - action: Parameter description
    func dismissCallout(animated: Bool, action: VoidAction?) {
        dismissCallout(animated: animated)
        action?()
    }

	// MARK: - Callout interaction handlers
 /// Checks if callout tappable.
 /// - Returns: Bool
	func isCalloutTappable() -> Bool {
		if let delegate = delegate {
			if delegate.responds(to: #selector(MGLCalloutViewDelegate.calloutViewShouldHighlight)) {
				return delegate.calloutViewShouldHighlight!(self)
			}
		}
		return false
	}

 /// Callout tapped
 /// Callout tapped.
	@objc func calloutTapped() {
		if isCalloutTappable() && delegate!.responds(to: #selector(MGLCalloutViewDelegate.calloutViewTapped)) {
			delegate!.calloutViewTapped!(self)
		}
	}

	// MARK: - Custom view styling
 /// Draws.
 /// - Parameters:
 ///   - rect: CGRect
	override func draw(_ rect: CGRect) {
		// Draw the pointed tip at the bottom.
		let fillColor: UIColor = .darkGray

		let tipLeft = rect.origin.x + (rect.size.width / 2.0) - (tipWidth / 2.0)
		let tipBottom = CGPoint(x: rect.origin.x + (rect.size.width / 2.0), y: rect.origin.y + rect.size.height)
		let heightWithoutTip = rect.size.height - tipHeight - 1

		let currentContext = UIGraphicsGetCurrentContext()!

		let tipPath = CGMutablePath()
		tipPath.move(to: CGPoint(x: tipLeft, y: heightWithoutTip))
		tipPath.addLine(to: CGPoint(x: tipBottom.x, y: tipBottom.y))
		tipPath.addLine(to: CGPoint(x: tipLeft + tipWidth, y: heightWithoutTip))
		tipPath.closeSubpath()

		fillColor.setFill()
		currentContext.addPath(tipPath)
		currentContext.fillPath()
	}
}
