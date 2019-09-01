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
import Repeat

/*
 MainViewController.swift
 SDRVoiceKeyer
 
 Created by Peter Bourget on 2/10/17.
 Copyright © 2019 Peter Bourget W6OP. All rights reserved.
 Description: Main View Controller for the SDR Voice Keyer
 */
class ViewController: NSViewController, RadioManagerDelegate, PreferenceManagerDelegate, AudioManagerDelegate {
    
    var radioManager: RadioManager!
    var audiomanager: AudioManager!
    var preferenceManager: PreferenceManager!
    
    // this is only used once - in showPreferences - can I somehow eliminate it?
    var radios = [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: String)]()
    private var defaultStation = (model: "", nickname: "", stationName: "", default: "", serialNumber: "", clientId: "")
    private let radioKey = "defaultRadio"
    
    var isRadioConnected = false
    var isSliceActive = false
    var timerState: String = "ON"
    var idTimer :Repeater?
    var idlabelTimer :Repeater?
    
    lazy var window: NSWindow! = self.view.window
    
    // MARK: Outlets
    @IBOutlet weak var voiceButton1: NSButton!
    @IBOutlet weak var serialNumberLabel: NSTextField!
    @IBOutlet weak var activeSliceLabel: NSTextField!
    @IBOutlet weak var buttonStackView: NSStackView!
    @IBOutlet weak var buttonStackViewTwo: NSStackView!
    @IBOutlet weak var gainSlider: NSSlider!
    @IBOutlet weak var gainLabel: NSTextField!
    @IBOutlet weak var buttonSendID: NSButton!
    @IBOutlet weak var buttonStop: NSButton!
    @IBOutlet weak var labelSlice: NSTextField!
    @IBOutlet weak var labelMode: NSTextField!
    @IBOutlet weak var labelFrequency: NSTextField!
    @IBOutlet weak var labelStation: NSTextField!
    //@IBOutlet weak var labelSendID: NSTextField!
    
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
    
    @IBAction func sendID(_ sender: NSButton) {
        
        self.idlabelTimer = nil
        //self.labelSendID.isHidden = true
        //self.labelSendID.backgroundColor = NSColor.red
        voiceButtonSelected(buttonNumber: sender.tag)
    }
    
    // update the label when the slider is changed
    @IBAction func gainSliderChanged(_ sender: NSSlider) {
        gainLabel.stringValue = "\(gainSlider.intValue)"
        self.updateUserDefaults()
    }
    
    @IBAction func updateFilePreferences(_ sender: AnyObject){
        showFilePreferences(sender)
    }
    
    // enable the id timer
    @IBAction func enableIDTimer(_ sender: NSButton) {
        
        // reset back for distribution
        let timerInterval: Int = 1 //Int(UserDefaults.standard.string(forKey: "TimerInterval") ?? "10") ?? 10
        
        switch sender.state {
        case .on:
            preferenceManager.enableTimer(isEnabled: true, interval: timerInterval )
        case .off:
            preferenceManager.enableTimer(isEnabled: false, interval: timerInterval )
        default: break
        }
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
        
        updateButtonTitles(view: self.view)
        //self.labelSendID.backgroundColor = NSColor.green
        
       
//        buttonSendID.wantsLayer = true
//        buttonSendID.layer?.backgroundColor = NSColor.red.cgColor
        
        // only if no border
        //(buttonSendID.cell! as! NSButtonCell).backgroundColor = .red
        
        if let mutableAttributedTitle = buttonStop.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: NSColor.red, range: NSRange(location: 0, length: mutableAttributedTitle.length))
            buttonStop.attributedTitle = mutableAttributedTitle
        }
 
        // FOR DEBUG: delete user defaults
        //deleteUserDefaults()
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
        // keep on top of other windows
        self.window.level = NSWindow.Level.statusBar
    }
    // generated code
    override func viewWillDisappear() {
        
    }
    
    // Radio Methods ---------------------------------------------------------------------------
    
    /**
     Immediately stop transmitting
     */
    func stopTransmitting() {
        let xmitGain = gainSlider.intValue
        radioManager.keyRadio(doTransmit: false, xmitGain: Int(xmitGain))
        self.timerExpired = false
    }
    
    // MARK: GUI Methods
    
    /**
     Handle button clicks etc. from any voice button
     - parameter buttonNumber: Int
     */
    func voiceButtonSelected(buttonNumber: Int) {
        
        var transmitGain: Int = 35
        
        self.timerExpired = false
        self.buttonSendID.wantsLayer = true
        self.buttonSendID.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        DispatchQueue.main.async {
            let xmitGain = self.gainSlider.intValue
            transmitGain = Int(xmitGain)
        }
        
        if self.isRadioConnected {
            selectAudioFile(buttonNumber: buttonNumber, transmitGain: transmitGain)
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
     Select the audio file to transmit and return it as an array
     of 32 bit floats
     - parameter buttonNumber: Int
     - parameter transmitGain: Int
     */
    func selectAudioFile(buttonNumber: Int, transmitGain: Int){
        var floatArray = [Float]()
        
        floatArray = self.audiomanager.selectAudioFile(buttonNumber: buttonNumber)
        
        if floatArray.count > 0 {
            self.radioManager.keyRadio(doTransmit: true, buffer: floatArray, xmitGain: transmitGain)
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
            isSliceActive = false
            disableVoiceButtons()
            self.labelSlice.stringValue = "No TX Slice"
            return
        case RadioManagerMessage.ACTIVE:
            self.isSliceActive = true
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
    func didDiscoverRadio(discoveredRadios: [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: String)]) {
        
        var found: Bool = false
        self.radios = discoveredRadios
        
        if let defaults = UserDefaults.standard.dictionary(forKey: radioKey) {
            self.defaultStation.model = defaults["model"] as! String
            self.defaultStation.nickname = defaults["nickname"] as! String
            self.defaultStation.stationName = defaults["stationName"] as! String
            self.defaultStation.default = defaults["default"] as! String
            self.defaultStation.serialNumber = defaults["serialNumber"] as! String
            if defaults["clientId"] != nil {
                self.defaultStation.clientId = defaults["clientId"] as! String
            }
            
            if defaults["xmitGain"] != nil {
                self.gainSlider.intValue = Int32(defaults["xmitGain"] as! String) ?? 35
                self.gainLabel.stringValue = defaults["xmitGain"] as! String
            } else {
                self.gainSlider.intValue = 35
                self.gainLabel.stringValue = "35"
            }
        }
        
        switch discoveredRadios.count {
        case 1:
            if self.defaultStation.serialNumber == discoveredRadios[0].serialNumber {
                
                // could have the same nickname but model or ipaddress may have changed
                self.defaultStation.model = discoveredRadios[0].model
                self.defaultStation.nickname = discoveredRadios[0].nickname
                
                self.updateUserDefaults()
                
                self.doConnectRadio(serialNumber: self.defaultStation.serialNumber,stationName: self.defaultStation.stationName, clientId: self.defaultStation.clientId,  doConnect: true)
            }
            else{
                self.showPreferences("" as AnyObject)
            }
            break
        default:
            if self.defaultStation.nickname != "" {
                for radio in discoveredRadios {
                    if self.defaultStation.serialNumber == radio.serialNumber && self.defaultStation.default == YesNo.Yes.rawValue {
                        found = true
                        
                        // could have the same nickname but model or ipaddress may have change
                        self.defaultStation.model = radio.model
                        self.defaultStation.nickname = radio.nickname
                        self.defaultStation.stationName = radio.stationName
                        self.defaultStation.clientId = radio.clientId
                        
                        self.updateUserDefaults()
                        
                        self.doConnectRadio(serialNumber: self.defaultStation.serialNumber,stationName: self.defaultStation.stationName, clientId: self.defaultStation.clientId,  doConnect: true)
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
        
        var defaults = [String : String]()
        
        defaults["model"] = defaultStation.model
        defaults["nickname"] = defaultStation.nickname
        defaults["stationName"] = defaultStation.stationName
        defaults["default"] = defaultStation.default
        defaults["serialNumber"] = defaultStation.serialNumber
        defaults["clientId"] = defaultStation.clientId
        defaults["xmitGain"] = "\(gainSlider.intValue)"

        UserDefaults.standard.set(defaults, forKey: radioKey)
        UserDefaults.standard.set(timerState, forKey: "TimerState")
    }
    
    /**
     Delete all the default settings. This is just used for debugging.
     */
    func deleteUserDefaults(){
        
        UserDefaults.standard.set(nil, forKey: radioKey)
        UserDefaults.standard.set(nil, forKey: "NSNavLastRootDirectory")
        UserDefaults.standard.set(nil, forKey: "TimerState")
        UserDefaults.standard.set(nil, forKey: "TimerInterval")
        
        for i in 0..<21 {
            UserDefaults.standard.set(nil, forKey: "\(i)")
        }
        
        UserDefaults.standard.set(nil, forKey: "\(101)")
        UserDefaults.standard.set(nil, forKey: "\(102)")
    }
    
    /**
     Select the desired radio and instruct the RadioManager to start the connect process.
     - parameter serialNumber: String
     - parameter doConnect: Bool
     */
    func doConnectRadio(serialNumber: String, stationName: String, clientId: String, doConnect: Bool) {
        
        if self.radioManager.connectToRadio(serialNumber: serialNumber, clientStation: stationName, clientId: clientId, doConnect: doConnect) == true {
            self.view.window?.title = "SDR Voice Keyer - " + self.defaultStation.nickname
            self.isRadioConnected = true
            isSliceActive = true // this is just an assumption
            self.activeSliceLabel.stringValue = "Connected"
        }
    }
    
    /**
     We disconnected from the selected radio.
     */
    func didDisconnectFromRadio() {
        self.isRadioConnected = false
        self.isRadioConnected = false
        self.activeSliceLabel.stringValue = "Disconnected"
    }
    
    /**
     Refresh the voice buttons.
     */
    func doUpdateButtons() {
        if self.isRadioConnected && self.isSliceActive {
            enableVoiceButtons()
        }
    }
    
    /**
     Refresh the voice buttons labels.
     */
    func doUpdateButtonLabels() {
        updateButtonTitles(view: self.view)
        audiomanager.clearFileCache()
        if self.isRadioConnected && self.isSliceActive {
            enableVoiceButtons()
        }
    }
    
    /**
     Update the status labels when the radio notifies us of a change
     */
    func updateView(components: (slice: String, mode: String, frequency: String, station: String)) {
        UI {
            self.labelFrequency.stringValue = components.frequency
            self.labelMode.stringValue = components.mode
            self.labelSlice.stringValue = "Slice \(components.slice)"
            self.labelStation.stringValue = components.station
        }
    }
    
    /**
     Turn on or off the ID timer.
     */
    func doSetTimer(isEnabled: Bool, interval: Int) {
        self.idTimer = Repeater(interval: .minutes(interval), mode: .infinite) { _ in
            print("timer fired = \(interval)")
            //self.selectAudioFile(buttonNumber: 102, transmitGain: transmitGain)
            UI{
                //self.labelSendID.backgroundColor = NSColor.green
                //self.labelSendID.isHidden = false
                self.startLabelTimer()
            }
        }
        
        self.idTimer!.start()
    }
    var timerExpired = false
    func startLabelTimer() {
        
        self.idlabelTimer = Repeater(interval: .milliseconds(750), mode: .infinite) { _ in
            UI{
                if self.timerExpired {
                    self.timerExpired = false
                    //if self.labelSendID.isHidden {
                    //self.labelSendID.backgroundColor = NSColor.green
                    self.buttonSendID.wantsLayer = true
                    self.buttonSendID.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
                    //self.labelSendID.isHidden = false
                } else {
                    self.timerExpired = true
                    //self.labelSendID.isHidden = true
                    //self.labelSendID.backgroundColor = NSColor.red
                    self.buttonSendID.wantsLayer = true
                    self.buttonSendID.layer?.backgroundColor = NSColor.green.cgColor
                }
            }
        }
        
        self.idlabelTimer!.start()
    }
    
    /**
     Enable all the voice buttons.
     */
    func enableVoiceButtons(){
        
        for case let button as NSButton in self.buttonStackView.subviews {
            if UserDefaults.standard.string(forKey: String(button.tag)) != "" {
                button.isEnabled = self.isRadioConnected
            } else {
                button.isEnabled = false
            }
        }
        
        for case let button as NSButton in self.buttonStackViewTwo.subviews {
            if UserDefaults.standard.string(forKey: String(button.tag)) != "" {
                button.isEnabled = self.isRadioConnected
            } else {
                button.isEnabled = false
            }
        }
        
        // Send ID button
        if UserDefaults.standard.string(forKey: String(102)) != "" {
            buttonSendID.isEnabled = self.isRadioConnected
        } else {
            buttonSendID.isEnabled = false
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
        
        buttonSendID.isEnabled = false
    }
    
    /**
     Collect all the buttons from view and subviews and update their label (title)
     - parameter view: - the view to search
     */
    func updateButtonTitles(view: NSView) {
        
        var results = [NSButton]()
        let offset = 10 // labels start with tag = 11
        
        for subview in view.subviews as [NSView] {
            if let button = subview as? NSButton {
                if button.tag != 0 && button.tag != 102 {
                    results += [button]
                    button.title = UserDefaults.standard.string(forKey: String(button.tag + offset)) ?? ""
                }
            } else {
                updateButtonTitles(view: subview)
            }
        }
    }
    
    /**
     Show the file preferences panel and populate it
     */
    func showFilePreferences(_ sender: AnyObject) {
        let SB = NSStoryboard(name: "Main", bundle: nil)
        let PVC: FilePreferences = SB.instantiateController(withIdentifier: "filePreferences") as! FilePreferences
        PVC.preferenceManager = self.preferenceManager
        
        //presentViewControllerAsSheet(PVC)
        presentAsModalWindow(PVC)
        // present(_ PVC: NSViewController, asPopoverRelativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge, behavior: NSPopover.Behavior)
        
    }
    
    
    /**
     Show the radio selector panel and populate it
     */
    func showPreferences(_ sender: AnyObject) {
        let SB = NSStoryboard(name: "Main", bundle: nil)
        let PVC: RadioPreferences = SB.instantiateController(withIdentifier: "radioSelection") as! RadioPreferences
        //PVC.buildStationList(radios: self.radios)
        PVC.station = self.radios
        PVC.preferenceManager = self.preferenceManager
        
        presentAsSheet(PVC)
        // presentAsModalWindow(PVC)
        // present(_ PVC: NSViewController, asPopoverRelativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge, behavior: NSPopover.Behavior)
        
    }
    
} // end class

