//
//  RadioManager.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/12/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa

//
protocol RadioManagerDelegate: class {
    func didUpdateRadio(sender: Radio)
}

internal class RadioManager {
    
    weak var radioDelegate:RadioManagerDelegate?
    
    var radioFactory: RadioFactory
    var radio: Radio
    
    // TODO: Make sure exception handling works
    init() throws {
        
        radioFactory = RadioFactory.init()
        radio = Radio()
       
    }
    
    // Create a RadioFactory which starts the discovery process
    // Get the first radio's serial number to return to the view controller
    // TODO: Account for being called multiple times
    // TODO: Account for multiple radios
    internal func DiscoverRadioInstances () throws -> String {
        
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
            
            //radio.radioInstance = radioInstances[0]
            //radio = Radio.init(radioInstanceAndDelegate: radioInstances[0], delegate: RadioDelegate.self)
            
            CreateRadio(radioInstance: radioInstances[0])
            
            printDebugMessage ("The number of radios on the network is \(numberOfRadios) -- \(serialNumber)")
            
        } else {
            printDebugMessage ("Their were no radios found on the network")
        }
        
        return serialNumber
    }
    
    // Create a slice for the radio - or should we be getting the active slice?
    // maybe need SliceManager.swift code file
    // TODO: need to close radio connection
    func CreateRadio(radioInstance: RadioInstance) {
        
        radio = Radio.init(radioInstanceAndDelegate: radioInstance, delegate: MyDelegateRx)
        
        // we have a radio, let the GUI know
        radioDelegate?.didUpdateRadio(sender: radio)
        
    }
    
    func MyDelegateRx(radio: Radio) {
        
               // debug.print
        print (radio.slices.count)
    }
    
    
    func printDebugMessage (_ object: Any) {
        #if DEBUG
            print(object)
        #endif
    }

} // end class
