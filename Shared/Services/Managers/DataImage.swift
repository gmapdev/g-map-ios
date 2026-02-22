//
//  DataImage.swift
//

import SwiftUI
class DataImageManager {
	
	private var imageDownloadingQueue = OperationQueue()

 /// Shared.
 /// - Parameters:
 ///   - DataImageManager: Parameter description
	public static var shared: DataImageManager = {
		let mgr = DataImageManager()
		return mgr
	}()
    @Inject var imageProvider: ImageProvider
	
 /// Download.
 /// - Parameters:
 ///   - fromURL: Parameter description
 ///   - toLocalPath: Parameter description
 ///   - completion: Parameter description
 /// - Returns: Void))
	public func download(fromURL: String, toLocalPath: String, completion:@escaping ((Bool)->Void)) {
        imageDownloadingQueue.addOperation { [self] in
            imageProvider.downloadFile(fromURL: fromURL, toLocalPath: toLocalPath, withJPGCompress: false) { (success) in
				DispatchQueue.main.async {
					completion(success)
				}
			}
		}
	}
}

struct DataImage: View {
	private var id: String
	private var url: String
	private var expire: Double
	private var defImage: UIImage
	@State private var lastUpdated = Date().timeIntervalSince1970
    @Inject var tripProvider: TripProvider
	
 /// Id:  string, url:  string, expire:  double, def image:  string = "gray_background"
 /// Initializes a new instance.
 /// - Parameters:
 ///   - id: String
 ///   - url: String
 ///   - expire: Double
 ///   - defImage: String = "gray_background"
	init(id: String, url: String, expire: Double, defImage: String = "gray_background"){
		self.url = url
		self.id = id
		self.expire = expire
		if expire <= 5 {
			self.expire = 5
		}
		self.defImage = UIImage(named: defImage) ?? UIImage()
	}
	
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
		let pictureName = self.id
		var needToDownload = true
		var localUIImage = UIImage()
		var wasDownloaded = false
		let pictureURLPath = ImageProvider.docPath(pictureName)
		if FileManager.default.fileExists(atPath: pictureURLPath.path) {
			do {
				if let finalUIImage = UIImage(contentsOfFile: pictureURLPath.path) {
					localUIImage = finalUIImage
				}else{
					localUIImage = self.defImage
				}
				wasDownloaded = true
				let attrs = try FileManager.default.attributesOfItem(atPath: pictureURLPath.path)
				if let creationDate = attrs[FileAttributeKey.modificationDate] as? Date {
					if (Date().timeIntervalSince1970 - creationDate.timeIntervalSince1970) < expire {
						needToDownload = false
					}
				}
			}catch {
                OTPLog.log(level: .warning, info: "Can't load the image")
			}
		}else{
			localUIImage = self.defImage
		}
		
		if needToDownload {
			DataImageManager.shared.download(fromURL: self.url, toLocalPath: pictureURLPath.path) { (success) in
				DispatchQueue.main.async {
					self.lastUpdated = Date().timeIntervalSince1970
				}
			}
		}
        return HStack{
            if self.lastUpdated > 0 {
                Image(uiImage: (wasDownloaded ? localUIImage : UIImage())).renderingMode(.original).resizable().aspectRatio(contentMode:.fit)
                    
            }
        }
    }
}

struct DataImage_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
		DataImage(id:"Temporary ID"
			     ,url: "https://upload.wikimedia.org/wikipedia/commons/6/68/Grass_dsc08672-nevit.jpg"
				 ,expire: 14592039492)
    }
}
