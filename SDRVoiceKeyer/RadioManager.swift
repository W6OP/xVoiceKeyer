//
//  RadioManager.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/12/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa

internal class RadioManager {
    
    
    var radioFactory: RadioFactory
    var radio: Radio
    
    init() {
        
        radioFactory  = RadioFactory()
        radio = Radio()
    }
    
    // Create a RadioFactory which starts the discovery process
    // Get the first radio's serial number to return to the view controller
    // TODO: Account for being called multiple times
    // TODO: Account for multiple radios
    internal func DiscoverRadio () -> String {
        
        var serialNumber = "Radio Not Found"
        var numberOfRadios = 0
        var radioInstances = [RadioInstance]()
        
        // this force casts an NSArray to Swift Array
        radioInstances = radioFactory.availableRadioInstances() as! [RadioInstance]
        
        if radioInstances.count > 0 {
            serialNumber = radioInstances[0].serialNum
            
            switch radioInstances.count {
            case 1:
                numberOfRadios = 1
            default:
                // do something else
                numberOfRadios = radioInstances.count
            }
            
            radio.radioInstance = radioInstances[0]
            
            CreateSlice()
            
            printDebugMessage ("The number of radios on the network is \(numberOfRadios) -- \(serialNumber)")
            
        } else {
            printDebugMessage ("The number of radios on the network is 0")
        }
        
        return serialNumber
        
    }
    
    // Create a slice for the radio - or should we be getting the active slice?
    func CreateSlice() {
        //for slice: Slice in radio {
            
        //}
    }
    
    
    func printDebugMessage (_ object: Any) {
        #if DEBUG
            print(object)
        #endif
    }

} // end class
