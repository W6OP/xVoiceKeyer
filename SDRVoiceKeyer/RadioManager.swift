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
import xFlexAPI
import os

// event delegate
// implement in your viewcontroller to receive messages from the radio manager
protocol RadioManagerDelegate: class {
    // radio was discovered
    func didDiscoverRadio(discoveredRadios: [(model: String, nickname: String, ipAddress: String)])
    // an update to the radio was received
    func didUpdateRadio(serialNumber: String, activeSlice: String, transmitMode: TransmitMode)
    // probably not needed
    func openRadioSelector(serialNumber: String)
}

// structure to pass data back to view controller
struct SliceInfo {
    let handle: String
    let slice: String // create enum?
    let mode: String //TransmitMode
    let tx: String // Bool ??
    let complete: Bool
}


enum  TransmitMode: String{
    case Invalid
    case USB
    case LSB
    case SSB
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
    var discoveredRadios: [(model: String, nickname: String, ipAddress: String)]
    
    // ----------------------------------------------------------------------------
    // MARK: - Internal Radio properties
    
    // Radio currently running
    internal var activeRadio: RadioParameters?
    // Radio class in use
    internal var radio: Radio?
    
    // ----------------------------------------------------------------------------
    // MARK: - Private properties
    
    // Radio that is selected - may not be the active radio
    fileprivate var selectedRadio: RadioParameters?
    
    // Notification observers
    fileprivate var notifications = [NSObjectProtocol]()
    
    //fileprivate let _opusManager = OpusManager()
    
    // constants
    fileprivate let _log = Log.sharedInstance   // Shared log
    //fileprivate let _log: XCGLogger!          // Shared log
    
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
        
        discoveredRadios = [(model: String, nickname: String, ipAddress: String)]()
        
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
        nc.addObserver(forName:Notification.Name(rawValue:"meterHasBeenAdded"),
                       object:nil, queue:nil,
                       using:meterHasBeenAdded)
        
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
    
    // model: String, nickname: String, ipAddress: String
    @objc fileprivate func radiosAvailable(_ note: Notification) {
        
        DispatchQueue.main.async {
            
            // receive the updated list of Radios
            self.availableRadios = (note.object as! [RadioParameters])
            if self.availableRadios.count > 0 {
                
                os_log("Discovery process has completed.", log: RadioManager.model_log, type: .info)
                
                for item in self.availableRadios {
                    self.discoveredRadios.append((item.model, item.nickname!, item.ipAddress))
                }
                
                self.radioManagerDelegate?.didDiscoverRadio(discoveredRadios: self.discoveredRadios)
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
        
        // get the version info for the underlying xFlexAPI
//        let frameworkBundle = Bundle(identifier: kxFlexApiIdentifier)
//        let apiVersion = frameworkBundle?.object(forInfoDictionaryKey: versionKey) ?? "0"
//        let apiBuild = frameworkBundle?.object(forInfoDictionaryKey: buildKey) ?? "0"
        
        // get the version info for this app
//        let appVersion = Bundle.main.object(forInfoDictionaryKey: versionKey) ?? "0"
//        let appBuild = Bundle.main.object(forInfoDictionaryKey: buildKey) ?? "0"
        
        // observe changes to Radio properties
        observations(radio!, paths: _radioKeyPaths)
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
        }
    }
    /// Process a newly added Meter object
    ///
    /// - Parameter note: a Notification instance
    ///
    @objc fileprivate func meterHasBeenAdded(_ note: Notification) {
        
        //if let meter = note.object as? Meter {
            // is it one we need to watch?
            //if meter.name == self.kVoltageMeter || meter.name == self.kPaTempMeter {
                
                // YES, process the initial meter reading
                //processMeterUpdate(meter)
                
                // subscribe to its updates
                //NC.makeObserver(self, with: #selector(meterUpdated(_:)), of: .meterUpdated, object: meter)
            //}
        //}
    }
    
    @objc fileprivate func radioInitialized(_ note: Notification) {
        
        // the Radio class has been initialized
        if let radio = note.object as? Radio {
            os_log("The Radio has been initialized.", log: RadioManager.model_log, type: .info)
            DispatchQueue.main.async { [unowned self] in
                 print (radio.slices.count)
                self.UpdateRadio()
                // use delegate to pass message to view controller ??
                // or use the radio available ??
            }
        }
    }
    
    
    
    // raise event and send to view controller
    // not currently using
    // will send a collection of some type instead of strings
    func UpdateRadio() {
        let serialNumber = self.selectedRadio?.serialNumber
        let activeSlice = "1"
        let mode = TransmitMode.USB
        
        os_log("An update to the Radio has been received.", log: RadioManager.model_log, type: .info)
        
        // we have an update, let the GUI know
        radioManagerDelegate?.didUpdateRadio(serialNumber: serialNumber!, activeSlice: activeSlice, transmitMode: mode)
        
        
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
        
        // the Opus class has been initialized
                if let slice = note.object as? xFlexAPI.Slice {
                    print (slice.id)
                    //
        //            DispatchQueue.main.async { [unowned self] in
        //
        //                // add Opus property observations
        //                self.observations(opus, paths: self._opusKeyPaths)
        //            }
                }
    }
    
    
    @objc fileprivate func sliceWillBeRemoved(_ note: Notification) {
        
        // the Opus class has been initialized
        if let slice = note.object as? xFlexAPI.Slice {
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
        if self.openRadio(self.availableRadios[0]) == true {
//            self.UpdateRadio()
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
                DispatchQueue.main.async { [unowned self] in
                    
                    switch kp {
                        
                    case #keyPath(Radio.lineoutGain):
                        //self._mainWindowController?.lineoutGain.integerValue = ch[.newKey] as! Int
                        break
                    case #keyPath(Radio.lineoutMute):
//                        self._mainWindowController?.lineoutMute.state = (ch[.newKey] as! Bool) ? NSControl.StateValue.onState : NSControl.StateValue.offState
                        break
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
                        
                        if let opus = object as? Opus, let start = ch[.newKey] as? Bool{
                            
                            // Tx Opus starting / stopping
                            //self._opusManager.txAudio( start, opus: opus )
                        }
                        
                    case #keyPath(Opus.rxStreamStopped):
                        
                        // FIXME: Implement this
                        break
                        
                    default:
                        // log and ignore any other keyPaths
                        self._log.msg("Unknown observation - \(String(describing: keyPath))", level: .error, function: #function, file: #file, line: #line)
                    }
                }
            }
        }
    }
    
} // end class
