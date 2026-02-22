//
//  ImageProvider.swift
//

import Foundation
import SwiftUI
import UIKit

class ImageProvider: BaseProvider {

/// Download file.
/// - Parameters:
///   - fromURL: Parameter description
///   - toLocalPath: Parameter description
///   - withJPGCompress: Parameter description
///   - completion: Parameter description
/// - Returns: Void)?)
public func downloadFile(fromURL: String, toLocalPath: String, withJPGCompress: Bool = false, completion:((Bool)->Void)?) {
    guard let url = URL(string: fromURL) else {
        OTPLog.log(level: .error, info: "can not convert the fromURL to \(fromURL)")
        completion?(false)
        return
    }
    
    let request = URLRequest(url: url)
    let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode>=200 &&  httpResponse.statusCode<300 {
                if let data = data, data.count > 0 {
                    do{
                        let toURL = URL(fileURLWithPath: toLocalPath)
                        var writableData = data
                        if withJPGCompress {
                            if let image = UIImage(data: data), let compressedData = image.jpegData(compressionQuality: 0.5) {
                                writableData = compressedData
                            }else{
                                completion?(false)
                                return
                            }
                        }
						try writableData.write(to: toURL, options:.atomic)
                        completion?(true)
                        return
                    }catch let error as NSError {
                        OTPLog.log(level: .error, info: "copy file from temp area to destination failed, \(error.description)")
                    }
                }
            }
            completion?(false)
        }
        dataTask.resume()
}

/// Doc path.
/// - Parameters:
///   - _: Parameter description
/// - Returns: URL
@objc public static func docPath(_ withAppendedPath: String = "") -> URL {
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    if let documentDirectory: URL = urls.first {
        var directory: ObjCBool = ObjCBool(false)
        let folderExisted = fileManager.fileExists(atPath: documentDirectory.path, isDirectory: &directory)
        if folderExisted && directory.boolValue {} else {
            do {
                try fileManager.createDirectory(atPath: documentDirectory.path, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                assertionFailure("Can not create documents folder for the ATL RIDES. \(error.localizedDescription)")
                return URL(fileURLWithPath: "")
            }
        }
        let path = documentDirectory.appendingPathComponent(withAppendedPath)
        return path
    }
    else{
        assert(false, "Couldn't get general documents directory")
    }
    return URL(fileURLWithPath: "")
}
    
    /// Get image url.
    /// - Parameters:
    ///   - imageName: Parameter description
    /// - Returns: String
    public static func getImageUrl(imageName: String) -> String {
        let imageUrl = FeatureConfig.shared.agencies_logo_base_url+imageName.lowercased().replacingOccurrences(of: " ", with: "_")
        return imageUrl
    }
}
