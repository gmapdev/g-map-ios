//
//  OTPLog.swift
//

import Foundation

fileprivate struct OTPLogItem: Hashable, Codable
{
	/// Define the log level of this item
	var logLevel: OTPLog.Level
	
	/// Define the UTC timestamp for tracking purpose
	var logDateTime: Double
	
	/// Define the log message
	var logMessage: String
	
	/// Define the file name when we log the information
	var fileName: String
	
	/// Define the function name in the file when we log the information
	var functionName: String
	
	/// Define the line number of the log so that we know where this log is happen
	var line: Int
	
	/// Define the parameters that when we log this record, it will be convert to the String for display purpose
	var parameters: String?
	
	/// Used to get the file name without the path information.
	var prettyLogFileName: String {
		get{
			var finalFileName = fileName
			if let lastIndexOf = fileName.lastIndex(of: "/") {
				let newIndex = lastIndexOf.utf16Offset(in: fileName)
				finalFileName = String(fileName[(newIndex + 1)...])
			}
			return finalFileName
		}
	}
	
	/// Used to get the current timezone, Date Time in yyyy-MM-dd HH:mm:ss.SSSS
	var  prettyLogDateTime: String {
		get {
			return OTPUtils.convertTimestampToLocal(logDateTime, toFormat: "yyyy-MM-dd HH:mm:ss.SSSS")
		}
	}
}

public class OTPLog: NSObject {
	
	// MARK: PRIVATE DEFINITION
	
	/// This is the container to save all the log information
	private var logContainer:[OTPLogItem] = [OTPLogItem]()
	
	/// This is the lock for the log, so that we won't have issue, when we log information in multithread programming
	private var logContainerLock: DispatchQueue = DispatchQueue(label: "com.ibigroup.otp.access.log.queue")
	
	/// This is the counter to remember when we need to flush the records to the disk
	private var flushLogIntervalIndex = 0
	
	/// It records when we need to flush the disk after how many records are recorded
	private var _flushLogAfterNrofRecords = 50
	
	/// It is used to define the log file name in the disk
	public var logFileName = "otp_log.txt"
	
	/// It is used to store the state of displaying the log in the console
	private var _displayLogInConsole = true
	
	/// It is used to store the state of the displaying details of the log
	private var _displayLogDetails = false
	
	
	// MARK: PROPERTY AND CHANGABLE VARIABALE DEFINITION
	
	/// Shared Instance - OTPLog Log information
	public static let shared : OTPLog = {
		let mgr = OTPLog()
		
		//load the saved log from disk
		mgr.loadLogToContainer()
		return mgr
	}()
	
	
	/**
	 Define the default level of the log, by default it is : Level.info, if the level is above this tracking level.
	 OTPLog won't be recorded. The tracking level priority is info > warning > error > crash
	*/
	@objc public static var trackingLevel: Level = Level.info
	
	/// Define the log buffer of the log, by default it tracks 300 records
	@objc public static var trackingBufferSize = 300
	
	/// Define the interval of flush the log to the disk for permanent saving, by default it is 50 records.
	/// The range to this flush log interval is between 5 and 1000
	@objc public static var flushLogAfterNrofRecords: Int {
		get{
			return shared._flushLogAfterNrofRecords
		}
		set {
			if newValue <= OTPLog.trackingBufferSize && newValue >= 5 {
				shared._flushLogAfterNrofRecords = newValue
			}else {
				OTPLog.log(level: .warning, info: "Failed to setup flushLogAfterNrofRecords variable, `flush log after number of records` can not be less than 5 records or larger than tracking buffer size")
			}
		}
	}
	
	/// This property is used to turn on/off the ability of the OTPLog to display/print the log in the console. if this is false, there is no log will be printed in the console.
	@objc public static var displayLogInConsole: Bool {
		get {
			return shared._displayLogInConsole
		}
		set {
			shared._displayLogInConsole = newValue
		}
	}

	/// This is used to turn on/off the output of log details, if this is off, the log only display message information without the source file, function and line information
	@objc public static var displayLogDetails: Bool {
		get {
			return shared._displayLogDetails
		}
		set {
			shared._displayLogDetails = newValue
		}
	}

	/// Convenience method to enable console logging (for development/debug builds)
	@objc public static func enableConsoleLogging() {
		displayLogInConsole = true
	}

	/// Convenience method to disable console logging (for production/release builds)
	@objc public static func disableConsoleLogging() {
		displayLogInConsole = false
	}

	/// Levels of the log
	@objc public enum Level: Int, Codable {
		
		/// If a potential crash will happens here, use level crash to record
		case crash = 0
		/// If an error will be detected here, use level error to record. this error won't let the app crash
		case error = 1
		/// If something is not that normal or not happen frequently, use level warning to record
		case warning = 2
		/// If regular running steps, use level info to record
		case info = 3
		
		/// Get the corresponding text description for the level
  /// To string.
  /// - Returns: String
		func toString()->String {
			switch(self){
				case .crash: return "Crash"
				case .error: return "Error"
				case .warning: return "Warning"
				case .info: return "Info"
			}
		}
	}
	
	// MARK: PUBLIC FUNCTION
	
	/// This function is used to clear and delete the log file in the documentation folder. it will block the process until it is done.
 /// Removes log file.
 /// - Parameters:
 ///   - completion: ((
 /// - Returns: Void)? = nil)
	@objc public static func removeLogFile(completion:(()->Void)? = nil){
		let urlFromDisk = OTPUtils.docPath(shared.logFileName)
		if FileManager.default.fileExists(atPath: urlFromDisk.path) {
			shared.logContainerLock.sync {
				do{
					try FileManager.default.removeItem(at: urlFromDisk)
					completion?()
				}catch{
					assert(false, "Can not delete local log file for OTP, error:" + error.localizedDescription)
				}
			}
		}else{
			completion?()
		}
	}
	
	/// This function is used to retrieve a formatted Log Information in a string for caller
 /// Retrieve log history.
 /// - Parameters:
 ///   - withDetails: Bool = false
 ///   - completion: @escaping (String?
 /// - Returns: Void)
	@objc public static func retrieveLogHistory(withDetails:Bool = false, completion:@escaping (String?)->Void){
		shared.logContainerLock.sync {
			var logHistory = ""
			let copyLogContainer = shared.logContainer
			for item in copyLogContainer {
				logHistory.append(shared.formatOTPLogItem(item: item, withDetails: withDetails))
			}
			completion(logHistory)
		}
	}
	
	/// For outside caller to use the log to record information, pass Dictionary as parameters
 /// Log.
 /// - Parameters:
 ///   - level: Level = .info
 ///   - info: String
 ///   - parameters: [String:Any]? = nil
 ///   - fileName: String = #file
 ///   - functionName: String = #function
 ///   - lineNumber: Int = #line
	@objc public static func log(level:Level = .info, info: String, parameters:[String:Any]? = nil, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
		track(level: level, info:info, parameters: parameters, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
	}
	
	/// Log information that we want to track, by default, the level of the log is info
 /// Track.
 /// - Parameters:
 ///   - level: Level = .info
 ///   - info: String
 ///   - parameters: T? = nil
 ///   - fileName: String = #file
 ///   - functionName: String = #function
 ///   - lineNumber: Int = #line
	internal static func track<T>(level:Level = .info, info: String, parameters: T? = nil, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line){
		
		// if the leve is not the level that we want to log, then, directly return
		if level.rawValue > trackingLevel.rawValue {
			return
		}
		
		// control the lock so that at one time, there are only one log record is accessing and processing by the class
		shared.logContainerLock.sync {
			
			if shared.logContainer.count > OTPLog.trackingBufferSize {
				shared.logContainer.removeFirst()
			}
			
			var parameterString : String?
			if let params = parameters{
				parameterString = OTPUtils.objToJSONString(object: params)
			}
			
			let logEntry = OTPLogItem(logLevel: level, logDateTime: Date().timeIntervalSince1970, logMessage: info, fileName: fileName, functionName: functionName, line: lineNumber, parameters: parameterString)

			// Output the log information
			if shared._displayLogInConsole {
				print(shared.formatOTPLogItem(item: logEntry, withDetails: shared._displayLogDetails))
			}
			
			shared.logContainer.append(logEntry)
			
			shared.flushLogIntervalIndex += 1
			
			if shared.flushLogIntervalIndex%flushLogAfterNrofRecords == 0 {
				shared.flushLogToDisk()
				shared.flushLogIntervalIndex = 0
			}
		}
	}
	
	// MARK: PRIVATE FUNCTION
	
	/// This is used to format a given OTPLog Item in a string for console / log display purpose
 /// Formats otp log item.
 /// - Parameters:
 ///   - item: OTPLogItem
 ///   - withDetails: Bool = false
 /// - Returns: String
	fileprivate func formatOTPLogItem(item: OTPLogItem, withDetails: Bool = false)->String {
		var outputFormat = ""
		if withDetails {
			outputFormat.append(contentsOf: "\n{Level:\(item.logLevel.toString())} [\(item.prettyLogDateTime)] \n")
			outputFormat.append(contentsOf: "\(item.prettyLogFileName)->\(item.functionName)(Line:\(item.line)): \n")
			outputFormat.append(contentsOf: "-- [Info]: \(item.logMessage)")
			if let logParameters = item.parameters {
				outputFormat.append(contentsOf: "\n>> [Parameters]: \(logParameters)")
			}
		}
		else {
			outputFormat.append(contentsOf: "[\(item.logLevel.toString())][\(item.prettyLogDateTime)]: \(item.logMessage)")
			if let logParameters = item.parameters {
				outputFormat.append(contentsOf: "\n>>[Parameters]: \(logParameters)")
			}
		}
		return outputFormat
	}
	
	/// This function will write the log to the disk
 /// Flush log to disk.
 /// - Parameters:
 ///   - fileName: String = #file
 ///   - functionName: String = #function
 ///   - lineNumber: Int = #line
	fileprivate func flushLogToDisk(fileName: String = #file, functionName: String = #function, lineNumber: Int = #line){
		let urlToDisk = OTPUtils.docPath(logFileName)
		if let jsonData = try? JSONEncoder().encode(logContainer) {
			// write the data to the local file.
			do{
				let jsonString = String(data: jsonData, encoding: .utf8) ?? "Unknown"
				let jsonEncrypted = IBISecurity.encrypt(jsonString)
				try jsonEncrypted.write(to: urlToDisk, atomically: true, encoding: .utf8)
			}
			catch {
				let jsonString = String(data: jsonData, encoding: .utf8) ?? "Unknown"
				let error = "flush log to disk failed:" + "\(error.localizedDescription), >> Path" + urlToDisk.path
				assert(false, error)
				let logEntry = OTPLogItem(logLevel: .error, logDateTime: Date().timeIntervalSince1970, logMessage: error, fileName: fileName, functionName: functionName, line: lineNumber, parameters: "JSON:\(jsonString)")
				logContainer.append(logEntry)
				flushLogIntervalIndex += 1
			}
		}
		else{
			assert(false, "Cannot convert the logContainer object to json data")
		}
	}
	
	/// This function is used to load the log from the disk to the container object
 /// Loads log to container.
 /// - Parameters:
 ///   - fileName: String = #file
 ///   - functionName: String = #function
 ///   - lineNumber: Int = #line
	fileprivate func loadLogToContainer(fileName: String = #file, functionName: String = #function, lineNumber: Int = #line){
		logContainerLock.sync {
			let urlFromDisk = OTPUtils.docPath(self.logFileName)
			if FileManager.default.fileExists(atPath: urlFromDisk.path) {
				if let jsonEncryptedData = try? Data(contentsOf: urlFromDisk) {
     /// Initializes a new instance.
     /// - Parameters:
     ///   - data: jsonEncryptedData
     ///   - encoding: .utf8
					let jsonEncryptedString = String.init(data: jsonEncryptedData, encoding: .utf8) ?? ""
					let jsonString = IBISecurity.decrypt(jsonEncryptedString)
					if let jsonData = jsonString?.data(using: .utf8) {
						if let content:[OTPLogItem] = try? JSONDecoder().decode([OTPLogItem].self, from: jsonData){
							self.logContainer.append(contentsOf: content)
						}else{
							let jsonString = String(data: jsonEncryptedData, encoding: .utf8) ?? "Unknown"
							let error = "Convert and decode log object failed:"
							let logEntry = OTPLogItem(logLevel: .error, logDateTime: Date().timeIntervalSince1970, logMessage: error, fileName: fileName, functionName: functionName, line: lineNumber, parameters: jsonString)
							self.logContainer.append(logEntry)
							self.flushLogIntervalIndex += 1
							assert(false, error)
						}
					}else{
						let error = "Can not convert back json data from json string:" + urlFromDisk.path
						let logEntry = OTPLogItem(logLevel: .error, logDateTime: Date().timeIntervalSince1970, logMessage: error, fileName: fileName, functionName: functionName, line: lineNumber, parameters: "")
						self.logContainer.append(logEntry)
						self.flushLogIntervalIndex += 1
						assert(false, error)
					}
				}else {
					let error = "Can not load data from the disk via url:" + urlFromDisk.path
					let logEntry = OTPLogItem(logLevel: .error, logDateTime: Date().timeIntervalSince1970, logMessage: error, fileName: fileName, functionName: functionName, line: lineNumber, parameters: "")
					self.logContainer.append(logEntry)
					self.flushLogIntervalIndex += 1
					assert(false, error)
				}
			}else{
				let warning = "Reading Log File failed, the file is not existed:" + urlFromDisk.path
				let logEntry = OTPLogItem(logLevel: .warning, logDateTime: Date().timeIntervalSince1970, logMessage: warning, fileName: fileName, functionName: functionName, line: lineNumber, parameters: "")
				self.logContainer.append(logEntry)
				self.flushLogIntervalIndex += 1
			}
		}
	}
}
