/**
 * Copyright (c) 2017 W6OP
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
//  Copyright © 2017 Peter Bourget. All rights reserved.
//
// Description: This is a wrapper for the xLib6000 framework written by Doug Adams K3TZR
// The purpose is to simplify the interface into the API and allow the GUI to function
// without a reference to the API or even knowledge of the API.

import Foundation
import xLib6000
import os

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
        func didConnectToRadio()
        // notify the GUI the tcp connection to the radio was closed
        func didDisconnectFromRadio()
        // an update to the radio was received
        func didUpdateRadio(serialNumber: String, activeSlice: String, transmitMode: TransmitMode)
        // a slice update was received - let the GUI know
        func didUpdateSlice(availableSlices : [Int : SliceInfo])
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

    /**
        Wrapper class for the FlexAPI Library xLib6000 written for the Mac by Doug Adams K3TZR.
        This class will isolate other apps from the API implemenation allowing reuse by multiple
        programs.
     */
internal class RadioManager: NSObject, ApiDelegate {
    func vitaParser(_ vitaPacket: Vita) {
         _ = 1
    }
    
    func streamHandler(_ vitaPacket: Vita) {
         _ = 1
    }
    
    func apiMessage(_ text: String, level: MessageLevel, function: StaticString, file: StaticString, line: Int) {
        _ = 1
    }
    
    func sentMessage(_ text: String) {
        // comment
        _ = 1
    }
    
    func receivedMessage(_ text: String) {
        // comment
        _ = 1
    }

    func addReplyHandler(_ sequenceId: SequenceId, replyTuple: ReplyTuple) {
       // comment
        _ = 1
    }
    
    func defaultReplyHandler(_ command: String, seqNum: String, responseValue: String, reply: String) {
       // comment
        _ = 1
    }
    
    
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
    // Radio class in use
    internal var api: Api?
    
    var audiomanager: AudioManager!
    
    // MARK: - Private properties ----------------------------------------------------------------------------
    
    // Radio that is selected - may not be the active radio
    private var selectedRadio: RadioParameters?
    
    // Notification observers
    private var notifications = [NSObjectProtocol]()
    private let log = (NSApp.delegate as! AppDelegate)
    //private let kModule = "RadioManager"   // Module Name reported in log messages
    let clientName = "SDRVoiceKeyer"
    
    //private let kxFlexApiIdentifier = "net.k3tzr.xLib6000"      // Bundle identifier for xFlexApi
    
    private let connectFailed = "Initial Connection failed"    // Error messages
    private let udpBindFailed = "Initial UDP bind failed"
    
    private let versionKey = "CFBundleShortVersionString"      // CF constants
    private let buildKey = "CFBundleVersion"
    
    private var availableRadios = [RadioParameters]()          // Array of available Radios
    private var radioFactory: RadioFactory
    
    private var txAudioStreamId: DaxStreamId
    private var txAudioStreamRequested = false
    private var txAudioStream: TxAudioStream!
    var audioBuffer = [Float]()
    
    //    private let concurrentTxAudioQueue = DispatchQueue(
    //            label: "com.w6op.txAudioQueue", // 1
    //            attributes: .concurrent ) // 2
    
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
        
        
        os_log("Initializing the RadioFactory.", log: RadioManager.model_log, type: .info)
        
        // start the Radio discovery process
        radioFactory = RadioFactory()
        
        
        txAudioStreamId = DaxStreamId("0")!
       
        //txAudioStream = TxAudioStream(radio!, txAudioStreamId, concurrentTxAudioQueue)
        
        super.init()
        
        // add notification subscriptions
        addNotificationListeners()
        os_log("Added the notification subscriptions.", log: RadioManager.model_log, type: .info)
        
        api = Api.sharedInstance
        
        //addObserver(self, forKeyPath: #keyPath(api.apiState), options: [.old, .new], context: nil)
    }
    
    //override func observeValue(forKeyPath: #keyPath(@objc api?.apiState), of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if keyPath == #keyPath(configurationManager.configuration.updatedAt) {
//            // Update Time Label
//            timeLabel.text = configurationManager.updatedAt
//        }
   // }
    
    // MARK: - Notification Methods ----------------------------------------------------------------------------
    
    /**
        Add subscriptions to Notifications from the xLib6000 API
    */
    private func addNotificationListeners() {
        
        // Initial TCP Connection opened
        let nc = NotificationCenter.default
        nc.addObserver(forName:Notification.Name(rawValue:"clientDidConnect"),
                       object:nil, queue:nil,
                       using:tcpDidConnect)
        
        // TCP Connection disconnect
        nc.addObserver(forName:Notification.Name(rawValue:"clientDidDisconnect"),
                       object:nil, queue:nil,
                       using:tcpDidDisconnect)
        
        // Radio Initialized
        nc.addObserver(forName:Notification.Name(rawValue:"radioInitialized"),
                       object:nil, queue:nil,
                       using:radioInitialized)
        
        // Available Radios changed
        nc.addObserver(forName:Notification.Name(rawValue:"radiosAvailable"),
                       object:nil, queue:nil,
                       using:radiosAvailable)
        
        // Audio stream added
        nc.addObserver(forName:Notification.Name(rawValue:"txAudioStreamHasBeenAdded"),
                       object:nil, queue:nil,
                       using:txAudioStreamHasBeenAdded)
        
        // Audio stream removed
        nc.addObserver(forName:Notification.Name(rawValue:"txAudioStreamWillBeRemoved"),
                       object:nil, queue:nil,
                       using:txAudioStreamWillBeRemoved)
        
        nc.addObserver(forName:Notification.Name(rawValue:"sliceHasBeenAdded"),
                       object:nil, queue:nil,
                       using:sliceHasBeenAdded)
        
        nc.addObserver(forName:Notification.Name(rawValue:"sliceWillBeRemoved"),
                       object:nil, queue:nil,
                       using:sliceWillBeRemoved)
    }
    
    // MARK: - Radio Methods ----------------------------------------------------------------------------
 
    /** 
     Notification that one or more radios were discovered.
     
        - parameters:
            - note: a Notification instance
    */
    @objc private func radiosAvailable(_ note: Notification) {
        
        DispatchQueue.main.async {
            
            // receive the updated list of Radios
            self.availableRadios = (note.object as! [RadioParameters])
            if self.availableRadios.count > 0 {
                
                os_log("Discovery process has completed.", log: RadioManager.model_log, type: .info)
                
                for item in self.availableRadios {
                    // only add new radios
                    if !self.discoveredRadios.contains(where: { $0.nickname == item.nickname! }) {
                        self.discoveredRadios.append((item.model, item.nickname!, item.ipAddress, "No", item.serialNumber))
                        // let the view controller know a radio was discovered
                        self.radioManagerDelegate?.didDiscoverRadio(discoveredRadios: self.discoveredRadios)
                    }
                }
            }
        }
    }
    
    /** 
     Process the tcpDidConnect Notification.
     
        - parameters:
            - note: a Notification instance
    */
    private func tcpDidConnect(_ note: Notification) {
        
        os_log("A TCP connection has been established.", log: RadioManager.model_log, type: .info)
        
        // save the active Radio as the selected Radio
        activeRadio = selectedRadio
        
        // observe changes to Radio properties
        //observations(radio!, paths: _radioKeyPaths)
        
        
        // look at active radio
        //if (api?.apiState == Api.ApiState.initialized) {
            self.connectToRadio(serialNumber: (activeRadio?.serialNumber)!)
        //}
        // let the view controller know a radio was connected
        self.radioManagerDelegate?.didConnectToRadio()
    
    }
    
    /** 
     Process the tcpDidDisconnect Notification.
     
        - parameters:
            - note: a Notification instance
    */
    private func tcpDidDisconnect(_ note: Notification) {
        
        os_log("The TCP connection is being terminated.", log: RadioManager.model_log, type: .info)
        
        if ((note.object as! Api.DisconnectReason) == .normal) {
            // let the view controller know a radio was disconnected to
            self.radioManagerDelegate?.didDisconnectFromRadio()

        }
    }
    
    /** 
     Let the view controller or other object know the radio was initialized.
     At this point I have the radio but may not have slice and other information.
     i.e. SmartSDR may not be running
     
        - parameters:
            - note: a Notification instance
     */
    private func radioInitialized(_ note: Notification) {
        
        // the Radio class has been initialized
        if let radio = note.object as? Radio {
            os_log("The Radio has been initialized.", log: RadioManager.model_log, type: .info)
            DispatchQueue.main.async { [unowned self] in
                print (radio.slices.count)
                //self.updateRadio()
                // use delegate to pass message to view controller ??
                // or use the radio available ??
            }
        }
    }
    
    
    /** 
     Raise event and send to view controller.
     Not in use currently.
    */
    func updateRadio() {
        
        os_log("An update to the Radio has been received.", log: RadioManager.model_log, type: .info)
        
        // we have an update, let the GUI know
        //radioManagerDelegate?.didUpdateRadio(serialNumber: serialNumber!, activeSlice: activeSlice, transmitMode: mode)
    }
    
    // MARK: - Slice Methods ----------------------------------------------------------------------------
    
    /**
     Process a newly added Slice - when the radio first starts up you will get a
     notification for each slice that exists.
     
        - parameters:
            - note: a Notification instance
     */
    private func sliceHasBeenAdded(_ note: Notification) {
        
        if let slice = note.object as? xLib6000.Slice {
            
            // TODO: USE xLib60000 SLICE OBJECT ???
//            print ("slice: \(slice.id)")
//            print ("sliceActive: \(slice.active)")
//            print ("sliceTxEnabled: \(slice.txEnabled)")

             var sliceInfo = SliceInfo()
             sliceInfo.populateSliceInfo(sliceId: Int(slice.id)!, mode: slice.mode, isActiveSlice: slice.active, txEnabled: slice.txEnabled)
//            //let sliceInfo = SliceInfo(sliceId: Int(slice.id)!, mode: slice.mode, isActiveSlice: slice.active, txEnabled: slice.txEnabled)
//            
            print ("sliceInfo: \(sliceInfo.sliceId)")
            
            availableSlices[sliceInfo.sliceId] = sliceInfo
            
            radioManagerDelegate?.didUpdateSlice(availableSlices: availableSlices)
            
        }
    }
    
    /**
     Cleanup when a slice has been removed.
     
        - parameters:
            - note: a Notification instance
     */
    private func sliceWillBeRemoved(_ note: Notification) {
        
        if let slice = note.object as? xLib6000.Slice {
            print (slice.id)
        }
    }
    
    // MARK: - RadioManagerDelegate methods ----------------------------------------------------------------------------
    
    /**
     Force the Radio Factory to resend availableRadios.
     */
    func updateAvailableRadios() {
        //radioFactory.updateAvailableRadios()
    }
    
    /**
     Stop the active radio. Remove observations of Radio properties.
     Perform an orderly close of the Radio resources.
    */
    func closeRadio() {
        
        //observations(radio!, paths: _radioKeyPaths, remove: true)
        
        api?.disconnect()
        activeRadio = nil
    }
    
    /**
     Exposed function for the GUI to indicate which radio to connect to.
     
        - parameters:
            - serialNumber: a string representing the serial number of the radio to connect
    */
    public func connectToRadio( serialNumber: String) {
        
        os_log("Connect to the Radio.", log: RadioManager.model_log, type: .info)
        
        for i in 0..<self.availableRadios.count {
            if self.availableRadios[i].serialNumber == serialNumber {
                if self.openRadio(self.availableRadios[i]) == true {
                    // self.UpdateRadio()
                }
            }
        }
    }
    
    /**
     Connect / Disconnect the selected Radio.
     
        - parameters:
            - selectedRadioParameters: an object representing a radio
    */
    private func openRadio(_ selectedRadioParameters: RadioParameters?) -> Bool {
        
        api?.connect(selectedRadioParameters!, clientName: clientName)
        
        self.selectedRadio = selectedRadioParameters
        
        if selectedRadio != nil && selectedRadio == activeRadio {
            // Disconnect the active Radio
            closeRadio()
        } else if selectedRadio != nil {
            if activeRadio != nil {
                // Disconnect the active Radio
                closeRadio()
            }
            
            // Create a Radio class
            //api = Api(clientName: clientName, isGui: false)
            
            // start a connection to the Radio
//            if !api!.connect(selectedRadio!, primaryCmdTypes: [.allPrimary], secondaryCmdTypes: [.allSecondary], subscriptionCmdTypes: [.allSubscription]) {
//                // connect failed, log the error and return
//                os_log("Connection to the Radio failed.", log: RadioManager.model_log, type: .error)
//                return false
//            }
        }
        
        return true
    }
    
    // ----------------------------------------------------------------------------
    // MARK: Transmit methods
    
    /**
     Prepare to key the selected Radio. Create the audio stream to be sent.
     
        - parameters:
            - doTransmit: true create and send an audio stream, false will unkey MOX
            - buffer: an array of floats representing an audio sample in PCM format
    */
    func keyRadio(doTransmit: Bool, buffer: [Float]? = nil) {
        
        if doTransmit  {
            // https://community.flexradio.com/flexradio/topics/how-to-control-the-dax-subsystem-via-the-ethernet-api
            //dax audio set <dax channel> slice=<slice index>
            // dax audio set <dax channel> tx=0|1
            
            self.audioBuffer = buffer!
            self.createTxAudioStream()
        }
        
        // GET the daxEnabled status and preserve it
        // SET the daxEnabled status to true (enabled)
        //let errorString = FlexErrors(rawString:"50000016").description()

//        if !doTransmit  {
//            // swift 4
//            api?.radio?.transmitSet(false) { (result) -> () in
//                // RESET the daxEnabled status to its persisted value
//                //self.txAudioStream.transmit = false
//                // swift 4
//                //print("Stop Transmit: \(result)")
//                // TODO: account for failure - resend
//            }
//        }
    }
    
    /**
     Reply handler for the transmitSet command. Not used currently.
    */
    func transmitSetHandler(_ command: String, seqNum: String, responseValue: String, reply: String) {
       
        print("TransmitSet Handler Called: \(command):\(responseValue):\(reply)")
        
        // TODO: explore the dax tx handling
        txAudioStream.transmit = true
        txAudioStream.txGain = 50
        let _ = txAudioStream.sendTXAudio(left: self.audioBuffer, right: self.audioBuffer, samples: Int(self.audioBuffer.count))
        
    }
    
    // MARK: - Audio Stream Methods ----------------------------------------------------------------------------
    
    /**
     Ask the radio to create an audio stream. The response will be provided in the callback method.
    */
    private func createTxAudioStream() {
        
        os_log("Create audio stream.", log: RadioManager.model_log, type: .info)
        
        if let check = api?.radio?.txAudioStreamCreate(callback: updateTxStreamId) {
            if check {
                txAudioStreamRequested = true
                os_log("TX audio stream created.", log: RadioManager.model_log, type: .info)
            } else {
                os_log("Error requesting tx audio stream.", log: RadioManager.model_log, type: .error)
                // TODO: notify GUI
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
            let errorString = FlexErrors(rawString: responseValue).description()
            print("StreamId response: \(errorString)")
            os_log("Error requesting tx audio stream ID.", log: RadioManager.model_log, type: .error)
            // TODO: notify GUI
            return
        }
        
        // check if we have a stream requested
        if !self.txAudioStreamRequested {
            os_log("Unsolicited audio stream received.", log: RadioManager.model_log, type: .error)
            return
        }
        
        // make the string 8 characters long -> add "0" at the beginning
        let fillCnt = 8 - reply.count
        let fills = (fillCnt > 0 ? String(repeatElement("0", count: fillCnt)) : "")
        
        self.txAudioStreamId = DaxStreamId(fills + reply)!
        
        // now check if we already have this stream in the radio object and initialize if necessary
        if let stream = api?.radio?.txAudioStreams[self.txAudioStreamId] {
            sendTxAudioStream(stream)
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
                sendTxAudioStream(txAudioStream)
            }
        }
    }
    
    /** Key the radio and send the audio stream to the radio.
     
        - Parameters:
            - txAudioStream: the audio stream to send
     */
    private func sendTxAudioStream(_ txAudioStream: TxAudioStream) {
        
        self.txAudioStream = txAudioStream
        self.txAudioStreamRequested = false
        
//        let txAudioActive = false
//        
//        // TODO: explore the dax tx handling
//        txAudioStream.transmit = txAudioActive
        
          api?.radio?.transmitSet(true, callback: transmitSetHandler)
//        radio?.transmitSet(true) { (result) -> () in
//            txAudioStream.txGain = 35
//            //let _ = txAudioStream.sendTXAudio(left: self.audioBuffer, right: self.audioBuffer, samples: Int(self.audioBuffer.count))
//        }
    }
    
    /**
     The audio stream has been removed.
     
        - parameters:
            - note: a Notification instance
     */
    @objc private func txAudioStreamWillBeRemoved(_ note: Notification) {
        // do I need to do anything ???
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
                    case #keyPath(Opus.remoteRxOn):
                        
                        if let opus = object as? Opus, let start = ch[.newKey] as? Bool{
                            
                            if start == true && opus.delegate == nil {
                                
                                // Opus starting, supply a decoder
//                                self._opusManager.rxAudio(true)
//                                opus.delegate = self._opusManager
                                
                            } else if start == false && opus.delegate != nil {
                                
                                // opus stopping, remove the decoder
//                                self._opusManager.rxAudio(false)
//                                opus.delegate = nil
                            }
                        }
                        
                    case #keyPath(Opus.remoteTxOn):
                        break
                        //if let opus = object as? Opus, let start = ch[.newKey] as? Bool{
                            
                            // Tx Opus starting / stopping
                            //self._opusManager.txAudio( start, opus: opus )
                        //}
                        
                    case #keyPath(Opus.rxStreamStopped):
                        
                        // FIXME: Implement this
                        break
                        
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
