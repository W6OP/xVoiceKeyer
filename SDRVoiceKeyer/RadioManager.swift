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

// event delegate
// implement in your viewcontroller to receive messages from the radio manager
protocol RadioManagerDelegate: class {
    func didDiscoverRadio(discoveredRadios: [String])
    func didUpdateRadio(serialNumber: String, activeSlice: String, transmitMode: TransmitMode)
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


enum TransmitMode{
    case Invalid
    case USB
    case LSB
    case SSB
    case AM
}

// wrapper class for the xFlexAPI written by Doug Adams K3TZR
internal class RadioManager: NSObject {
    
    var radioManagerDelegate:RadioManagerDelegate?
    var discoveredRadios: [String]
    
    var discoveryPort = 4992
    var checkInterval: TimeInterval = 1.0
    var notSeenInterval: TimeInterval = 3.0
    
    // ----------------------------------------------------------------------------
    // MARK: - Internal properties
    
    internal var activeRadio: RadioParameters?                      // Radio currently running
    internal var radio: Radio?                                      // Radio class in use
    
    // ----------------------------------------------------------------------------
    // MARK: - Private properties
    
    fileprivate var selectedRadio: RadioParameters?                // Radio to start
    
    
    fileprivate var notifications = [NSObjectProtocol]()           // Notification observers
    //fileprivate let _opusManager = OpusManager()
    
    // constants
    fileprivate let _log = Log.sharedInstance                       // Shared log
    //fileprivate let _log: XCGLogger!                                // Shared log
    
    fileprivate let log = (NSApp.delegate as! AppDelegate)
    fileprivate let kModule = "RadioViewController"                 // Module Name reported in log messages
    let kClientName = "SDRVoiceKeyer"
    
    ///fileprivate let kGuiFirmwareSupport = "1.10.16.x"               // Radio firmware supported by this App
    fileprivate let kxFlexApiIdentifier = "net.k3tzr.xFlexAPI"      // Bundle identifier for xFlexApi
    //fileprivate let kVoltageMeter = "+13.8B"                        // Short name of voltage meter
    //fileprivate let kPaTempMeter = "PATEMP"                         // Short name of temperature meter
    //fileprivate let kVoltageTemperature = "VoltageTemp"             // Identifier of toolbar VoltageTemperature toolbarItem
    
    //fileprivate let kSideStoryboard = "Side"                        // Storyboard names
    
    //fileprivate let kRadioPickerIdentifier = "RadioPicker"          // Storyboard identifiers
    fileprivate let kPcwIdentifier = "PCW"
    fileprivate let kPhoneIdentifier = "Phone"
    fileprivate let kRxIdentifier = "Rx"
    //fileprivate let kEqualizerIdentifier = "Equalizer"
    
    fileprivate let kConnectFailed = "Initial Connection failed"    // Error messages
    fileprivate let kUdpBindFailed = "Initial UDP bind failed"
    
    fileprivate let kVersionKey = "CFBundleShortVersionString"      // CF constants
    fileprivate let kBuildKey = "CFBundleVersion"
    
    fileprivate var availableRadios = [RadioParameters]()          // Array of available Radios
//    fileprivate enum ToolbarButton: String {                        // toolbar item identifiers
//        case Pan, Tnf, Markers, Remote, Speaker, Headset, VoltTemp, Side
//    }
    
//    fileprivate var _shouldOpenPicker = false
    fileprivate var radioFactory: RadioFactory
    
    override init() {
        
        radioFactory = RadioFactory()
        discoveredRadios = [String]()
        
        // give the API access to the logger
        Log.sharedInstance.delegate = (NSApp.delegate as! LogHandler)
        
        super.init()
        
        // add notification subscriptions
        addNotifications()
        
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - Notification Methods
    
    /// Add subscriptions to Notifications
    ///
    fileprivate func addNotifications() {
        
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
    }
    
    /// Process .tcpDidConnect Notification
    ///
    /// - Parameter note: a Notification instance
    ///
    @objc fileprivate func tcpDidConnect(_ note: Notification) {
        
        // a tcp connection has been established
        
        // remember the active Radio
        activeRadio = selectedRadio
        
        // get the version info for the underlying xFlexAPI
        let frameworkBundle = Bundle(identifier: kxFlexApiIdentifier)
        let apiVersion = frameworkBundle?.object(forInfoDictionaryKey: kVersionKey) ?? "0"
        let apiBuild = frameworkBundle?.object(forInfoDictionaryKey: kBuildKey) ?? "0"
        
        // get the version info for this app
        let appVersion = Bundle.main.object(forInfoDictionaryKey: kVersionKey) ?? "0"
        let appBuild = Bundle.main.object(forInfoDictionaryKey: kBuildKey) ?? "0"
        
        // observe changes to Radio properties
        //observations(radio!, paths: _radioKeyPaths)
    }
    /// Process .tcpDidDisconnect Notification
    ///
    /// - Parameter note: a Notification instance
    ///
    @objc fileprivate func tcpDidDisconnect(_ note: Notification) {
        
        // the TCP connection has disconnected
        if (note.object as! Radio.DisconnectReason) != .closed {
            
            // not a normal disconnect
            //openRadioPicker(self)
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
            
            DispatchQueue.main.async { [unowned self] in
                
                // use delegate to pass message to view controller ??
                // or use the radio available ??
            }
        }
    }
    
    @objc fileprivate func radiosAvailable(_ note: Notification) {
        
        DispatchQueue.main.async {
            
            // receive the updated list of Radios
            self.availableRadios = (note.object as! [RadioParameters])
            if self.availableRadios.count > 0 {
                
                for item in self.availableRadios {
                    self.discoveredRadios.append(item.serialNumber)
                }
                
                self.radioManagerDelegate?.didDiscoverRadio(discoveredRadios: self.discoveredRadios)
            }
        }
    }
    
    // raise event and send to view controller
    // not currently using
    func UpdateRadio() {
        var serialNumber = self.selectedRadio?.serialNumber
        var activeSlice = "1"
        var mode = TransmitMode.USB
        
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
        //observations(radio!, paths: _radioKeyPaths, remove: true)
        
        // perform an orderly close of the Radio resources
        radio?.disconnect()
        
        // remove the active Radio
        activeRadio = nil
    }
    
    // exposed function for the GUI to indicate which radio to connect to
    public func connectToRadio( serialNumber: String) {
        
        if self.openRadio(self.availableRadios[0]) == true {
            self.UpdateRadio()
        }
        
    }
    
    /// Connect / Disconnect the selected Radio
    ///
    /// - Parameter selectedRadio: the RadioParameters
    ///
    fileprivate func openRadio(_ selectedRadioParameters: RadioParameters?) -> Bool {
        
        // if open, close the Radio Picker
        //if _radioPickerViewController != nil { _radioPickerViewController = nil }
        
        self.selectedRadio = selectedRadioParameters
        
//        if selectedRadio != nil && selectedRadio == activeRadio {
//
//            // Disconnect the active Radio
//            closeRadio()
//
//        } else if selectedRadio != nil {
//
//            // Disconnect the active Radio & Connect a different Radio
//            if activeRadio != nil {
//
//                // Disconnect the active Radio
//                closeRadio()
//            }
            // Create a Radio class
            radio = Radio(radioParameters: selectedRadio!, clientName: kClientName, isGui: true)
            
            // start a connection to the Radio
            if !radio!.connect(selectedRadio: selectedRadio!) {
                
                // connect failed, log the error and return
                //self._log.msg(kConnectFailed, level: .error, function: #function, file: #file, line: #line)
                
                return false        // Connect failed
            }
            return true             // Connect succeeded
        //}
       // return false                // no radio selected
    }
    
} // end class
