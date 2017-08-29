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
// Description: This is a wrapper for the xFlexAPI framework written by Doug Adams K3TZR
// The purpose is to simplify the interface into the API and allow the GUI to function
// without a reference to the API or even knowledge of the API.

import Foundation
import xLib6000
import os

// event delegate
// implement in your viewcontroller to receive messages from the radio manager
protocol RadioManagerDelegate: class {
    // radio was discovered
    func didDiscoverRadio(discoveredRadios: [(model: String, nickname: String, ipAddress: String, default: String)])
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

// structure to pass data back to view controller
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

//struct DiscoveredRadios {
//    var model: String
//    var nickname: String
//    var ipAddress: String
//    var isDefaultRadio: String
//}

//
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

// wrapper class for the xFlexAPI written by Doug Adams K3TZR
internal class RadioManager: NSObject {
    
    // setup logging for the RadioManager
    static let model_log = OSLog(subsystem: "com.w6op.Radio-Swift", category: "Model")
    
    // delegate to pass messages back to viewcontroller
    var radioManagerDelegate:RadioManagerDelegate?
    
    // ----------------------------------------------------------------------------
    // MARK: - Internal properties
    
    // list of serial numbers of discovered radios
    var discoveredRadios: [(model: String, nickname: String, ipAddress: String, default: String)]
    
    var availableSlices: [Int : SliceInfo]
    
    // ----------------------------------------------------------------------------
    // MARK: - Internal Radio properties
    
    // Radio currently running
    internal var activeRadio: RadioParameters?
    // Radio class in use
    internal var radio: Radio?
    
    var audiomanager: AudioManager!
    
    // ----------------------------------------------------------------------------
    // MARK: - Private properties
    
    // Radio that is selected - may not be the active radio
    fileprivate var selectedRadio: RadioParameters?
    
    // Notification observers
    fileprivate var notifications = [NSObjectProtocol]()
    
    //fileprivate let _opusManager = OpusManager()
    
    // constants
    // fileprivate let _log = Log.sharedInstance   // Shared log
    // fileprivate let _log: XCGLogger!          // Shared log
    
    fileprivate let log = (NSApp.delegate as! AppDelegate)
    fileprivate let kModule = "RadioManager"                 // Module Name reported in log messages
    let clientName = "SDRVoiceKeyer"
    
    fileprivate let kxFlexApiIdentifier = "net.k3tzr.xFlexAPI"      // Bundle identifier for xFlexApi
    
    fileprivate let connectFailed = "Initial Connection failed"    // Error messages
    fileprivate let udpBindFailed = "Initial UDP bind failed"
    
    fileprivate let versionKey = "CFBundleShortVersionString"      // CF constants
    fileprivate let buildKey = "CFBundleVersion"
    
    fileprivate var availableRadios = [RadioParameters]()          // Array of available Radios
    fileprivate var radioFactory: RadioFactory
    
    // ----------------------------------------------------------------------------
    // MARK: - Observation properties
    
    // KVO
    fileprivate let _radioKeyPaths =                                // Radio keypaths to observe
        [
            #keyPath(Radio.lineoutGain),
            #keyPath(Radio.lineoutMute),
            #keyPath(Radio.headphoneGain),
            #keyPath(Radio.headphoneMute),
            #keyPath(Radio.tnfEnabled),
            #keyPath(Radio.fullDuplexEnabled)
    ]
    
//    private let _opusKeyPaths =
//        [
//            #keyPath(Opus.remoteRxOn),
//            #keyPath(Opus.remoteTxOn),
//            #keyPath(Opus.rxStreamStopped)
//    ]
    
    // ----------------------------------------------------------------------------
    // MARK: - RadioManager Initialization
    
    // initialize the class
    // create the RadioFactory
    // add notification listeners
    override init() {
        
        audiomanager = AudioManager()
        
        availableSlices = [Int : SliceInfo]()
        availableRadios = [RadioParameters]()
        discoveredRadios = [(model: String, nickname: String, ipAddress: String, default: String)]()
        
        
        os_log("Initializing the RadioFactory.", log: RadioManager.model_log, type: .info)
        
        // start the Radio discovery process
        radioFactory = RadioFactory()
        
        super.init()
        
        // add notification subscriptions
        addNotificationListeners()
        os_log("Added the notification subscriptions.", log: RadioManager.model_log, type: .info)
    }
    
    
    // ----------------------------------------------------------------------------
    // MARK: - Notification Methods
    
    /// Add subscriptions to Notifications from the xFlexAPI
    ///
    fileprivate func addNotificationListeners() {
        
        // Initial TCP Connection opened
        let nc = NotificationCenter.default
        nc.addObserver(forName:Notification.Name(rawValue:"tcpDidConnect"),
                       object:nil, queue:nil,
                       using:tcpDidConnect)
        
        // TCP Connection disconnect
        nc.addObserver(forName:Notification.Name(rawValue:"tcpDidDisconnect"),
                       object:nil, queue:nil,
                       using:tcpDidDisconnect)
        
        // a Meter was Added
//        nc.addObserver(forName:Notification.Name(rawValue:"meterHasBeenAdded"),
//                       object:nil, queue:nil,
//                       using:meterHasBeenAdded)
        
        // Radio Initialized
        nc.addObserver(forName:Notification.Name(rawValue:"radioInitialized"),
                       object:nil, queue:nil,
                       using:radioInitialized)
        
        // Available Radios changed
        nc.addObserver(forName:Notification.Name(rawValue:"radiosAvailable"),
                       object:nil, queue:nil,
                       using:radiosAvailable)
        
        // an Opus was Added
        nc.addObserver(forName:Notification.Name(rawValue:"opusHasBeenAdded"),
                       object:nil, queue:nil,
                       using:opusHasBeenAdded)
        
        nc.addObserver(forName:Notification.Name(rawValue:"sliceHasBeenAdded"),
                       object:nil, queue:nil,
                       using:sliceHasBeenAdded)
        
        nc.addObserver(forName:Notification.Name(rawValue:"sliceWillBeRemoved"),
                       object:nil, queue:nil,
                       using:sliceWillBeRemoved)
    }
    
    // discovered at least one radio
    @objc fileprivate func radiosAvailable(_ note: Notification) {
        
        DispatchQueue.main.async {
            
            // receive the updated list of Radios
            self.availableRadios = (note.object as! [RadioParameters])
            if self.availableRadios.count > 0 {
                
                os_log("Discovery process has completed.", log: RadioManager.model_log, type: .info)
                
                //self.discoveredRadios.append(("6500", "New Radio", "129.34.3.4", "No"))
                
                for item in self.availableRadios {
                    // only add new radios
                    if !self.discoveredRadios.contains(where: { $0.nickname == item.nickname! }) {
                        self.discoveredRadios.append((item.model, item.nickname!, item.ipAddress, "No"))
                        
                        
                        // TODO: DELETE
                        // for debugging to test disconnect/reconnect
                        self.discoveredRadios.append(("FLEX-6700", item.nickname!, item.ipAddress, "No"))
                        
//                        // let the view controller know a radio was discovered
                        self.radioManagerDelegate?.didDiscoverRadio(discoveredRadios: self.discoveredRadios)
                    }
                }
                
                // let the view controller know one or more radios were discovered
                //self.radioManagerDelegate?.didDiscoverRadio(discoveredRadios: self.discoveredRadios)
            }
        }
    }
    
    /// Process .tcpDidConnect Notification
    ///
    /// - Parameter note: a Notification instance
    ///
    @objc fileprivate func tcpDidConnect(_ note: Notification) {
        
        // a tcp connection has been established
        os_log("A TCP connection has been established.", log: RadioManager.model_log, type: .info)
        
        // save the active Radio as the selected Radio
        activeRadio = selectedRadio
        
        // observe changes to Radio properties
        observations(radio!, paths: _radioKeyPaths)
        
        // let the view controller know a radio was connected
        self.radioManagerDelegate?.didConnectToRadio()
    }
    
    /// Process .tcpDidDisconnect Notification
    ///
    /// - Parameter note: a Notification instance
    ///
    @objc fileprivate func tcpDidDisconnect(_ note: Notification) {
        
        // the TCP connection has disconnected
        os_log("The TCP connection is being terminated.", log: RadioManager.model_log, type: .info)
        if (note.object as! Radio.DisconnectReason) != .closed {
            
            // not a normal disconnect
           // notify GUI
            
            // let the view controller know a radio was disconnected to
            self.radioManagerDelegate?.didDisconnectFromRadio()

        }
    }
    
    // let the view controller or other object know the radio was initialized
    // at this point I have the radio but may not have slice and other information
    // i.e. SmartSDR may not be running
    @objc fileprivate func radioInitialized(_ note: Notification) {
        
        // the Radio class has been initialized
        if let radio = note.object as? Radio {
            os_log("The Radio has been initialized.", log: RadioManager.model_log, type: .info)
            DispatchQueue.main.async { [unowned self] in
                print (radio.slices.count)
                self.updateRadio()
                // use delegate to pass message to view controller ??
                // or use the radio available ??
            }
        }
    }
    
    
    // raise event and send to view controller
    // not currently using
    // will send a collection of some type instead of strings
    func updateRadio() {
        //let serialNumber = self.selectedRadio?.serialNumber
        //let activeSlice = "1"
        //let mode = TransmitMode.USB
        
        os_log("An update to the Radio has been received.", log: RadioManager.model_log, type: .info)
        
        // we have an update, let the GUI know
        //radioManagerDelegate?.didUpdateRadio(serialNumber: serialNumber!, activeSlice: activeSlice, transmitMode: mode)
        
        
    }
    
    /// Process a newly added Opus
    ///
    /// - Parameter note: a Notification instance
    ///
    @objc fileprivate func opusHasBeenAdded(_ note: Notification) {
        
        // the Opus class has been initialized
//        if let opus = note.object as? Opus {
//
//            DispatchQueue.main.async { [unowned self] in
//
//                // add Opus property observations
//                self.observations(opus, paths: self._opusKeyPaths)
//            }
//        }
    }
    
    /// Process a newly added Slice - when the radio first starts up you will get a
    /// notification for each slice that exists
    ///
    /// - Parameter note: a Notification instance
    ///
    @objc fileprivate func sliceHasBeenAdded(_ note: Notification) {
        
        if let slice = note.object as? xLib6000.Slice {
            
//            print ("slice: \(slice.id)")
//            print ("sliceActive: \(slice.active)")
//            print ("sliceTxEnabled: \(slice.txEnabled)")

             var sliceInfo = SliceInfo()
             sliceInfo.populateSliceInfo(sliceId: Int(slice.id)!, mode: slice.mode, isActiveSlice: slice.active, txEnabled: slice.txEnabled)
//            //let sliceInfo = SliceInfo(sliceId: Int(slice.id)!, mode: slice.mode, isActiveSlice: slice.active, txEnabled: slice.txEnabled)
//            
//            print ("sliceInfo: \(sliceInfo.sliceId)")
            
            availableSlices[sliceInfo.sliceId] = sliceInfo
            
            radioManagerDelegate?.didUpdateSlice(availableSlices: availableSlices)
            
        }
    }
    
    
    @objc fileprivate func sliceWillBeRemoved(_ note: Notification) {
        
        // the Opus class has been initialized
        if let slice = note.object as? xLib6000.Slice {
            print (slice.id)
            //
            //            DispatchQueue.main.async { [unowned self] in
            //
            //                // add Opus property observations
            //                self.observations(opus, paths: self._opusKeyPaths)
            //            }
        }
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - RadioManagerDelegate methods
    
    /// Force the Radio Factory to resend availableRadios
    ///
    func updateAvailableRadios() {
        
        radioFactory.updateAvailableRadios()
    }
    
    /// Stop the active Radio
    ///
    func closeRadio() {
        
        // remove observations of Radio properties
        observations(radio!, paths: _radioKeyPaths, remove: true)
        
        // perform an orderly close of the Radio resources
        radio?.disconnect()
        
        // remove the active Radio
        activeRadio = nil
    }
    
    // exposed function for the GUI to indicate which radio to connect to
    public func connectToRadio( serialNumber: String) {
        
        os_log("Connect to the Radio.", log: RadioManager.model_log, type: .info)
        
        for i in 0..<self.availableRadios.count {
            if self.availableRadios[i].nickname == serialNumber {
                if self.openRadio(self.availableRadios[i]) == true {
                    //            self.UpdateRadio()
                }
            }
        }
    }
    
    /// Connect / Disconnect the selected Radio
    ///
    /// - Parameter selectedRadio: the RadioParameters
    ///
    fileprivate func openRadio(_ selectedRadioParameters: RadioParameters?) -> Bool {
        
        self.selectedRadio = selectedRadioParameters
        
        if selectedRadio != nil && selectedRadio == activeRadio {
            
            // Disconnect the active Radio
            closeRadio()
            
        } else if selectedRadio != nil {
            
            // Disconnect the active Radio & Connect a different Radio
            if activeRadio != nil {
                
                // Disconnect the active Radio
                closeRadio()
            }
            
            // Create a Radio class
            radio = Radio(radioParameters: selectedRadio!, clientName: clientName, isGui: false)
            
            // start a connection to the Radio
            if !radio!.connect(selectedRadio: selectedRadio!) {
                // connect failed, log the error and return
                os_log("Connection to the Radio failed.", log: RadioManager.model_log, type: .error)
                return false
            }
        }
        
        return true
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - Audio methods
    
//    func selectAudioFile(tag: Int) {
//        audiomanager.selectAudioFile(buttonNumber: tag)
//    }
    
    // ----------------------------------------------------------------------------
    // MARK: Transmit methods
    
    func keyRadio(doTransmit: Bool) {
//        let radioIsKeyed: ReplyHandler = radio?.transmitSet(true, callback: ReplyHandler) {
//            
//        }
        
        radio?.transmitSet(doTransmit) { (result) -> () in
            // do stuff with the result
            print(result)
        }
        
//        radio?.transmitSet(false) { (result) -> () in
//            // do stuff with the result
//            print(result)
//        }
    
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
    fileprivate func observations<T: NSObject>(_ object: T, paths: [String], remove: Bool = false) {
        
        // for each KeyPath Add / Remove observations
        for keyPath in paths {
            
            //            print("\(remove ? "Remove" : "Add   ") \(object.className):\(keyPath) in " + kModule)
            
            if remove { object.removeObserver(self, forKeyPath: keyPath, context: nil) }
            else { object.addObserver(self, forKeyPath: keyPath, options: [.initial, .new], context: nil) }
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
                        
//                    case #keyPath(Radio.lineoutGain):
//                        //self._mainWindowController?.lineoutGain.integerValue = ch[.newKey] as! Int
//                        break
//                    case #keyPath(Radio.lineoutMute):
////                        self._mainWindowController?.lineoutMute.state = (ch[.newKey] as! Bool) ? NSControl.StateValue.onState : NSControl.StateValue.offState
//                        break
                    case #keyPath(Radio.headphoneGain):
//                        self._mainWindowController?.headphoneGain.integerValue = ch[.newKey] as! Int
                        break
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
