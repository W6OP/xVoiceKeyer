/**
 * Copyright (c) 2019 Peter Bourget W6OP
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
//
//  RadioManager.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 7/11/17.
//  Copyright © 2019 Peter Bourget. All rights reserved.
//
// Description: This is a wrapper for the xLib6000 framework written by Doug Adams K3TZR
// The purpose is to simplify the interface into the API and allow the GUI to function
// without a reference to the API or even knowledge of the API.

import Foundation
import xLib6000
import Repeat
import os

    // MARK: Extensions ------------------------------------------------------------------------------------------------

    // breaks an array into chunks of a specific size, the last chunk may be smaller than the specified size
    extension Array {
        func chunked(into size: Int) -> [[Element]] {
            return stride(from: 0, to: count, by: size).map {
                Array(self[$0 ..< Swift.min($0 + size, count)])
            }
        }
    }

    // MARK: Helper Functions ------------------------------------------------------------------------------------------------

    // utility functions to run a UI or background thread
    // USAGE:
    //BG() {
    // everything in here will execute in the background
    //}
    // https://www.electrollama.net/blog/2017/1/6/updating-ui-from-background-threads-simple-threading-in-swift-3-for-ios
    func BG(_ block: @escaping ()->Void) {
        DispatchQueue.global(qos: .background).async(execute: block)
    }

    // USAGE:
    //UI() {
    // everything in here will execute on the main thread
    //}
    func UI(_ block: @escaping ()->Void) {
        DispatchQueue.main.async(execute: block)
    }

    // MARK: Event Delegates ------------------------------------------------------------------------------------------------

    /**
        Implement in your viewcontroller to receive messages from the radio manager
    */
    protocol RadioManagerDelegate: class {
        
        // radio was discovered
        func didDiscoverRadio(discoveredRadios: [(model: String, nickname: String, ipAddress: String, default: String, serialNumber: String)])
        // notify the GUI the tcp connection to the radio was successful
        //func didConnectToRadio()
        // notify the GUI the tcp connection to the radio was closed
        func didDisconnectFromRadio()
        // an update to the radio was received
        //func didUpdateRadio(serialNumber: String, activeSlice: String, transmitMode: TransmitMode)
        // a slice update was received - let the GUI know
        //func didUpdateSlice(availableSlices : [Int : SliceInfo])
        // probably not needed
        func openRadioSelector(serialNumber: String)
    }

    // MARK: Structs ------------------------------------------------------------------------------------------------

    struct SliceInfo {
        var sliceId: Int = 8
        var sliceName: SliceName = SliceName.Slice_X
        var transmitMode: TransmitMode = TransmitMode.Invalid
        var txEnabled: Bool = false
        var isActiveSlice: Bool = false
        var isValidForTransmit: Bool = false
        
        init() {
        }
        
        mutating func populateSliceInfo(sliceId: Int, mode: String, isActiveSlice: Bool, txEnabled: Bool) {
            
            self.isActiveSlice = isActiveSlice
            self.txEnabled = txEnabled
            self.sliceId = sliceId
            convertSliceIdToSliceName(sliceId: sliceId)
            convertModeToTransmitMode(mode: mode)
        }
        
        mutating func convertSliceIdToSliceName(sliceId: Int) {
            
            switch sliceId {
                case 0:
                    sliceName = SliceName.Slice_A
                case 1:
                    sliceName = SliceName.Slice_B
                case 2:
                    sliceName = SliceName.Slice_C
                case 3:
                    sliceName = SliceName.Slice_D
                case 4:
                    sliceName = SliceName.Slice_E
                case 5:
                    sliceName = SliceName.Slice_F
                case 6:
                    sliceName = SliceName.Slice_G
                case 7:
                    sliceName = SliceName.Slice_H
                default:
                    sliceName = SliceName.Slice_X
            }
        }
        
        mutating func convertModeToTransmitMode(mode: String)  {
            
            var validMode = false
            
            switch mode {
            case "USB":
                transmitMode = TransmitMode.USB
                validMode = true
            case "LSB":
                transmitMode = TransmitMode.LSB
                validMode = true
            case "SSB":
                transmitMode = TransmitMode.SSB
                validMode = true
            case "DIGU":
                transmitMode = TransmitMode.DIGI
                validMode = true
            case "DIGL":
                transmitMode = TransmitMode.DIGI
                validMode = true
            case "AM":
                transmitMode = TransmitMode.AM
                validMode = true
            default:
                validMode = false
            }
            
            isValid(validMode: validMode)
            
        }
        
        mutating func isValid(validMode: Bool) {
            
            if validMode && isActiveSlice && txEnabled {
                isValidForTransmit = true
            }
        }
    }

    // MARK: Enums ------------------------------------------------------------------------------------------------

    enum SliceName: String {
        case Slice_A = "Slice A"
        case Slice_B = "Slice B"
        case Slice_C = "Slice C"
        case Slice_D = "Slice D"
        case Slice_E = "Slice E"
        case Slice_F = "Slice F"
        case Slice_G = "Slice G"
        case Slice_H = "Slice H"
        case Slice_X = "Invalid" // indicates invalid slice
    }

    enum  TransmitMode: String{
        case Invalid
        case USB
        case LSB
        case SSB
        case DIGI
        case AM
    }

    // MARK: Class Definition ------------------------------------------------------------------------------------------------

    private var _replyHandlers                  = [SequenceId: ReplyTuple]()  // Dictionary of pending replies
    internal let _objectQ                       = DispatchQueue(label: "xVoiceKeyer" + ".objectQ", attributes: [.concurrent])
    internal var replyHandlers: [SequenceId: ReplyTuple] {
    get { return _objectQ.sync { _replyHandlers } }
    set { _objectQ.sync(flags: .barrier) { _replyHandlers = newValue } } }

    /**
        Wrapper class for the FlexAPI Library xLib6000 written for the Mac by Doug Adams K3TZR.
        This class will isolate other apps from the API implemenation allowing reuse by multiple
        programs.
     */
internal class RadioManager: NSObject, ApiDelegate {
    
    // setup logging for the RadioManager
    static let model_log = OSLog(subsystem: "com.w6op.RadioManager-Swift", category: "Model")
    
    // delegate to pass messages back to viewcontroller
    var radioManagerDelegate:RadioManagerDelegate?
    
    // MARK: - Internal properties ----------------------------------------------------------------------------
    
    // list of serial numbers of discovered radios
    var discoveredRadios: [(model: String, nickname: String, ipAddress: String, default: String, serialNumber: String)]
    
    // list of avaiable slices - only one will be active
    var availableSlices: [Int : SliceInfo]

    // MARK: - Internal Radio properties ----------------------------------------------------------------------------
    
    // Radio currently running
    internal var activeRadio: RadioParameters?
    
    // this starts the discovery process
    private var api = Api.sharedInstance          // Api to the Radio
    
    private var audiomanager: AudioManager!
    
    // MARK: - Private properties ----------------------------------------------------------------------------
    
    // Radio that is selected - may not be the active radio
    private var selectedRadio: RadioParameters?
    
    // Notification observers
    private var notifications = [NSObjectProtocol]()
    private let log = (NSApp.delegate as! AppDelegate)
   
    private let clientName = "xVoiceKeyer"
    
    private let connectFailed = "Initial Connection failed"    // Error messages
    private let udpBindFailed = "Initial UDP bind failed"
    
    private let versionKey = "CFBundleShortVersionString"      // CF constants
    private let buildKey = "CFBundleVersion"
    
    private var availableRadios = [RadioParameters]()          // Array of available Radios
    
    private var txAudioStream: TxAudioStream!
    private var txAudioStreamId: DaxStreamId
    private var txAudioStreamRequested = false
    
    private var audioBuffer = [Float]()
    
    private var audioStreamTimer :Repeater?
    
    private let concurrentTxAudioQueue = DispatchQueue(
                label: "com.w6op.txAudioQueue",
                attributes: .concurrent )
    
    // MARK: - Observation properties ----------------------------------------------------------------------------
    // KVO
    //    private let _radioKeyPaths =                                // Radio keypaths to observe
    //        [
    //            #keyPath(Radio.lineoutGain),
    //            #keyPath(Radio.lineoutMute),
    //            #keyPath(Radio.headphoneGain),
    //            #keyPath(Radio.headphoneMute),
    //            #keyPath(Radio.tnfEnabled),
    //            #keyPath(Radio.fullDuplexEnabled)
    //    ]
    
    // MARK: - RadioManager Initialization ----------------------------------------------------------------------------
    
    /**
        Initialize the class, create the RadioFactory, add notification listeners
    */
    override init() {
        
        audiomanager = AudioManager()
        availableSlices = [Int : SliceInfo]()
        availableRadios = [RadioParameters]()
        discoveredRadios = [(model: String, nickname: String, ipAddress: String, default: String, serialNumber: String)]()
        
        txAudioStreamId = DaxStreamId("1")!
        txAudioStream = TxAudioStream(id: txAudioStreamId, queue: concurrentTxAudioQueue)
        //api.radio?.audioStreams
       
        super.init()
        
        // add notification subscriptions
        addNotificationListeners()

        api.delegate = self
       
        //addObserver(self, forKeyPath: #keyPath(api.apiState), options: [.old, .new], context: nil)
    }
    
    // MARK: - Open and Close Radio Methods ----------------------------------------------------------------------------
    
    func sentMessage(_ text: String) {
        _ = 1
    }
    
    func receivedMessage(_ text: String) {
        // get all except the first character
        _ = String(text.dropFirst())
        os_log("Message received.", log: RadioManager.model_log, type: .info)
        
    }
    
    func addReplyHandler(_ sequenceId: SequenceId, replyTuple: ReplyTuple) {
        // add the handler
        replyHandlers[sequenceId] = replyTuple
        os_log("addReplyHandler added.", log: RadioManager.model_log, type: .info)
    }
    
    func defaultReplyHandler(_ command: String, seqNum: String, responseValue: String, reply: String) {
        // unused in xVoiceKeyer
        os_log("defaultReplyHandler added.", log: RadioManager.model_log, type: .info)
    }
    
    func vitaParser(_ vitaPacket: Vita) {
        // unused in xVoiceKeyer
        os_log("Vita parser added.", log: RadioManager.model_log, type: .info)
    }
    
    /**
     Exposed function for the GUI to indicate which radio to connect to.
     
     - parameters:
     - serialNumber: a string representing the serial number of the radio to connect
     */
    internal func connectToRadio( serialNumber: String) -> Bool {
        
        os_log("Connect to the Radio.", log: RadioManager.model_log, type: .info)
        
        // allow time to hear the UDP broadcasts
        usleep(1500)
        
        for (_, foundRadio) in api.availableRadios.enumerated() where foundRadio.serialNumber == serialNumber {
            activeRadio = foundRadio
            //guard let activeRadio = RadioParameters?foundRadio else { return false }
        
            if api.connect(activeRadio!, clientName: "xVoiceKeyer", isGui: false) {
                return true
            }
        }
        
        return false
    }
    
    /**
     Stop the active radio. Remove observations of Radio properties.
     Perform an orderly close of the Radio resources.
     */
    internal func closeRadio() {
        api.disconnect()
        activeRadio = nil
    }
    
    // MARK: - Notification Methods ----------------------------------------------------------------------------
    
    /**
        Add subscriptions to Notifications from the xLib6000 API
    */
    private func addNotificationListeners() {
        let nc = NotificationCenter.default
        
        // Available Radios changed
        nc.addObserver(forName:Notification.Name(rawValue:"radiosAvailable"),
                       object:nil, queue:nil,
                       using:radiosAvailable)
        
        // Audio stream added
        nc.addObserver(forName:Notification.Name(rawValue:"txAudioStreamHasBeenAdded"),
                       object:nil, queue:nil,
                       using:txAudioStreamHasBeenAdded)
        
        // Audio stream removed
//        nc.addObserver(forName:Notification.Name(rawValue:"txAudioStreamWillBeRemoved"),
//                       object:nil, queue:nil,
//                       using:txAudioStreamWillBeRemoved)
        
    }
    
    // MARK: - Radio Methods ----------------------------------------------------------------------------
 
    /** 
     Notification that one or more radios were discovered.
     
        - parameters:
            - note: a Notification instance
    */
    private func radiosAvailable(_ note: Notification) {
        
        DispatchQueue.main.async {
            
            // receive the updated list of Radios
            let availableRadios = (note.object as! [RadioParameters])
            var newRadios: Int = 0
            
            if availableRadios.count > 0 {
                os_log("Discovery process has completed.", log: RadioManager.model_log, type: .info)
                
                for item in availableRadios {
                    // only add new radios
                    if !self.discoveredRadios.contains(where: { $0.nickname == item.nickname! }) {
                        newRadios += 1
                        self.discoveredRadios.append((item.model, item.nickname!, item.ipAddress, "No", item.serialNumber))
                    }
                }
                
                if newRadios > 0 {
                    // let the view controller know a radio was discovered
                    self.radioManagerDelegate?.didDiscoverRadio(discoveredRadios: self.discoveredRadios)
                }
            }
        }
    }
    
    // MARK: Transmit methods ----------------------------------------------------------------------------
    
    /**
     Prepare to key the selected Radio. Create the audio stream to be sent.
     
        - parameters:
            - doTransmit: true create and send an audio stream, false will unkey MOX
            - buffer: an array of floats representing an audio sample in PCM format
    */
    func keyRadio(doTransmit: Bool, buffer: [Float]? = nil) {
        var frameCount: Int = 0
        
        if doTransmit  {
            self.audioBuffer = buffer!
            if txAudioStreamRequested == false {
                if TxAudioStream.create(callback: updateTxStreamId) {
                    txAudioStreamRequested = true
                }
            }
            else{
                sendTxAudioStream()
            }
        }
    }
    
    /** Callback for the TX Stream Request command.
     
     - Parameters:
     - command:        the original command
     - seqNum:         the Sequence Number of the original command
     - responseValue:  the response value
     - reply:          the reply
     */
    private func updateTxStreamId(_ command: String, seqNum: String, responseValue: String, reply: String) {
        
        guard responseValue == "0" else {
            // Anything other than 0 is an error, log it and ignore the Reply
            //            let errorString = FlexErrors(rawString: responseValue).description()
            //            print("StreamId response: \(errorString)")
            os_log("Error requesting tx audio stream ID.", log: RadioManager.model_log, type: .error)
            // TODO: notify GUI
            return
        }
        
        // check if we have a stream requested
        if !self.txAudioStreamRequested {
            os_log("Unsolicited audio stream received.", log: RadioManager.model_log, type: .error)
            return
        }
       
        // "reply" is the streamId in hex //84000001 2214592513
        let streamId = UInt32(reply, radix:16)
        
        
        
        self.txAudioStream = api.radio?.txAudioStreams[streamId!]
        //sendTxAudioStream(streamId: streamId!)
        sendTxAudioStream()
    }
    
    func sendTxAudioStream(){ //func sendTxAudioStream(streamId: UInt32){
        var frameCount: Int = 0
        let result = self.audioBuffer.chunked(into: 128)
        
        api.radio?.mox = true
        
        //self.txAudioStream = api.radio?.txAudioStreams[streamId]
        txAudioStream.transmit = true
        txAudioStream.txGain = 100
        
        
        self.audioStreamTimer = Repeater.every(.microseconds(5300), count: result.count) { _ in
            
            //print("Timer fired: \(frameCount):\(result[frameCount])\n")
            let _ = self.txAudioStream.sendTXAudio(left: result[frameCount], right: result[frameCount], samples: Int(result[frameCount].count))
            frameCount += 1
        }
        // stop transmitting when you run out of audio - could also be interrupted
        self.audioStreamTimer!.onStateChanged = { (_ timer: Repeater, _ state: Repeater.State) in
            if self.audioStreamTimer!.state.isFinished {
                self.api.radio?.mox = false
                self.audioStreamTimer = nil
            }
        }
        
        audioStreamTimer?.start()
    }
    
//        case nanoseconds(Int)
//        case microseconds(Int)
//        case milliseconds(Int)
//        case seconds(Double)
    
    /**
     Reply handler for the transmitSet command.
    */
    func transmitSetHandler(_ command: String, seqNum: String, responseValue: String, reply: String) {

        var frameCount: Int = 0
        
        print("TransmitSet Handler Called: \(command):\(responseValue):\(reply)")

        
        // IS A "0" SUCCESS ???
        
        // if success do the following. Otherwise let the GUI know it failed and if possible, why.
        
         //self.createTxAudioStream()
        
        
        let result = self.audioBuffer.chunked(into: 128)
        
        txAudioStream.transmit = true
        txAudioStream.txGain = 50
        
        // 72 msec = 48Khz - 0.072
        self.audioStreamTimer = Repeater.every(.seconds(0.072), count: result.count) { _ in
            
            //print("Timer fired: \(frameCount):\(result[frameCount])\n")
            let _ = self.txAudioStream.sendTXAudio(left: result[frameCount], right: result[frameCount], samples: Int(result[frameCount].count))
            frameCount += 1
        }
        // stop transmitting when you run out of audio - could also be interrupted
        self.audioStreamTimer!.onStateChanged = { (_ timer: Repeater, _ state: Repeater.State) in
            if self.audioStreamTimer!.state.isFinished {
                //self.api.radio.
                self.api.send("xmit 0")
                self.audioStreamTimer = nil
            }
        }
        
        audioStreamTimer?.start()
    }
    
    // MARK: - Audio Stream Methods ----------------------------------------------------------------------------
    
    /**
     Ask the radio to create an audio stream. The response will be provided in the callback method.
    */
    private func createTxAudioStream() {
        
        os_log("Create audio stream.", log: RadioManager.model_log, type: .info)
    
        #warning("THIS IS WRONG - check.count needs to be handled correctly")
        //if let check = api.radio?.txAudioStreams(callback: updateTxStreamId) {
        if TxAudioStream.create(callback: updateTxStreamId){
            if let check = api.radio?.txAudioStreams {
                if check.count == 1 {
                    txAudioStream = check[0]
                    txAudioStreamRequested = true
                    os_log("TX audio stream created.", log: RadioManager.model_log, type: .info)
                } else {
                    os_log("Error requesting tx audio stream.", log: RadioManager.model_log, type: .error)
                    // TODO: notify GUI
                }
            }
        }
    }
    
   

    
    /// Process txAudioStreamHasBeenAdded Notification
    ///
    /// - Parameter note: a Notification instance
    ///
    @objc private func txAudioStreamHasBeenAdded(_ note: Notification) {
        
        // does the Notification contain a TXAudioStream object?
        if let txAudioStream = note.object as? TxAudioStream {
            
            if !self.txAudioStreamRequested {
                // stream not requested by us - ignore
                return
            } else {
                
                if txAudioStream.id != self.txAudioStreamId {
                    // stream not created by us - ignore
                    return
                }
            
                // initialize stream
                //sendTxAudioStream(txAudioStream)
            }
        }
    }
    

    
    // ----------------------------------------------------------------------------
    // MARK: - Observation methods
    
    /// Add / Remove property observations
    ///
    /// - Parameters:
    ///   - object: the object of the observations
    ///   - paths: an array of KeyPaths
    ///   - add: add / remove (defaults to add)
    ///
    private func observations<T: NSObject>(_ object: T, paths: [String], remove: Bool = false) {
        
        // for each KeyPath Add / Remove observations
        for keyPath in paths {
            if remove {
                object.removeObserver(self, forKeyPath: keyPath, context: nil)
            }
            else {
                object.addObserver(self, forKeyPath: keyPath, options: [.initial, .new], context: nil)
            }
        }
    }
    
    /// Process changes to observed keyPaths (may arrive on any thread)
    ///
    /// - Parameters:
    ///   - keyPath: the KeyPath that changed
    ///   - object: the Object of the KeyPath
    ///   - change: a change dictionary
    ///   - context: a pointer to a context (if any)
    ///
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let kp = keyPath, let ch = change {
            
            if kp != "springLoaded" {
                
                // interact with the UI
                //DispatchQueue.main.async { [unowned self] in
                    
                    switch kp {
//                    case #keyPath(Radio.txAudioStreams):
////                        self._mainWindowController?.headphoneGain.integerValue = ch[.newKey] as! Int
//                        break
                    case #keyPath(Radio.headphoneMute):
//                        self._mainWindowController?.headphoneMute.state = (ch[.newKey] as! Bool) ? NSControl.StateValue.onState : NSControl.StateValue.offState
                        break
                    case #keyPath(Radio.tnfEnabled):
//                        self._mainWindowController?.tnfEnabled.state = (ch[.newKey] as! Bool) ? NSControl.StateValue.onState : NSControl.StateValue.offState
                        break
                    case #keyPath(Radio.fullDuplexEnabled):
//                        self._mainWindowController?.fdxEnabled.state = (ch[.newKey] as! Bool) ? NSControl.StateValue.onState : NSControl.StateValue.offState
                        break
//                    case #keyPath(Opus.remoteRxOn):
//
//                        if let opus = object as? Opus, let start = ch[.newKey] as? Bool{
//
//                            if start == true && opus.delegate == nil {
//
//                                // Opus starting, supply a decoder
////                                self._opusManager.rxAudio(true)
////                                opus.delegate = self._opusManager
//
//                            } else if start == false && opus.delegate != nil {
//
//                                // opus stopping, remove the decoder
////                                self._opusManager.rxAudio(false)
////                                opus.delegate = nil
//                            }
//                        }
                        
//                    case #keyPath(Opus.remoteTxOn):
//                        break
//                        //if let opus = object as? Opus, let start = ch[.newKey] as? Bool{
//
//                            // Tx Opus starting / stopping
//                            //self._opusManager.txAudio( start, opus: opus )
//                        //}
//
//                    case #keyPath(Opus.rxStreamStopped):
//
//                        // FIXME: Implement this
//                        break
                        
                    default:
                        // log and ignore any other keyPaths
                        break
                        //self.log.msg("Unknown observation - \(String(describing: keyPath))", level: .error, function: #function, file: #file, line: #line)
                    }
                //}
            }
        }
    }
    
   
    
} // end class
