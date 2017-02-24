//
//  MainViewController.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/10/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa


// http://stackoverflow.com/questions/29418310/set-color-of-nsbutton-programmatically-swift

class ViewController: NSViewController, RadioManagerDelegate {
    
    var radioManager: RadioManager!
    var audiomanager: AudioManager!
    //var activeSliceHandle = ""
    
    
    // outlets
    @IBOutlet weak var voiceButton1: NSButton!
    @IBOutlet weak var serialNumberLabel: NSTextField!
    @IBOutlet weak var activeSliceLabel: NSTextField!
    @IBOutlet weak var buttonStackView: NSStackView!

    // actions
    @IBAction func voiceButtonClicked(_ sender: NSButton) {
        audiomanager.selectAudioFile(tag: sender.tag)
    }
    
    
    @IBAction func buttonShowPreferences(_ sender: AnyObject) {
        showPreferences(sender)
    }
    
    // generated code
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.radioChanged), name: NSNotification.Name.init(rawValue: "K6TURadioFactory"), object: nil)
        
        // create an instance of my radio manager and assign a delegate from it
        // so I can handle events it raises
        do {
            try radioManager = RadioManager()
            radioManager.radioDelegate = self
            
            audiomanager = AudioManager()
        }
        catch let error as NSError {
            // debug.print
            print("Error: \(error.userInfo.description)")
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // cleanup network sockets when application terminates
    // TODO: put method in RadioManager and also close Radio object
    override func viewWillDisappear() {
        radioManager.CloseAll()
    }
    
    // my code
    
     // event handler from Radiomanager - do stuff like updating the UI
    func didUpdateRadio(sender: Radio) {
        //activeSliceLabel.stringValue = "Connected"
        
    }

    // Notification handler - this will fire when the first radio is discovered and
    // anytime a new radio is discovered, or an existing radio has a major change
    // If an error occurs in the RadioFactory.m a dictionary will be posted
    // TODO: Need to account for multiple entries into this function
    func radioChanged(notification: NSNotification){
        
        if var info = notification.userInfo as? Dictionary<String,String> {
            // Check if value present before using it
            if let error = info["Error"] {
                serialNumberLabel.stringValue = error
                return
            }
        }
        
        // this calls RadioManager.analyzePayload
        if var info = notification.userInfo as? Dictionary<String,String> {
            // Check if value present before using it
            if let payload = info["RadioPayload"] {
                // debug.print
                //print ("Payload Data --> \(payload)")
                
                let availableSlices = radioManager.analyzePayload(payload: payload) as [String: SliceInfo]
                
                activeSliceLabel.stringValue = "No Active Slice"
                for (slice, sliceInfo) in availableSlices {
                    switch slice {
                        case "slice0":
                            if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
                                activeSliceLabel.stringValue = "Slice A Active"
                            }
                        case "slice1":
                            if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
                                activeSliceLabel.stringValue = "Slice B Active"
                            }
                        case "slice2":
                            if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
                                activeSliceLabel.stringValue = "Slice C Active"
                            }
                        case "slice3":
                            if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
                                activeSliceLabel.stringValue = "Slice D Active"
                            }
                        case "slice4":
                            if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
                                activeSliceLabel.stringValue = "Slice E Active"
                            }
                        case "slice5":
                            if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
                                activeSliceLabel.stringValue = "Slice F Active"
                            }
                        case "slice6":
                            if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
                                activeSliceLabel.stringValue = "Slice G Active"
                            }
                        case "slice7":
                            if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
                                activeSliceLabel.stringValue = "Slice H Active"
                            }
                        default:
                        activeSliceLabel.stringValue = "No Active Slice"
                    }
                    
                }
                
                return
                
            }
        }
        
        // initialization
        if radioManager != nil {
            do {
                serialNumberLabel.stringValue = try "S/N " + radioManager.InitializeRadioInstances()
                activeSliceLabel.stringValue = "Connected"
                // enable buttons
                for case let button as NSButton in buttonStackView.subviews {
                    button.isEnabled = true
                }
            }
            catch let error as NSError {
                // debug.print
                print("Error: \(error.localizedDescription)")
            }
        } else {
            serialNumberLabel.stringValue = "Unable to find radio"
        }
    }
    
    
    // show the preferences panel and populate it
    func showPreferences(_ sender: AnyObject) {
        let SB = NSStoryboard(name: "Main", bundle: nil)
        let PVC: RadioPreferences = SB.instantiateController(withIdentifier: "radioPreferences") as! RadioPreferences
        
        self.presentViewControllerAsSheet(PVC)
    }
    
} // end class

