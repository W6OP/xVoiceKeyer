//
//  ViewController.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/10/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    
   
    var radioManager: RadioManager!
    
   

    // generated code
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        radioManager = RadioManager()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.discoveredRadios), name: NSNotification.Name.init(rawValue: "K6TURadioFactory"), object: nil)

      
        
        //radioManager.DiscoverRadio()
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // my code
    @objc func discoveredRadios(notification: NSNotification){
        //do stuff
        // debug.print
        print ("Notification received. 2")
        
        radioManager.DiscoverRadio()
        
    }


    // outlets
    
    @IBOutlet weak var voiceButton1: NSButton!
    
    
    // actions
    
    @IBAction func voiceButtonClicked(_ sender: NSButton) {
        
    }

} // end class

