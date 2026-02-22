//
//  UIImageExtension.swift
//

import Foundation
import UIKit

extension UIImage {
	
 /// Initializes a new instance.
 /// - Parameters:
 ///   - color: UIColor
 ///   - size: CGSize = CGSize(width: 1, height: 1
	convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
	   let rect = CGRect(origin: .zero, size: size)
	   UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
	   color.setFill()
	   UIRectFill(rect)
	   let image = UIGraphicsGetImageFromCurrentImageContext()
	   UIGraphicsEndImageContext()
	   guard let cgImage = image?.cgImage else { return nil }
    /// Cg image: cg image
    /// Initializes a new instance.
    /// - Parameters:
    ///   - cgImage: cgImage
	   self.init(cgImage: cgImage)
	 }
	
 /// Resize image.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - opaque: Parameter description
 /// - Returns: UIImage
	func resizeImage(_ width:CGFloat,_ height: CGFloat, opaque: Bool = false) -> UIImage {
			
		let width: CGFloat = width
		let height: CGFloat = height
		var newImage: UIImage
		
		if #available(iOS 10.0, *) {
			let renderFormat = UIGraphicsImageRendererFormat.default()
			renderFormat.opaque = opaque
			let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
			newImage = renderer.image {
				(context) in
				self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
			}
		} else {
			UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
			self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
			newImage = UIGraphicsGetImageFromCurrentImageContext()!
			UIGraphicsEndImageContext()
		}
		
		return newImage
	}
    
    /// Image with color.
    /// - Parameters:
    ///   - tintColor: Parameter description
    /// - Returns: UIImage
    func imageWithColor(tintColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)

        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0);
        context.setBlendMode(.normal)

        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height) as CGRect
        context.clip(to: rect, mask: self.cgImage!)
        tintColor.setFill()
        context.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }
    
    /// Add background to image.
    /// - Parameters:
    ///   - backgroundColor: Parameter description
    /// - Returns: UIImage?
    func addBackgroundToImage(backgroundColor: UIColor) -> UIImage? {
        let bigSize = CGSize(width: 40, height: 40)
        let smallSize = CGSize(width: 20, height: 20)
        // Create a new bitmap-based graphics context
        UIGraphicsBeginImageContextWithOptions(bigSize, true, self.scale)
        
        // Draw the background color
        backgroundColor.setFill()
        UIRectFill(CGRect(origin: .zero, size: bigSize))
         
        // Draw the image on top of the background
        self.draw(in: CGRect(origin: CGPoint(x: 10, y: 10), size: smallSize))
        
        // Get the combined image from the graphics context
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the graphics context
        UIGraphicsEndImageContext()
        
        return combinedImage
    }
    
    /// Round corners.
    /// - Parameters:
    ///   - cornerRadius: Parameter description
    /// - Returns: UIImage?
    func roundCorners(cornerRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        
        let rect = CGRect(origin: .zero, size: self.size)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        
        path.addClip()
        self.draw(in: rect)
        
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return roundedImage
    }
}
