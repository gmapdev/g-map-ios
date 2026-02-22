//
//  TravelIQAudio.swift
//

import Foundation
import AVFoundation

/// Audio Manager is used to handle all the audio related play/pause/replay and so on. TTS control and IVR control will be here.
@objc public class TravelIQAudio: NSObject {
    
	public var languageCode = "en"
	
    /// Initializes a new instance.

    /// this is the audio call back definition.
    public typealias audioCallBack = ((_ state: AudioState, _ errorMessage: String?,_ parameters:[String: Any]?) -> Void)?
    
    /// this is the audio queue, which is used to play audio item one by one.
    private var audioQueue: [AudioQueueItem]
    
    /// when an audio is playing, this operation will take care of it
    private var activeOperation: AudioQueueItem?
    
    /// audio lock is used to avoid the multithread access for an audio operation
    private var audioLock: NSLock
    
    /// this is the flag to indicate what kind of state now for the audio manager
    @objc public var currentPlayerState:AudioPlayerState = .stopped
    
    /// this is the TTS instance for the audio manager. so that we can pause, stop, continue and so on
    var speechSynthesizer:AVSpeechSynthesizer
    
    /// This is the AVFoundation audio file player
    var audioPlayer: AVAudioPlayer?
    
    /// This is to hold weather the app is Forground or Background
    var isAppInForeground: Bool = true
    
    /// This is used to provide the play information for the operation to play the audio.
    struct AudioPlayItem {
        /// content will differ from different type
        var content: String
        /// the parameters that the caller  wants to bring back
        var parameters: [String: Any]?
        /// this is the audio play type, which will decide how we can use the content
        var type: AudioPlayType
        /// callback function is used to notify the caller, the state changes.
        var callback: audioCallBack
    }
    
    /// Define what kind of audio format we are going to play.
    public enum AudioPlayType: String {
        case networkDataStream = "NetworkDataStream"
        case localAudioFile = "LocalAudioFile"
        case textContent = "textContent"
	}
    
    /// AudioState is used to indicate what kind of state is for that individual audio
    @objc public enum AudioState: Int {
        /// when we call play audio and prepare send the audio to the queue
        case inPlayQueue = 0
        /// if now, we are playing the audio
        case playing = 1
        /// finish playing the audio
        case finishPlaying = 2
        /// interrup by some other process
        case interrupt = 3
        /// if error happens, this state will be triggered
        case error = 4
    }
    
    /// AudioPlayerState is used to indicate what is the current state of the audio player manager, audo player manager will manage several individual audio entity
    @objc public enum AudioPlayerState: Int {
        case playing = 0
        case stopped = 1
        case paused = 2
    }
    
    /// shared is an instance
    @objc public static let shared : TravelIQAudio = {
        let mgr = TravelIQAudio()
        return mgr
    }()
    
    /// Initializes a new instance.
    override init()
    {
        self.speechSynthesizer = AVSpeechSynthesizer()
        self.audioQueue = [AudioQueueItem]()
        self.audioLock = NSLock()
        /// Initializes a new instance.
        super.init()
    }
    
    /**
     This function is used to add operation in the audio manager
     - Parameters:
     - operation: this is the operation that used to play the audio
     */
    /// Add operation.
    /// - Parameters:
    ///   - _: Parameter description
    /// Adds operation.
    private func addOperation(_ operation: AudioQueueItem){
        DispatchQueue.main.async {
            self.audioLock.lock()
            self.audioQueue.append(operation)
            self.audioLock.unlock()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AudioManagerPlayItemsCountChanged"), object: nil, userInfo: nil)
            if self.currentPlayerState == .stopped{  // add a new one, we need to run it
                self.runNextOperation()
            }
        }
    }
    
    /**
     This function is used to add operation in the audio manager and make it has higher priority
     - Parameters:
     - operation: this is the operation that used to play the audio
     */
    /// Add operation to front.
    /// - Parameters:
    ///   - _: Parameter description
    /// Adds operation to front.
    private func addOperationToFront(_ operation: AudioQueueItem){
        DispatchQueue.main.async {
            self.audioLock.lock()
            // add a new one, and make it have higher priority than others
            if self.audioQueue.count > 1 {
                self.audioQueue.insert(operation, at: 1)
            }else{
                self.audioQueue.append(operation)
            }
            self.audioLock.unlock()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AudioManagerPlayItemsCountChanged"), object: nil, userInfo: nil)
            if self.currentPlayerState == .stopped {
                self.runNextOperation()
            }
        }
    }
    
    /**
     This function is used to pop operation from audioQueue and run the operation
     - Returns:
     operation to be used by caller function, can be nil if there is no operation in the queue
     */
    /// Run next operation
    /// Run next operation.
    private func runNextOperation(){
        audioLock.lock()
        if audioQueue.count > 0 {
            // Check whether the previous is the one that the same to the current playing. if it is, them remove
            if activeOperation == audioQueue.first {
                audioQueue.removeFirst()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AudioManagerPlayItemsCountChanged"), object: nil, userInfo: nil)
            }
        }
        
        
        // check again after remove one item in the queue, if we remove the played one, and there are still another one. then, we play
        if audioQueue.count > 0 {
            activeOperation = audioQueue.first
            audioLock.unlock()  // unlock after get the item. so that, if there is error happens, it won't block
            currentPlayerState = .playing
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AudioManagerStateChanged"), object: nil, userInfo: ["state": AudioPlayerState.playing.rawValue])
            activeOperation?.start()
        }else{
            // directly unlock if there is no item in audio queue. and set up the flag.
            currentPlayerState = .stopped
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AudioManagerStateChanged"), object: nil, userInfo: ["state": AudioPlayerState.stopped.rawValue])
            audioLock.unlock()
        }
    }
    
    /**
     This function is used to clear all the operations for playing the audio
     */
    /// Clear all operation
    /// Clears all operation.
    private func clearAllOperation(){
        audioLock.lock()
        audioQueue.removeAll()
        audioLock.unlock()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AudioManagerPlayItemsCountChanged"), object: nil, userInfo: nil)
    }
    
    /**
     Play audio from file path
     - Parameters:
     - fromFilePath: the file path in the iOS folder
     - parameters: some extra parameters, which we want to get after the callback comes back
     - highPriority: if this is true, this audio will be placed to the front of the queue and play first
     - ignoreError: if we set ignore error to false, we need to handle the error in the callback. otherwise, the queue won't be excuted. if this value is true, even the play item is failed, it will automatically jump to the next item to play in the queue. if this is false, we need to manually call playNext() in the callback function. when the state is error. otherwise, all the alert or queued item won't play.
     - Returns:
     - callback: (AudioState, errorMessage)
     */
    /// Play audio.
    /// - Parameters:
    ///   - fromFilePath: Parameter description
    ///   - parameters: Parameter description
    ///   - highPriority: Parameter description
    ///   - ignoreError: Parameter description
    ///   - stateChanges: Parameter description
    @objc public func playAudio(fromFilePath: String, parameters:[String:Any]? = nil, highPriority: Bool = false, ignoreError: Bool = true, stateChanges:audioCallBack){
        let item = AudioPlayItem(content: fromFilePath, parameters: parameters, type: .localAudioFile, callback: { (_ state: AudioState, _ errorMessage: String?, _ parameters:[String: Any]?) in
            stateChanges?(state, errorMessage, parameters)
            if state == .error {
                if ignoreError {self.runNextOperation()}
            }else{
                if state != .playing && state != .inPlayQueue{ // audio play item finished, need to move to next one.
                    self.runNextOperation()
                }
            }
        })
        let playItem = AudioQueueItem()
        playItem.audioPlayItem = item
        stateChanges?(AudioState.inPlayQueue, nil, parameters)
        if highPriority {
            self.addOperationToFront(playItem)
        }else{
            self.addOperation(playItem)
        }
    }
    
    /**
     Play audio from file network stream
     - Parameters:
     - fromURL: the file path in the iOS folder
     - parameters: some extra parameters, which we want to get after the callback comes back
     - highPriority: if this is true, this audio will be placed to the front of the queue and play first
     - ignoreError: if we set ignore error to false, we need to handle the error in the callback. otherwise, the queue won't be excuted. if this value is true, even the play item is failed, it will automatically jump to the next item to play in the queue.if this is false, we need to manually call playNext() in the callback function. when the state is error. otherwise, all the alert or queued item won't play.
     - Returns:
     - callback: (AudioState, errorMessage)
     */
    /// Play audio.
    /// - Parameters:
    ///   - fromURL: Parameter description
    ///   - parameters: Parameter description
    ///   - highPriority: Parameter description
    ///   - ignoreError: Parameter description
    ///   - stateChanges: Parameter description
    @objc public func playAudio(fromURL: String, parameters:[String:Any]? = nil, highPriority: Bool = false, ignoreError: Bool = true, stateChanges:audioCallBack){
        let item = AudioPlayItem(content: fromURL, parameters: parameters, type: .networkDataStream, callback: { (_ state: AudioState, _ errorMessage: String?, _ parameters:[String: Any]?) in
            stateChanges?(state, errorMessage, parameters)
            if state == .error {
                if ignoreError {self.runNextOperation()}
            }else{
                if state != .playing && state != .inPlayQueue{ // audio play item finished, need to move to next one.
                    self.runNextOperation()
                }
            }
        })
        let playItem = AudioQueueItem()
        playItem.audioPlayItem = item
        stateChanges?(AudioState.inPlayQueue, nil, parameters)
        if highPriority {
            self.addOperationToFront(playItem)
        }else{
            self.addOperation(playItem)
        }
    }
    
    /**
     Play audio from text
     - Parameters:
     - fromText: the text which we want to announce
     - parameters: some extra parameters, which we want to get after the callback comes back
     - highPriority: if this is true, this audio will be placed to the front of the queue and play first
     - ignoreError: if we set ignore error to false, we need to handle the error in the callback. otherwise, the queue won't be excuted. if this value is true, even the play item is failed, it will automatically jump to the next item to play in the queue.if this is false, we need to manually call playNext() in the callback function. when the state is error. otherwise, all the alert or queued item won't play.
     - Returns:
     - callback: (AudioState, errorMessage)
     */
    /// Play audio.
    /// - Parameters:
    ///   - fromText: Parameter description
    ///   - parameters: Parameter description
    ///   - highPriority: Parameter description
    ///   - ignoreError: Parameter description
    ///   - stateChanges: Parameter description
    @objc public func playAudio(fromText: String,parameters:[String:Any]? = nil,highPriority: Bool = false, ignoreError: Bool = true, stateChanges:audioCallBack){
        let item = AudioPlayItem(content: fromText, parameters: parameters, type: .textContent, callback: { (_ state: AudioState, _ errorMessage: String?, _ parameters:[String: Any]?) in
            stateChanges?(state, errorMessage, parameters)
            if state == .error {
                if ignoreError {self.runNextOperation()}
            }else{
                if state != .playing && state != .inPlayQueue{ // audio play item finished, need to move to next one.
                    self.runNextOperation()
                }
            }
        })
        let playItem = AudioQueueItem()
        playItem.audioPlayItem = item
        stateChanges?(AudioState.inPlayQueue, nil, parameters)
        if highPriority {
            self.addOperationToFront(playItem)
        }else{
            self.addOperation(playItem)
        }
    }
    
    /// This function is used to get how any items needs to be play.
    /// Items count wait for play.
    /// - Returns: Int
    @objc public func itemsCountWaitForPlay() -> Int{
        return audioQueue.count
    }
    
    /**
     This function is used to pause the playing of the audio
     */
    /// Pause
    /// Pauses.
    @objc public func pause(){
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.pauseSpeaking(at: .immediate)
        }
        
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying {
            audioPlayer.pause()
        }
        
        currentPlayerState = .paused
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AudioManagerStateChanged"), object: nil, userInfo: ["state": AudioPlayerState.paused.rawValue])
    }
    
    /// This is used to play the audio or tts item in the queue.
    /// Play.
    @objc public func play(){
        if currentPlayerState != .playing {
            if let activeOpt = activeOperation, let audioPlayItem = activeOpt.audioPlayItem {
                if audioPlayItem.type == .textContent {
                    if speechSynthesizer.isPaused {
                        speechSynthesizer.continueSpeaking()
                    }else{
                        activeOpt.start()
                    }
                }else if audioPlayItem.type == .localAudioFile {
                    if let audioPlayer = audioPlayer, !audioPlayer.isPlaying {
                        audioPlayer.play()
                    }
                }else if audioPlayItem.type == .networkDataStream {
                    if let audioPlayer = audioPlayer, !audioPlayer.isPlaying {
                        audioPlayer.play()
                    }
                }
            }
            currentPlayerState = .playing
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AudioManagerStateChanged"), object: nil, userInfo: ["state": AudioPlayerState.playing.rawValue])
        }
    }
    
    /// Play at.
    /// - Parameters:
    ///   - url: Parameter description
    ///   - at: Parameter description
    public func playAt(url: String, at: TimeInterval){
        var createNewPlayer = false
        let currentPlayItem = audioQueue.first
        if let currentItem = currentPlayItem?.audioPlayItem {
            let currentURL = currentItem.content
            let currentType = currentItem.type
            if currentType == .networkDataStream || currentType == .localAudioFile && currentURL == url{
                if let player = audioPlayer{
					let shortStartDelay: TimeInterval = 0.01
					let now: TimeInterval = audioPlayer?.deviceCurrentTime ?? 0
					let timeDelayPlay: TimeInterval = now + shortStartDelay
					player.currentTime = at
                    player.play(atTime: timeDelayPlay)
					currentPlayerState = .playing
                }
            }
            else{
                createNewPlayer = true
            }
        } else{
            createNewPlayer = true
        }
		
        if createNewPlayer {
            playAudio(fromURL: url, parameters: nil, highPriority: false, ignoreError: false) { (state, errorMessage, parameters) in
                
                // Failure handling for the ivr, then switch to tts if needed
                if state == .error && parameters != nil {
                    if let err = errorMessage{
						OTPLog.log(level: .error, info: err.localized())
                    }
                }
            }
        }
    }
    
    /// This is used to get current progress and duration for item which is playing in AVAudioPlayer
    /// Retrieves current audio time.
    /// - Parameters:
    ///   - completion: @escaping ((currentTime: TimeInterval, duration: TimeInterval
    /// - Returns: Void)
    public func getCurrentAudioTime(completion: @escaping ((currentTime: TimeInterval, duration: TimeInterval)?) -> Void) {
        guard let audioPlayer = audioPlayer else {
            /// Initializes a new instance.
            completion(nil) /// AVAudioPlayer is not initialized
            return
        }
        let currentTime = audioPlayer.currentTime
        let duration = audioPlayer.duration
        
        completion((currentTime, duration))
    }
    
	/// This function is used to set up a specific time for the audio player to play
    /// Sets play time.
    /// - Parameters:
    ///   - to: TimeInterval
    /// - Returns: Bool
    public func setPlayTime(to: TimeInterval) -> Bool{
        if let player = audioPlayer{
            player.currentTime = to
            return true
        }
		return false
    }
    
    /// if something happens, and we pass the ignoreError to NO, in this case, we need to make the error resume manually. after we properly handle the error.
    /// Error resume.
    @objc public func errorResume(){
        DispatchQueue.main.async {
            self.runNextOperation()
        }
    }
    
    /**
     This function is used to play the next audio item and stop the current one.
     Play next item has a pre-condition, there should be one is playing.
     */
    /// Play next
    /// Play next.
    @objc public func playNext(){
        // Order is important, because isPaused belongs to isPlaying state
       if speechSynthesizer.isPaused || speechSynthesizer.isSpeaking{
            speechSynthesizer.stopSpeaking(at: .immediate)
       }
        
       if let audioPlayer = audioPlayer, audioPlayer.isPlaying || audioPlayer.rate >= 0{
            TravelIQAudio.shared.audioPlayer?.stop()
            TravelIQAudio.shared.audioPlayer = nil       // avoid to come to this place again.
            // Because audio player doesn't have callback when we disable, so we need to manually call run next operation
            runNextOperation()
       }
    }
    
    /**
     This function is used to stop all the ongoing audio
     */
    /// Stop
    /// Stops.
    @objc public func stop(){
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying {
            audioPlayer.stop()
            // need to clear the audio player, so that it won't carry previous audio data.
            TravelIQAudio.shared.audioPlayer = nil
        }
        
        clearAllOperation()
        currentPlayerState = .stopped
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AudioManagerStateChanged"), object: nil, userInfo: ["state": AudioPlayerState.stopped.rawValue])
    }
}



/// Customized audio queue item to play the audio.
fileprivate class AudioQueueItem: Operation
{
    var audioPlayItem: TravelIQAudio.AudioPlayItem?
    /// Main
    override func main() {
        if let audioItem = audioPlayItem {
            switch(audioItem.type){
            case .textContent:
                if audioItem.content.count > 0 {
                    playTTS(content: audioItem.content)
                }else{
                    if let callback = audioItem.callback
                    {
                        callback(.error, "content can not be empty when try to play audio", audioItem.parameters)
                    }
                }
            case .localAudioFile:
                if audioItem.content.count > 0 {
                    let filePath = audioItem.content
                    if FileManager.default.fileExists(atPath: filePath) {
                        playFile(onPath: filePath)
                    }else{
                        if let callback = audioItem.callback {
                            callback(.error, "can not find local audio file", audioItem.parameters)
                        }
                    }
                }else{
                    if let callback = audioItem.callback
                    {
                        callback(.error, "local audio file parameter can not be empty", audioItem.parameters)
                    }
                }
            case .networkDataStream:
                if audioItem.content.count > 0 {
                    let url = audioItem.content
                    let ivrAudio = "ivrAudio"
					let destinationURL = TravelIQUtils.docPath(ivrAudio)
					let requestHwnd = TravelIQRequest()
					requestHwnd.urlIgnoreSSLCertificate = true
					requestHwnd.downloadFile(fromURL: url, toLocalPath: destinationURL.path) { (success) in
						var playSuccessfully  = false
                        let localURL = destinationURL.path
						let audioURL = URL(fileURLWithPath: localURL)
						do{
                            if TravelIQAudio.shared.isAppInForeground {
                                self.setupAudioConfigurationForFG()
                            }else{
                                self.setupAudioConfigurationForBG()
                            }
							TravelIQAudio.shared.audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
							if let audioPlayer = TravelIQAudio.shared.audioPlayer{
								audioPlayer.delegate = self
								audioPlayer.play()
								playSuccessfully = true
							}else{
								playSuccessfully = false
        /// Initializes a new instance.
								OTPLog.log(level: .error, info: "can not initialize the audio player")
							}
						}catch let error as NSError {
							playSuccessfully = false
							OTPLog.log(level: .error, info: "when playing the audio file, error happens\(error.description)")
						}
                        
                        if !playSuccessfully {
                            self.audioPlayItem?.callback?(.error, "when playing the audio file", self.audioPlayItem?.parameters)
                        }else{
                            self.audioPlayItem?.callback?(.playing, nil, self.audioPlayItem?.parameters)
                        }
					}
                }else{
                    if let callback = audioItem.callback
                    {
                        callback(.error, "network audio file parameter can not be empty", audioItem.parameters)
                    }
                }
            }
        }
    }
    
    /// This is used to directly play the audio data
    /// Play file.
    /// - Parameters:
    ///   - onData: Data
    func playFile(onData: Data){
        var playSuccessfully  = true
        do{
            // Setup the bluetooth communication channel
            if TravelIQAudio.shared.isAppInForeground {
                self.setupAudioConfigurationForFG()
            }else{
                self.setupAudioConfigurationForBG()
            }
            TravelIQAudio.shared.audioPlayer = try AVAudioPlayer(data: onData)
            if let audioPlayer = TravelIQAudio.shared.audioPlayer{
                audioPlayer.delegate = self
                audioPlayer.play()
            }else{
                playSuccessfully = false
                OTPLog.log(level: .error, info: "can not initialize the audio player width data")
            }
        }
        catch let error as NSError {
            playSuccessfully = false
            OTPLog.log(level: .error, info: "when play audio data, error happens: \(error.description)")
        }
        
        if !playSuccessfully {
            audioPlayItem?.callback?(.error, "when playing the audio data, error happens", audioPlayItem?.parameters)
        }else{
            audioPlayItem?.callback?(.playing, nil, audioPlayItem?.parameters)
        }
    }
    
    /// This is used to directly play the local file
    /// Play file.
    /// - Parameters:
    ///   - onPath: String
    func playFile(onPath: String){
        var playSuccessfully  = true
        do{
            // Setup the bluetooth communication channel
            if TravelIQAudio.shared.isAppInForeground {
                self.setupAudioConfigurationForFG()
            }else{
                self.setupAudioConfigurationForBG()
            }
            
            let audioURL = URL(fileURLWithPath: onPath)
            TravelIQAudio.shared.audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            if let audioPlayer = TravelIQAudio.shared.audioPlayer{
                audioPlayer.delegate = self
                audioPlayer.play()
            }else{
                playSuccessfully = false
                OTPLog.log(level: .error, info: "can not initialize the audio player")
            }
        }
        catch let error as NSError {
            playSuccessfully = false
            OTPLog.log(level: .error, info: "when play audio file, error happens: \(error.description)")
        }
        
        if !playSuccessfully {
            audioPlayItem?.callback?(.error, "when playing the audio file, error happens", audioPlayItem?.parameters)
        }else{
            audioPlayItem?.callback?(.playing, nil, audioPlayItem?.parameters)
        }
    }
    
    /// This is used to play TTS content
    /// Play tts.
    /// - Parameters:
    ///   - content: String
    func playTTS(content: String){
        // Setup bluetooth communication channel
        if TravelIQAudio.shared.isAppInForeground {
            self.setupAudioConfigurationForFG()
        }else{
            self.setupAudioConfigurationForBG()
        }
        
        let speechSynthesizer = TravelIQAudio.shared.speechSynthesizer
        speechSynthesizer.delegate = self
        let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: content)
        var voiceToUse: AVSpeechSynthesisVoice?
        for voice in AVSpeechSynthesisVoice.speechVoices()
        {
            if #available(iOS 9.0, *)
            {
                if voice.name == "Samantha"
                {
                    voiceToUse = voice
                }
            }
        }
        if(voiceToUse == nil)
        {
            voiceToUse = AVSpeechSynthesisVoice(language: "en-US")
        }
		
		if(TravelIQAudio.shared.languageCode.lowercased().contains("fr")){
			voiceToUse = AVSpeechSynthesisVoice(language: "fr-CA")
		}
        speechUtterance.voice = voiceToUse
        speechUtterance.rate = 0.41
        speechSynthesizer.speak(speechUtterance)
        audioPlayItem?.callback?(.playing, nil, audioPlayItem?.parameters)
    }
    
    /// Setup audio configuration for f g
    /// Sets up audio configuration for fg.
    func setupAudioConfigurationForFG(){
        do{
            try AVAudioSession.sharedInstance().setActive(false)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker,.allowBluetooth])
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch{
            OTPLog.log(level: .error, info: "\(error.localizedDescription)")
        }
    }
    //
    /// Sets up audio configuration for bg.
    func setupAudioConfigurationForBG(){
        do{
            try AVAudioSession.sharedInstance().setActive(false)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.duckOthers,.mixWithOthers,.defaultToSpeaker,.allowBluetooth,.allowAirPlay])
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch{
            OTPLog.log(level: .error, info: "\(error.localizedDescription)")
        }
    }
}

extension AudioQueueItem: AVAudioPlayerDelegate {
    /// Audio player decode error did occur.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - error: Parameter description
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        audioPlayItem?.callback?(.error, "decode audio player failed: \(error?.localizedDescription ?? "")", audioPlayItem?.parameters)
    }
    
    /// Audio player did finish playing.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - successfully: Parameter description
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayItem?.callback?(.finishPlaying, nil, audioPlayItem?.parameters)
    }
}

extension AudioQueueItem: AVSpeechSynthesizerDelegate {
    
    /// Speech synthesizer.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - didStart: Parameter description
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        audioPlayItem?.callback?(.playing, nil, audioPlayItem?.parameters)
    }
    
    /// Speech synthesizer.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - didFinish: Parameter description
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        audioPlayItem?.callback?(.finishPlaying, nil, audioPlayItem?.parameters)
    }
    
    /// Speech synthesizer.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - didPause: Parameter description
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {}
    
    /// Speech synthesizer.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - didCancel: Parameter description
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        audioPlayItem?.callback?(.interrupt, nil, audioPlayItem?.parameters)
    }
}
