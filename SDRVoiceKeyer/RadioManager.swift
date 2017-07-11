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

import Foundation
import xFlexAPI

// event delegate
// implement in your viewcontroller to receive messages from the radio manager
protocol RadioManagerDelegate: class {
    func didUpdateRadio(serialNumber: String, activeSlice: String, transmitMode: TransmitMode)
    func openRadioSelector(serialNumber: String)
}

internal class RadioManager: NSObject {
    
    var radioManagerDelegate:RadioManagerDelegate?
    
    // ----------------------------------------------------------------------------
    // MARK: - Internal properties
    
    internal var activeRadio: RadioParameters?                      // Radio currently running
    internal var radio: Radio?                                      // Radio class in use
    
    // ----------------------------------------------------------------------------
    // MARK: - Private properties
    
    fileprivate var selectedRadio: RadioParameters?                // Radio to start
    //fileprivate var _toolbar: NSToolbar?
    //fileprivate var _sideViewController: NSSplitViewController?
    //fileprivate var _panafallsViewController: PanafallsViewController?
    
    fileprivate var notifications = [NSObjectProtocol]()           // Notification observers
    //fileprivate var _radioPickerViewController: RadioPickerViewController?  // RadioPicker sheet controller
    //fileprivate var _voltageTempMonitor: ParameterMonitor?          // the Voltage/Temp ParameterMonitor
    //fileprivate let _opusManager = OpusManager()
    
    // constants
    //    fileprivate let _log = Log.sharedInstance                       // Shared log
    //    fileprivate let _log: XCGLogger!                                // Shared log
    
    fileprivate let log = (NSApp.delegate as! AppDelegate)
    fileprivate let kModule = "RadioViewController"                 // Module Name reported in log messages
    let kClientName = "SDRVoiceKeyer"
    
    fileprivate let kGuiFirmwareSupport = "1.10.16.x"               // Radio firmware supported by this App
    fileprivate let kxFlexApiIdentifier = "net.k3tzr.xFlexAPI"      // Bundle identifier for xFlexApi
    fileprivate let kVoltageMeter = "+13.8B"                        // Short name of voltage meter
    fileprivate let kPaTempMeter = "PATEMP"                         // Short name of temperature meter
    fileprivate let kVoltageTemperature = "VoltageTemp"             // Identifier of toolbar VoltageTemperature toolbarItem
    
    fileprivate let kSideStoryboard = "Side"                        // Storyboard names
    
    fileprivate let kRadioPickerIdentifier = "RadioPicker"          // Storyboard identifiers
    fileprivate let kPcwIdentifier = "PCW"
    fileprivate let kPhoneIdentifier = "Phone"
    fileprivate let kRxIdentifier = "Rx"
    fileprivate let kEqualizerIdentifier = "Equalizer"
    
    fileprivate let kConnectFailed = "Initial Connection failed"    // Error messages
    fileprivate let kUdpBindFailed = "Initial UDP bind failed"
    
    fileprivate let kVersionKey = "CFBundleShortVersionString"      // CF constants
    fileprivate let kBuildKey = "CFBundleVersion"
    
    fileprivate var _availableRadios = [RadioParameters]()          // Array of available Radios
//    fileprivate enum ToolbarButton: String {                        // toolbar item identifiers
//        case Pan, Tnf, Markers, Remote, Speaker, Headset, VoltTemp, Side
//    }
    
    fileprivate var _shouldOpenPicker = false
    fileprivate var _radioFactory = RadioFactory()
    
    override init() {
        
        // give the API access to the logger
        //Log.sharedInstance.delegate = (NSApp.delegate as! LogHandler)
        
        super.init()
        
        // add notification subscriptions
        addNotifications()
        
        
        // see if there is a default Radio
        //let params = Defaults[.defaultRadioParameters]
        //let defaultRadio = RadioParameters.parametersFromArray(valuesArray: params)
        
//        if defaultRadio.ipAddress != "" && defaultRadio.port != 0 {
//
//            _log.msg("Attempting to open Default Radio, IP \(defaultRadio.ipAddress), Port \(defaultRadio.port)", level: .info, function: #function, file: #file, line: #line)
//
//            // there is a default, try to open it
//            if !openRadio(defaultRadio) {
//
//                // open failed, open the picker
//                _shouldOpenPicker = true
//            }
//
//        } else {
//
//            // no default, open the Radio Picker sheet (when the Window appears)
//            _shouldOpenPicker = true
//        }
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - Notification Methods
    
    /// Add subscriptions to Notifications
    ///
    fileprivate func addNotifications() {
        
        // Initial TCP Connection opened
        NC.makeObserver(self, with: #selector(tcpDidConnect(_:)), of: .tcpDidConnect, object: nil)
        
        // TCP Connection disconnect
        NC.makeObserver(self, with: #selector(tcpDidDisconnect(_:)), of: .tcpDidDisconnect, object: nil)
        
        // a Meter was Added
        NC.makeObserver(self, with: #selector(meterHasBeenAdded(_:)), of: .meterHasBeenAdded, object: nil)
        
        // Radio Initialized
        NC.makeObserver(self, with: #selector(radioInitialized(_:)), of: .radioInitialized, object: nil)
        
        // Available Radios changed
        NC.makeObserver(self, with: #selector(radiosAvailable(_:)), of: .radiosAvailable, object: nil)
        
        // an Opus was Added
        NC.makeObserver(self, with: #selector(opusHasBeenAdded(_:)), of: .opusHasBeenAdded, object: nil)
    }
    /// Process .tcpDidConnect Notification
    ///
    /// - Parameter note: a Notification instance
    ///
    @objc fileprivate func tcpDidConnect(_ note: Notification) {
        
        // a tcp connection has been established
        
        // remember the active Radio
        activeRadio = selectedRadio
        
        // get Radio model & firmware version
        //Defaults[.radioFirmwareVersion] = activeRadio!.firmwareVersion!
        //Defaults[.radioModel] = activeRadio!.model
        
        // get the version info for the underlying xFlexAPI
//        let frameworkBundle = Bundle(identifier: kxFlexApiIdentifier)
//        let apiVersion = frameworkBundle?.object(forInfoDictionaryKey: kVersionKey) ?? "0"
//        let apiBuild = frameworkBundle?.object(forInfoDictionaryKey: kBuildKey) ?? "0"
//
        //Defaults[.apiVersion] = "v\(apiVersion) build \(apiBuild)"
        //Defaults[.apiFirmwareSupport] = radio!.kApiFirmwareSupport
        
        // get the version info for this app
//        let appVersion = Bundle.main.object(forInfoDictionaryKey: kVersionKey) ?? "0"
//        let appBuild = Bundle.main.object(forInfoDictionaryKey: kBuildKey) ?? "0"
        
        //Defaults[.guiVersion] = "v\(appVersion) build \(appBuild)"
        //Defaults[.guiFirmwareSupport] = kGuiFirmwareSupport
        
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
        
        if let meter = note.object as? Meter {
            
            // is it one we need to watch?
            if meter.name == self.kVoltageMeter || meter.name == self.kPaTempMeter {
                
                // YES, process the initial meter reading
                //processMeterUpdate(meter)
                
                // subscribe to its updates
                //NC.makeObserver(self, with: #selector(meterUpdated(_:)), of: .meterUpdated, object: meter)
            }
        }
    }
    /// Process .radioInitialized Notification
    ///
    /// - Parameter note: a Notification instance
    ///
    @objc fileprivate func radioInitialized(_ note: Notification) {
        
        // the Radio class has been initialized
        if let radio = note.object as? Radio {
            
            DispatchQueue.main.async { [unowned self] in
                
                // Get a reference to the Window Controller containing the toolbar items
//                self._mainWindowController = self.view.window?.windowController as? MainWindowController
//
//                // Initialize the toolbar items
//                self._mainWindowController?.lineoutGain.integerValue = radio.lineoutGain
//                self._mainWindowController?.lineoutMute.state = radio.lineoutMute ? NSControl.StateValue.onState : NSControl.StateValue.offState
//                self._mainWindowController?.headphoneGain.integerValue = radio.headphoneGain
//                self._mainWindowController?.headphoneMute.state = radio.headphoneMute ? NSControl.StateValue.onState : NSControl.StateValue.offState
//                self._mainWindowController?.window?.viewsNeedDisplay = true
            }
        }
    }
    
    @objc fileprivate func radiosAvailable(_ note: Notification) {
        
        DispatchQueue.main.async {
            
            // receive the updated list of Radios
            self._availableRadios = (note.object as! [RadioParameters])
            if self._availableRadios.count > 0 {
                if self.openRadio(self._availableRadios[0]) == true {
                    self.UpdateRadio()
                }
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
    // MARK: - RadioPickerDelegate methods
    
    /// Force the Radio Factory to resend availableRadios
    ///
    func updateAvailableRadios() {
        
        _radioFactory.updateAvailableRadios()
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
    /// Connect / Disconnect the selected Radio
    ///
    /// - Parameter selectedRadio: the RadioParameters
    ///
    func openRadio(_ selectedRadioParameters: RadioParameters?) -> Bool {
        
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
