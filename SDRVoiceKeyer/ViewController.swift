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
        var ipaddress: String
        
        let radioFactory: RadioFactory = RadioFactory()
        let instance = radioFactory.availableRadioInstances()
        
        var radioInstance = [RadioInstance]()
        // this force casts an NSArray to Swift Array
        radioInstance = instance as! [RadioInstance]
        
        
        ipaddress = radioInstance[0].ipAddress
        
        
        
        
        //var someInts = [RadioInstance]()
        //someInts =  radioFactory.discoveredRadios

        
        //var radio: Radio
        var numberOfRadios = 0
        
        switch instance!.count {
            case 0:
            // pop message
            numberOfRadios = 0
        case 1:
            //radio = radioFactory[0]
            numberOfRadios = 1
        default:
            // do something else
            numberOfRadios = instance!.count
        }
        
         //myLabel.integerValue = instance?.count
        
         print ("The number of radios on the network is \(numberOfRadios)")
        
        
        
        
        
    }

} // end class

