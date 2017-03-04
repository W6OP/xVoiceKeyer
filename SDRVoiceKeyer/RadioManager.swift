//
//  RadioManager.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/12/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa
import Foundation

// extension to use Scanner in Swift
// https://www.raywenderlich.com/128792/nsscanner-tutorial-for-os-x
extension Scanner {
    
    func scanUpToCharactersFrom(_ set: CharacterSet) -> String? {
        var result: NSString?                                                           // 1.
        return scanUpToCharacters(from: set, into: &result) ? (result as? String) : nil // 2.
    }
    
    func scanUpTo(_ string: String) -> String? {
        var result: NSString?
        return self.scanUpTo(string, into: &result) ? (result as? String) : nil
    }
    
    func scanDouble() -> Double? {
        var double: Double = 0
        return scanDouble(&double) ? double : nil
    }
}

// structure to pass data back to view controller
struct SliceInfo {
    let handle: String
    let slice: String
    let mode: String
    let tx: String
    let complete: Bool
}

// event delegate
protocol RadioManagerDelegate: class {
    func didUpdateRadio(sender: Radio)
}

// begin class
internal class RadioManager: NSObject {
    
    weak var radioDelegate:RadioManagerDelegate?
    
    var radioFactory: RadioFactory
    var radio: Radio
    var availableRadioInstances: [RadioInstance]
    var availableSlices: [String: SliceInfo]
    
    // TODO: Make sure exception handling works
    override init() {
       
        
        radioFactory = RadioFactory.init()
        radio = Radio()
        availableRadioInstances = [RadioInstance]()
        availableSlices = [String: SliceInfo]()
        
         super.init()
        
        radioFactory.InitializeRadioFactory()
    }
    
    // Create a RadioFactory which starts the discovery process
    // Get the first radio's serial number to return to the view controller
    // TODO: Account for being called multiple times
    // TODO: Account for multiple radios
    internal func InitializeRadioInstances ()  -> String { // throws
        
        var serialNumber = "Radio Not Found"
        var numberOfRadios = 0
        var radioInstances = [RadioInstance]()
        
        //radioFactory.InitializeRadioFactory()
        
        // this force casts an NSArray to Swift Array
        //radioInstances = radioFactory.availableRadioInstances() as! [RadioInstance]
        radioInstances = self.availableRadioInstances // as! [RadioInstance]
        
        if radioInstances.count > 0 {
            serialNumber = radioInstances[0].serialNum
            
            switch radioInstances.count {
            case 1:
                numberOfRadios = 1
            default:
                // do something else
                numberOfRadios = radioInstances.count
            }
            
            //InitializeRadio(radioInstance: radioInstances[0])
            radio = Radio.init(radioInstanceAndDelegate: radioInstances[0], delegate: radioDelegate)
            
            printDebugMessage ("The number of radios on the network is \(numberOfRadios) -- \(serialNumber)")
            
        } else {
            printDebugMessage ("Their were no radios found on the network")
        }
        
        return serialNumber
    }
    
    
    // need to get all the slices
    // find one that has tx=1
    // check if the mode = USB or LSB or AM
    internal func analyzePayload(payload: String) -> [String: SliceInfo] {
        
        var sliceInfo: SliceInfo!
        var sliceHandle = ""
        var slice = ""
        var mode = ""
        var tx = ""
        var complete = false
        var count = 0
        
        // Create a CharacterSet of delimiters.
        let separators = CharacterSet(charactersIn: "| =")
        // Split based on separators
        let parts = payload.components(separatedBy: separators)

        
        let scanner = Scanner(string: payload)
        //scanner.charactersToBeSkipped = nil //CharacterSet(charactersIn: "|")
        
        var temp = scanner.scanUpTo("|")! // gets the status handle
        sliceHandle = temp
        
        temp = scanner.scanUpTo("slice ") ?? "" // this gets us the "|"
        temp = scanner.scanUpTo(" ") ?? "" // gets us "slice"
        
        if temp == "slice" {
            for (index, items) in parts.enumerated() {
                if items == "slice" {
                    slice = parts[index + 1]
                    count += 1
                }
                
                if items == "mode" {
                    mode = parts[index + 1]
                    count += 1
                }
                
                if items == "tx" {
                    tx  = parts[index + 1]
                    count += 1
                }
                
                if items == "active" {
                    tx = parts[index + 1]
                    count += 1
                }
            }
            
            if count >= 3 {
                complete = true
            }
            
            sliceInfo = SliceInfo(handle: sliceHandle, slice: slice, mode: mode, tx: tx, complete: complete)
            
            updateAvailableSlices(sliceInfo: sliceInfo)
        }
        
        return availableSlices

    }
    
    // payloads come in with few or many properties and I need to update
    // the properties I need to use later. Sometimes the properties are
    // empty so I need to preserve the previous values.
    func updateAvailableSlices (sliceInfo: SliceInfo) {
        let slice = sliceInfo.slice
        var updated = false
        var sliceInfoMode: SliceInfo!
        var sliceInfoTx: SliceInfo!
        
        if let val = availableSlices["slice" + slice] {
            if sliceInfo.mode.isEmpty {
               sliceInfoMode = SliceInfo(handle: sliceInfo.handle, slice: sliceInfo.slice, mode: val.mode, tx: sliceInfo.tx, complete: sliceInfo.complete)
               availableSlices["slice" + slice] = sliceInfoMode
               updated = true
            } else {
                if sliceInfo.mode != val.mode {
                    sliceInfoMode = SliceInfo(handle: sliceInfo.handle, slice: sliceInfo.slice, mode: sliceInfo.mode, tx: sliceInfo.tx, complete: sliceInfo.complete)
                    availableSlices["slice" + slice] = sliceInfoMode
                    updated = true
                }
            }
           
            if sliceInfo.tx.isEmpty {
                if updated == true {
                    sliceInfoTx = SliceInfo(handle: sliceInfoMode.handle, slice: sliceInfoMode.slice, mode: sliceInfoMode.mode, tx: val.tx, complete: sliceInfoMode.complete)
                    
                } else {
                     sliceInfoTx = SliceInfo(handle: sliceInfo.handle, slice: sliceInfo.slice, mode: sliceInfo.mode, tx: val.tx, complete: sliceInfo.complete)
                }
                
                availableSlices["slice" + slice] = sliceInfoTx
            } else {
                if sliceInfo.tx != val.tx {
                    if updated == true {
                        sliceInfoTx = SliceInfo(handle: sliceInfoMode.handle, slice: sliceInfoMode.slice, mode: sliceInfoMode.mode, tx: sliceInfo.tx, complete: sliceInfoMode.complete)
                        
                    } else {
                        sliceInfoTx = SliceInfo(handle: sliceInfo.handle, slice: sliceInfo.slice, mode: sliceInfo.mode, tx: sliceInfo.tx, complete: sliceInfo.complete)
                    }
                    
                    availableSlices["slice" + slice] = sliceInfoTx
                }
            }
            
        } else { // add the slice
            availableSlices["slice" + slice] = sliceInfo
        }
        
    }

    
    
    // raise event and send to view controller
    // not currently using
    func UpdateRadio(radioInstance: RadioInstance) {
        
        
        // we have an update, let the GUI know
        radioDelegate?.didUpdateRadio(sender: radio)
        
    }
    
    internal func CloseAll() {
        radio.close()
        //radioFactory.close()
    }
        
    
    func printDebugMessage (_ object: Any) {
        #if DEBUG
            print(object)
        #endif
    }

} // end class
