//
//  SwiftUIAnimation.swift
//

import Foundation
import SwiftUI

struct FlyTransition: GeometryEffect {
    var pct: Double
    
    /// Animatable data.
    /// - Parameters:
    ///   - Double: Parameter description
    var animatableData: Double {
        get { pct }
        set { pct = newValue }
    }
    
    /// Effect value.
    /// - Parameters:
    ///   - size: Parameter description
    /// - Returns: ProjectionTransform
    func effectValue(size: CGSize) -> ProjectionTransform {

        let rotationPercent = pct
        let a = CGFloat(Angle(degrees: 90 * (1-rotationPercent)).radians)
        
        var transform3d = CATransform3DIdentity;
        transform3d.m34 = -1/max(size.width, size.height)
        
        transform3d = CATransform3DRotate(transform3d, a, 1, 0, 0)
        transform3d = CATransform3DTranslate(transform3d, -size.width/2.0, -size.height/2.0, 0)
        
        let affineTransform1 = ProjectionTransform(CGAffineTransform(translationX: size.width/2.0, y: size.height / 2.0))
        let affineTransform2 = ProjectionTransform(CGAffineTransform(scaleX: CGFloat(pct * 2), y: CGFloat(pct * 2)))
        
        if pct <= 0.5 {
            return ProjectionTransform(transform3d).concatenating(affineTransform2).concatenating(affineTransform1)
        } else {
            return ProjectionTransform(transform3d).concatenating(affineTransform1)
        }
    }
}

extension AnyTransition{
    /// Slide in and out.
    /// - Parameters:
    ///   - AnyTransition: Parameter description
    static var slideInAndOut: AnyTransition {
        get {
            let insertion = AnyTransition.move(edge: .trailing).combined(with: .opacity)
            let removal = AnyTransition.move(edge: .leading).combined(with: .opacity)
            return .asymmetric(
                insertion: insertion,
                removal: removal
            )
        }
    }
    
    /// Fly.
    /// - Parameters:
    ///   - AnyTransition: Parameter description
    static var fly: AnyTransition {
        get{
            AnyTransition.modifier(active: FlyTransition(pct: 0), identity: FlyTransition(pct: 1))
        }
    }
    
    /// Drop and bounce back.
    /// - Parameters:
    ///   - AnyTransition: Parameter description
    static var dropAndBounceBack: AnyTransition {
        get{
            let insertion = AnyTransition.move(edge: .top)
            let removal = AnyTransition.move(edge: .top)
            return .asymmetric(
                insertion: insertion,
                removal: removal
            )
        }
    }
    
    /// Slide up and slide down.
    /// - Parameters:
    ///   - AnyTransition: Parameter description
    static var slideUpAndSlideDown: AnyTransition {
        get {
            let insertion = AnyTransition.move(edge: .bottom)
            let removal = AnyTransition.move(edge: .bottom)
            return .asymmetric(
                insertion: insertion,
                removal: removal
            )
        }
    }
}
