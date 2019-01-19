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
//  MainViewController.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/10/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, RadioManagerDelegate, PreferenceManagerDelegate {
   
    var radioManager: RadioManager!
    var audiomanager: AudioManager!
    var preferenceManager: PreferenceManager!
    
    var availableRadios = [(model: String, nickname: String, ipAddress: String, default: String, serialNumber: String)]()
    var defaultRadio = (model: "", nickname: "", ipAddress: "", default: "", serialNumber: "")
    
    //var transmitMode: TransmitMode = TransmitMode.Invalid
    //var availableSlices: [Int : SliceInfo] = [:]
    var isRadioConnected = false
    
    // MARK: Outlets
    @IBOutlet weak var voiceButton1: NSButton!
    @IBOutlet weak var serialNumberLabel: NSTextField!
    @IBOutlet weak var activeSliceLabel: NSTextField!
    @IBOutlet weak var buttonStackView: NSStackView!

    // MARK: Actions
    // this handles all of the voice buttons - use the tag value to determine which audio file to load
    @IBAction func voiceButtonClicked(_ sender: NSButton) {
        voiceButtonSelected(buttonNumber: sender.tag)
    }
    
    // show the preference pane
    @IBAction func buttonShowPreferences(_ sender: AnyObject) {
        showPreferences(sender)
    }
    
    // stop the current voice playback
    @IBAction func stopButtonClicked(_ sender: NSButton) {
        radioManager.keyRadio(doTransmit: false)
    }
    
    
    // generated code
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create the preference manager
        preferenceManager = PreferenceManager()
        preferenceManager.preferenceManagerDelegate = self
        
        // create an instance of my radio manager and assign a delegate from it so I can handle events it raises
        radioManager = RadioManager()
        radioManager.radioManagerDelegate = self
        
        // create the audio manager
        audiomanager = AudioManager()
        
        self.activeSliceLabel.stringValue = "Connecting"
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    // ---------------------------------------------------------------------------
    // cleanup network sockets when application terminates
    // TODO: put method in RadioManager and also close Radio object
    override func viewWillDisappear() {
        //radioManager.CloseAll()
    }
    
    
    // MARK: Handle button clicks etc.
    internal func voiceButtonSelected(buttonNumber: Int) {
        
        var floatArray = [Float]()
        
        floatArray = audiomanager.selectAudioFile(buttonNumber: buttonNumber)
        
        if floatArray.count > 0 {
            radioManager.keyRadio(doTransmit: true, buffer: floatArray)
        } else {
            let alert = NSAlert()
            alert.messageText = "Unable to play audio."
            alert.informativeText = "The file is missing or is the incorrect format."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            //alert.addButton(withTitle: "Cancel")
            alert.runModal() //== .alertFirstButtonReturn
        }
    }
    
    func radioMessageReceived(messageKey: String) {
        var heading: String
        var message: String
          
        switch messageKey {
        case "DAX":
            heading = "DAX Disabled"
            message = "TX DAX must be enabled"
        case "MODE":
            heading = "Invalid Mode"
            message = "The mode must be a voice mode"
        default:
            heading = "Unknown"
            message = messageKey
        }
        
        let alert = NSAlert()
        alert.messageText = heading
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        //alert.addButton(withTitle: "Cancel")
        alert.runModal() //== .alertFirstButtonReturn
    }
    
    // my code
    // Load the information for the default radio if there is any
    // Check how many radios were discovered. If there is a default and it matches the discovered radio - connect
    // otherwise show the preference pane. Also if there is a default, update its information
    // if there are multiple radios, see if one is the default, if so - connect
    // otherwise pop the preferences pane
    func didDiscoverRadio(discoveredRadios: [(model: String, nickname: String, ipAddress: String, default: String, serialNumber: String)]) {
        
        DispatchQueue.main.async { [unowned self] in
            
            var found: Bool = false
            self.availableRadios = discoveredRadios
            
            // FOR DEBUG: delete user defaults
            //UserDefaults.standard.set(nil, forKey: "defaultRadio")
            
        if let def = UserDefaults.standard.dictionary(forKey: "defaultRadio") {
                self.defaultRadio.model = def["model"] as! String
                self.defaultRadio.nickname = def["nickname"] as! String
                self.defaultRadio.ipAddress = def["ipAddress"] as! String
                self.defaultRadio.default = def["default"] as! String
                self.defaultRadio.serialNumber = def["serialNumber"] as! String
            }
            
            switch discoveredRadios.count {
                case 1:
                    if self.defaultRadio.serialNumber == discoveredRadios[0].serialNumber {
                        
                        // could have the same nickname but model or ipaddress may have changed
                        self.defaultRadio.model = discoveredRadios[0].model
                        self.defaultRadio.nickname = discoveredRadios[0].nickname
                        self.defaultRadio.ipAddress = discoveredRadios[0].ipAddress
                        self.updateUserDefaults()
                        
                        print("nickname \(self.defaultRadio.nickname)")
                        if self.radioManager.connectToRadio(serialNumber: self.defaultRadio.serialNumber) == true {
                            self.serialNumberLabel.stringValue = self.defaultRadio.nickname
                            self.isRadioConnected = true
                            self.activeSliceLabel.stringValue = "Connected"
                            self.enableVoiceButtons()
                        }
                    }
                    else{
                        self.showPreferences("" as AnyObject)
                    }
                    break
                default:
                    if self.defaultRadio.nickname != "" {
                        for radio in discoveredRadios {
                            if self.defaultRadio.serialNumber == radio.serialNumber && self.defaultRadio.default == YesNo.Yes.rawValue {
                                found = true
                                
                                // could have the same nickname but model or ipaddress may have change
                                self.defaultRadio.model = radio.model
                                self.defaultRadio.nickname = radio.nickname
                                self.defaultRadio.ipAddress = radio.ipAddress
                                self.updateUserDefaults()
                                
                                //print("nickname \(self.defaultRadio.nickname)")
                                if self.radioManager.connectToRadio(serialNumber: self.defaultRadio.serialNumber) == true {
                                    self.serialNumberLabel.stringValue = self.defaultRadio.nickname
                                    self.isRadioConnected = true
                                    self.activeSliceLabel.stringValue = "Connected"
                                    self.enableVoiceButtons()
                                }
                                break
                            }
                        }
                        
                        if !found {
                            self.showPreferences("" as AnyObject)
                        }
                    }
                    else {
                        self.showPreferences("" as AnyObject)
                    }

                    break
            }
        }
    }
    
    /**
        Update the user defaults
     */
    func updateUserDefaults() {
        
            var def = [String : String]()
        
            def["model"] = defaultRadio.model
            def["nickname"] = defaultRadio.nickname
            def["ipAddress"] = defaultRadio.ipAddress
            def["default"] = defaultRadio.default
            def["serialNumber"] = defaultRadio.serialNumber
            
            UserDefaults.standard.set(def, forKey: "defaultRadio")
    }

    /**
        select the desired radio and instruct the RadioManager to start the connect process
        - parameter serialNumber: String
     */
    func doConnectRadio(serialNumber: String) {
        if self.radioManager.connectToRadio(serialNumber: self.defaultRadio.serialNumber) == true {
            self.serialNumberLabel.stringValue = self.defaultRadio.nickname
            self.isRadioConnected = true
            self.activeSliceLabel.stringValue = "Connected"
            self.enableVoiceButtons()
        }
    }
    
    /**
        We disconnected to the selected radio.
     */
    func didDisconnectFromRadio() {
        
        DispatchQueue.main.async { [unowned self] in
            self.isRadioConnected = false
            self.activeSliceLabel.stringValue = "Disconnected"
        }
    }
    
    /**
        Enable all the voice bttons.
     */
    func enableVoiceButtons(){
        
        for case let button as NSButton in self.buttonStackView.subviews {
            button.isEnabled = true
        }
    }
    
    func openRadioSelector(serialNumber: String) {
        
    }
    
    // show the preferences panel and populate it
    func showPreferences(_ sender: AnyObject) {
        let SB = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let PVC: RadioPreferences = SB.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "radioPreferences")) as! RadioPreferences
        PVC.availableRadios = self.availableRadios
        PVC.preferenceManager = self.preferenceManager
        // This works with Swift 4
        //let SB = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        //let PVC: RadioPreferences = SB.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "radioPreferences")) as! RadioPreferences
        
        presentViewControllerAsSheet(PVC)
    }
    
} // end class

