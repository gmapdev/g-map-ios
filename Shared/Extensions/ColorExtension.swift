//
//  ColorExtension.swift
//

import Foundation
import SwiftUI

extension UIColor {
 /// Initializes a new instance.
 /// - Parameters:
 ///   - hex: String

 /// - Parameters:
	public convenience init?(hex: String) {
		let r, g, b, a: CGFloat

		if hex.hasPrefix("#") {
			let start = hex.index(hex.startIndex, offsetBy: 1)
			let hexColor = String(hex[start...])

			if hexColor.count == 8 {
				let scanner = Scanner(string: hexColor)
				var hexNumber: UInt64 = 0

				if scanner.scanHexInt64(&hexNumber) {
					r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
					g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
					b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
					a = CGFloat(hexNumber & 0x000000ff) / 255

     /// Red: r, green: g, blue: b, alpha: a
     /// Initializes a new instance.
     /// - Parameters:
     ///   - red: r
     ///   - green: g
     ///   - blue: b
     ///   - alpha: a
					self.init(red: r, green: g, blue: b, alpha: a)
					return
				}
			}
		}

		return nil
	}
}

extension Color {
 /// Hex:  string
 /// Initializes a new instance.
 /// - Parameters:
 ///   - hex: String
	init(hex: String) {
		var actualHex = hex
		
		//removing sharp #
		if hex.hasPrefix("#") {
			let start = hex.index(hex.startIndex, offsetBy: 1)
			actualHex = String(hex[start...])
		}
		
		let scanner = Scanner(string: actualHex)
		var rgbValue: UInt64 = 0
		scanner.scanHexInt64(&rgbValue)

		let r = (rgbValue & 0xff0000) >> 16
		let g = (rgbValue & 0xff00) >> 8
		let b = rgbValue & 0xff

  /// Red:  double(r) / 0xff, green:  double(g) / 0xff, blue:  double(b) / 0xff
  /// Initializes a new instance.
  /// - Parameters:
  ///   - red: Double(r
		self.init(red: Double(r) / 0xff, green: Double(g) / 0xff, blue: Double(b) / 0xff)
		
	}
}
