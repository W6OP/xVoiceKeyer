//
//  RadioManager.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/12/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Foundation

internal class RadioManager {
    
    
    var radioFactory: RadioFactory
    
    init() {
        
        radioFactory  = RadioFactory()
        
    }
    
   internal func DiscoverRadio () {
        var ipaddress: String
        
    
        
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(self.DicoverRadio),
//            name: .discoveredRadios,
//            object: nil)

    
    
    
    //let nc = NotificationCenter.default
    //nc.addObserver(forName:discoveredRadios, object:nil, queue:nil, using:catchNotification)
    
    
    
        
    //radioFactory  = RadioFactory()
    

        let instance = radioFactory.availableRadioInstances()
        
        var radioInstance = [RadioInstance]()
    
        // this force casts an NSArray to Swift Array
        radioInstance = instance as! [RadioInstance]

    
        if radioInstance.count > 0 {
            
            
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
            
            print ("The number of radios on the network is \(numberOfRadios) -- \(ipaddress)")
        } else {
            print ("The number of radios on the network is 0")
        }
    
    }
    
    
//   @objc func discoveredRadios(notification: NSNotification){
//        //do stuff
//        // debug.print
//        print ("Notification received. 1")
//        
//    }

} // end class
