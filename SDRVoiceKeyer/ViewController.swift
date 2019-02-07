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

/*
 MainViewController.swift
 SDRVoiceKeyer
 
 Created by Peter Bourget on 2/10/17.
 Copyright © 2019 Peter Bourget W6OP. All rights reserved.
 Description: Main View Controller for the SDR Voice Keyer
 */

import Cocoa

class ViewController: NSViewController, RadioManagerDelegate, PreferenceManagerDelegate, AudioManagerDelegate {
    
    var radioManager: RadioManager!
    var audiomanager: AudioManager!
    var preferenceManager: PreferenceManager!
    
    var availableRadios = [(model: String, nickname: String, ipAddress: String, default: String, serialNumber: String)]()
    var defaultRadio = (model: "", nickname: "", ipAddress: "", default: "", serialNumber: "")
    
    var isRadioConnected = false
    
    lazy var window: NSWindow! = self.view.window
    
    // MARK: Outlets
    @IBOutlet weak var voiceButton1: NSButton!
    @IBOutlet weak var serialNumberLabel: NSTextField!
    @IBOutlet weak var activeSliceLabel: NSTextField!
    @IBOutlet weak var buttonStackView: NSStackView!
    @IBOutlet weak var buttonStackViewTwo: NSStackView!
    @IBOutlet weak var gainSlider: NSSlider!
    @IBOutlet weak var gainLabel: NSTextField!
    
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
        stopTransmitting()
    }
    
    // update the label when the slider is changed
    @IBAction func gainSliderChanged(_ sender: NSSlider) {
        gainLabel.stringValue = "\(gainSlider.intValue)"
        self.updateUserDefaults()
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
        audiomanager.audioManagerDelegate = self
        self.activeSliceLabel.stringValue = "Connecting"
        
        findButton(view: self.view)
    }
    
    // generated code
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    // don't allow full screen
    override func viewDidAppear() {
        window.styleMask.remove(.resizable)
    }
    // generated code
    override func viewWillDisappear() {
        
    }
    
    // Radio Methods ---------------------------------------------------------------------------
    
    /**
    Immediately stop transmitting
     */
    internal func stopTransmitting() {
        let xmitGain = gainSlider.intValue
        radioManager.keyRadio(doTransmit: false, xmitGain: Int(xmitGain))
    }
    
    // MARK: GUI Methods
    
    /**
     Handle button clicks etc. from any voice button
     - parameter buttonNumber: Int
     */
    internal func voiceButtonSelected(buttonNumber: Int) {
        
        var floatArray = [Float]()
        let xmitGain = gainSlider.intValue
        
        self.serialNumberLabel.isEnabled = true
        
        if self.isRadioConnected {
            floatArray = audiomanager.selectAudioFile(buttonNumber: buttonNumber)
            
            if floatArray.count > 0 {
                radioManager.keyRadio(doTransmit: true, buffer: floatArray, xmitGain: Int(xmitGain))
            }
        } else {
            let alert = NSAlert()
            alert.messageText = "Radio Unavailable"
            alert.informativeText = "The Radio GUI seems to have gone away."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.beginSheetModal(for: NSApp.mainWindow!, completionHandler: { (response) in
                if response == NSApplication.ModalResponse.alertFirstButtonReturn { return }
            })
        }
    }
    
    /**
     receive messages from the radio manager
     - parameter messageKey: RadioManagerMessage - enum value for the message
     */
    func radioMessageReceived(messageKey: RadioManagerMessage) {
        var heading: String = ""
        var message: String = ""
        
        switch messageKey {
        case RadioManagerMessage.DAX:
            heading = "TX DAX Disabled"
            message = "TX DAX must be enabled to transmit."
        case RadioManagerMessage.MODE:
            heading = "Invalid Mode"
            message = "The mode must be a voice mode."
        case RadioManagerMessage.INACTIVE:
            //heading = "Missing Slice or Radio"
            //message = "There is no active slice or the radio GUI is missing."
            disableVoiceButtons()
            self.activeSliceLabel.stringValue = "No Active Slice"
            return
        case RadioManagerMessage.ACTIVE:
            enableVoiceButtons()
            self.activeSliceLabel.stringValue = "Connected"
            return
        }
        
        let alert = NSAlert()
        alert.messageText = heading
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: NSApp.mainWindow!, completionHandler: { (response) in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn { return }
        })
    }
    
    /**
     receive messages from the audio manager
     - parameter key: AudioMessage - enum value for the message
     - parameter messageData: String - data to be added to the message
     */
    func audioMessageReceived(messageKey: AudioMessage, message: String) {
        var heading: String
        
        switch messageKey {
        case AudioMessage.FileMissing:
            heading = "Missing File"
        case AudioMessage.InvalidFileType:
            heading = "Invalid File Type"
        case AudioMessage.ButtonNotConfigured:
            heading = "Button Not Configured"
        case AudioMessage.Error:
            heading = "An Error Has Occurred"
        case AudioMessage.InvalidSampleRate:
            heading = "Invalid Sample Rate"
        }
        
        let alert = NSAlert()
        alert.messageText = heading
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: NSApp.mainWindow!, completionHandler: { (response) in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn { return }
        })
    }
    
   
    /**
     Load the information for the default radio if there is any.
     Check how many radios were discovered. If there is a default and it matches the discovered radio - connect
     otherwise show the preference pane. Also if there is a default, update its information
     if there are multiple radios, see if one is the default, if so - connect
     otherwise pop the preferences pane.
     
     This is the normal flow. When the Connect button is clicked it goes straight to doConnectToradio()
     */
    func didDiscoverRadio(discoveredRadios: [(model: String, nickname: String, ipAddress: String, default: String, serialNumber: String)]) {
        
        var found: Bool = false
        self.availableRadios = discoveredRadios
        
        // FOR DEBUG: delete user defaults
//        deleteUserDefaults()
//        return
        
        if let def = UserDefaults.standard.dictionary(forKey: "defaultRadio") {
            self.defaultRadio.model = def["model"] as! String
            self.defaultRadio.nickname = def["nickname"] as! String
            self.defaultRadio.ipAddress = def["ipAddress"] as! String
            self.defaultRadio.default = def["default"] as! String
            self.defaultRadio.serialNumber = def["serialNumber"] as! String
            
            if def["xmitGain"] != nil {
                self.gainSlider.intValue = Int32(def["xmitGain"] as! String) ?? 35
                self.gainLabel.stringValue = def["xmitGain"] as! String
            } else {
                self.gainSlider.intValue = 35
                self.gainLabel.stringValue = "35"
            }
        }
        
        switch discoveredRadios.count {
        case 1:
            if self.defaultRadio.serialNumber == discoveredRadios[0].serialNumber {
                
                // could have the same nickname but model or ipaddress may have changed
                self.defaultRadio.model = discoveredRadios[0].model
                self.defaultRadio.nickname = discoveredRadios[0].nickname
                self.defaultRadio.ipAddress = discoveredRadios[0].ipAddress
                
                self.updateUserDefaults()
                
                self.doConnectRadio(serialNumber: self.defaultRadio.serialNumber, doConnect: true)
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
                        
                        self.doConnectRadio(serialNumber: self.defaultRadio.serialNumber, doConnect: true)
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
    
    /**
     Update the user defaults.
     */
    func updateUserDefaults() {
        
        var def = [String : String]()
        
        def["model"] = defaultRadio.model
        def["nickname"] = defaultRadio.nickname
        def["ipAddress"] = defaultRadio.ipAddress
        def["default"] = defaultRadio.default
        def["serialNumber"] = defaultRadio.serialNumber
        def["xmitGain"] = "\(gainSlider.intValue)"
        
        UserDefaults.standard.set(def, forKey: "defaultRadio")
    }
    
    /**
     Delete all the default settings. This is just used for debugging.
     */
    func deleteUserDefaults(){
        
        UserDefaults.standard.set(nil, forKey: "defaultRadio")
        UserDefaults.standard.set(nil, forKey: "NSNavLastRootDirectory")
        
        for i in 0..<21 {
            UserDefaults.standard.set(nil, forKey: "\(i)")
        }
        
    }
    
    /**
     Select the desired radio and instruct the RadioManager to start the connect process.
     - parameter serialNumber: String
     - parameter doConnect: Bool
     */
    func doConnectRadio(serialNumber: String, doConnect: Bool) {

        if self.radioManager.connectToRadio(serialNumber: serialNumber, doConnect: doConnect) == true {
            self.view.window?.title = "SDR Voice Keyer - " + self.defaultRadio.nickname
            self.isRadioConnected = true
            self.activeSliceLabel.stringValue = "Connected"
        }
    }
    
    /**
     We disconnected from the selected radio.
     */
    func didDisconnectFromRadio() {
        self.isRadioConnected = false
        self.activeSliceLabel.stringValue = "Disconnected"
    }
    
    /**
     Refresh the voice buttons lables.
     */
//    func doUpdateButtonLabels() {
//        findButton(view: self.view)
//    }
    
    /**
     Refresh the voice buttons.
     */
    func doUpdateButtons() {
        enableVoiceButtons()
    }
    
    /**
     Enable all the voice buttons.
     */
    func enableVoiceButtons(){
        for case let button as NSButton in self.buttonStackView.subviews {
            if UserDefaults.standard.string(forKey: String(button.tag)) != "" {
                button.isEnabled = true
            } else {
                button.isEnabled = false
            }
        }
        
        for case let button as NSButton in self.buttonStackViewTwo.subviews {
            if UserDefaults.standard.string(forKey: String(button.tag)) != "" {
                button.isEnabled = true
            } else {
                button.isEnabled = false
            }
        }
    }
    
    /**
     Disable all the voice buttons.
     */
    func disableVoiceButtons(){
        for case let button as NSButton in self.buttonStackView.subviews {
            button.isEnabled = false
        }
        
        for case let button as NSButton in self.buttonStackViewTwo.subviews {
            button.isEnabled = false
        }
    }
    
    /**
     Collect all the buttons from view and subviews
     - parameter view: - the view to search
     */
    func findButton(view: NSView) { //  -> [NSButton]
        
        var results = [NSButton]()
        let offset = 10 // labels start with tag = 11
        
        for subview in view.subviews as [NSView] {
            if let button = subview as? NSButton {
                if button.tag != 0 {
                    results += [button]
                    button.title = UserDefaults.standard.string(forKey: String(button.tag + offset)) ?? ""
                }
            } else {
                findButton(view: subview) // results += 
            }
        }
        //return results
    }
    
    
    
    /**
     Show the preferences panel and populate it
     */
    func showPreferences(_ sender: AnyObject) {
        let SB = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let PVC: RadioPreferences = SB.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "radioSelection")) as! RadioPreferences
        PVC.availableRadios = self.availableRadios
        PVC.preferenceManager = self.preferenceManager
       
        presentViewControllerAsSheet(PVC)
        // presentAsModalWindow(PVC)
        // present(_ PVC: NSViewController, asPopoverRelativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge, behavior: NSPopover.Behavior)

    }
    
} // end class

