//
//  SplashScreen.swift
//

import Foundation
import SwiftUI

struct SplashScreenItem {
    public var width: CGFloat
    public var height: CGFloat
    public var fileNameSuffix: String
}

struct SplashScreen: View {
    
    /// Define the environment related screen mode variables - Vertical
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    
    /// Define the environment related screen mode variables - Horizental
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    
    /// Define the logo ratio so that when the splash page get loaded, we can apply animation
    @State private var logoScaleSize:CGFloat = 1
    
    @State private var leftPanelX: CGFloat = 0
    @State private var rightPanelX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        return ZStack{
            GeometryReader { geo in
                VStack {
                    HStack{
                        Spacer()
                    }
                    Image(uiImage: SplashScreen.splashImage(size: geo.size)).resizable().aspectRatio(contentMode:.fill).frame(width:geo.size.width, height:geo.size.height).edgesIgnoringSafeArea(.all)
                    Spacer()
                }.edgesIgnoringSafeArea(.all)
            }
        }.edgesIgnoringSafeArea(.all)
    }
    
    /// This function is used to pull the proper splash image for the device
    /// Splash image.
    /// - Parameters:
    ///   - size: CGSize
    /// - Returns: UIImage
    public static func splashImage(size: CGSize)->UIImage{
        let availableSplashImages = SplashScreen.splashImageArray()
        let width = size.width
        let height = size.height
        let ratio:CGFloat = width/height
        var diff:CGFloat = 1
        var itemToUse = SplashScreenItem(width:640, height:960, fileNameSuffix: "")
        for item in availableSplashImages {
            let cmpRatio = item.width/item.height
            if abs(cmpRatio - ratio) < diff {
                itemToUse = item
                diff = abs(cmpRatio - ratio)
            }
        }
        
        let fileName = "Splash_\(itemToUse.fileNameSuffix)"
        let splashImage = UIImage(named: fileName) ?? UIImage()
        return splashImage
    }
    
    /// Splash image array
    /// - Returns: [SplashScreenItem]
    /// Splash image array.
    public static func splashImageArray() -> [SplashScreenItem]{
        let availableSplashImages = [
            SplashScreenItem(width: 640, height: 960, fileNameSuffix: "640x960"),
            SplashScreenItem(width: 640, height: 1136, fileNameSuffix: "640x1136"),
            SplashScreenItem(width: 750, height: 1334, fileNameSuffix: "750x1334"),
            SplashScreenItem(width: 768, height: 1024, fileNameSuffix: "768x1024"),
            SplashScreenItem(width: 828, height: 1792, fileNameSuffix: "828x1792"),
            SplashScreenItem(width: 1125, height: 2436, fileNameSuffix: "1125x2436"),
            SplashScreenItem(width: 1242, height: 2208, fileNameSuffix: "1242x2208"),
            SplashScreenItem(width: 1242, height: 2688, fileNameSuffix: "1242x2688"),
            SplashScreenItem(width: 1536, height: 2048, fileNameSuffix: "1536x2048")
        ]
        return availableSplashImages
    }
}

