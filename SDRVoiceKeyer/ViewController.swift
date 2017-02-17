//
//  MainViewController.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/10/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa

extension ViewController: RadioManagerDelegate {
    func didUpdateRadio(sender: RadioManager) {
        // do stuff like updating the UI
        
        var a = 1
        
      
    }
}

// http://stackoverflow.com/questions/29418310/set-color-of-nsbutton-programmatically-swift

class ViewController: NSViewController {
    
    var radioManager: RadioManager!

    // generated code
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.discoveredRadios), name: NSNotification.Name.init(rawValue: "K6TURadioFactory"), object: nil)
        
        // create an instance of my radio manager
        do {
            try radioManager = RadioManager()
            radioManager.delegate = self
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
    override func viewWillDisappear() {
        radioManager.radioFactory.close()
    }
    
    // my code
    
    // Notification handler - this will fire when the first radio is discovered and
    // anytime a new radio is discovered, or an existing radio has a major change
    // If an error occurs in the RadioFactory.m a dictionary will be posted
    // TODO: Need to account for multiple entries into this function
    func discoveredRadios(notification: NSNotification){
        
        if let info = notification.userInfo as? Dictionary<String,String> {
            // Check if value present before using it
            if let error = info["Error"] {
                serialNumberLabel.stringValue = error
                return
            }
        }
        
        if radioManager != nil {
            do {
                serialNumberLabel.stringValue = try "S/N " + radioManager.DiscoverRadioInstances()
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

    // actions
    
    @IBAction func voiceButtonClicked(_ sender: NSButton) {
        
        activeSliceLabel.stringValue = "Button Clicked"
    }
    
//    func getSocket () {
//       var udpSocket: GCDAsyncUdpSocket
//        
//        udpSocket = GCDAsyncUdpSocket()
//        
//        udpSocket.didRe
//        
//        
//        
//    }
    

    // outlets
    
    @IBOutlet weak var voiceButton1: NSButton!
    
    @IBOutlet weak var serialNumberLabel: NSTextField!
    @IBOutlet weak var activeSliceLabel: NSTextField!
    
    @IBOutlet weak var buttonStackView: NSStackView!
    
} // end class

