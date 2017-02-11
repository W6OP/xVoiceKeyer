//
//  ViewController.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/10/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    
   
    
    

    // generated code
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // outlets
    
    @IBOutlet weak var voiceButton1: NSButton!
    
    
    // actions
    
    @IBAction func voiceButtonClicked(_ sender: NSButton) {
        //let radio = RadioFactory()
        //let instance = radio.availableRadioInstances()
        
        // debug.print
        //print ("The width of someResolution is \(instance?.count)")
        
        
         let radio: RadioFactory = RadioFactory()
         //let instance = radio.availableRadioInstances()
        
        
        
        
        
    }

} // end class

