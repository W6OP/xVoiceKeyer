//
//  RadioManager.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/12/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa
import Foundation

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

extension Array  {
    var indexedDictionary: [Int: Element] {
        var result: [Int: Element] = [:]
        enumerated().forEach({ result[$0.offset] = $0.element })
        return result
    }
}

struct SliceInfo {
    // the fields' values once extracted placed in the properties
    let slice: String
    let mode: String
    let tx: String
}

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
    internal func InitializeRadioInstances () throws -> String {
        
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
            
            //InitializeRadio(radioInstance: radioInstances[0])
            radio = Radio.init(radioInstanceAndDelegate: radioInstances[0], delegate: radioDelegate)
            
            printDebugMessage ("The number of radios on the network is \(numberOfRadios) -- \(serialNumber)")
            
        } else {
            printDebugMessage ("Their were no radios found on the network")
        }
        
        return serialNumber
    }
    
    
    //typealias Fields = (slice: String, mode: String, tx: String, handle: String)
    var sliceInfo = (handle: "", slice: "", mode: "", tx: "", complete: false)
    // need to get all the slices
    // find one that has tx=1
    // check if the mode = USB or LSB or AM
    // should I return a string or send in event? - probably return a string
    internal func analyzePayload(payload: String) -> (handle: String, slice: String, mode: String, tx: String, complete: Bool){
        
        //var (slice, mode, tx, handle) = ("", "", "", "")
        
        var sliceHandle: String
        var count = 0
        
        // Create a CharacterSet of delimiters.
        let separators = CharacterSet(charactersIn: "| =")
        // Split based on characters.
        let parts = payload.components(separatedBy: separators)

        
        let scanner = Scanner(string: payload)
        //scanner.charactersToBeSkipped = nil //CharacterSet(charactersIn: "|")
        
        var temp = scanner.scanUpTo("|")! // gets the status handle
        sliceHandle = temp
        
        temp = scanner.scanUpTo("slice ") ?? "" // this gets us the "|"
        temp = scanner.scanUpTo(" ") ?? "" // gets us "slice"
        
        if temp == "slice" {
            if sliceHandle != sliceInfo.handle { // this may never happen
                sliceInfo = (handle: "", slice: "", mode: "", tx: "", complete: false)
            }
            
            sliceInfo.handle = sliceHandle
            for (index, items) in parts.enumerated() {
                if items == "slice" {
                    sliceInfo.slice = parts[index + 1]
                    count += 1
                }
                
                if items == "mode" {
                    sliceInfo.mode = parts[index + 1]
                    count += 1
                }
                
                if items == "tx" {
                    sliceInfo.tx = parts[index + 1]
                    count += 1
                }
                
                if items == "active" {
                    sliceInfo.tx = parts[index + 1]
                    count += 1
                }
            }
        }
        
        if count >= 3 {
            sliceInfo.complete = true
        }
        
        return sliceInfo
    }
    
//    func parseSlice (parts: [String]) -> (slice: "0", mode: "", tx: "0");){
//
//        var sliceInfo = (slice: "0", mode: "", tx: "0")
//        
//        for (index, items) in parts.enumerated() {
//            if items == "mode" {
//                sliceInfo.mode = parts[index + 1]
//    
//            }
//            
//            if items == "tx" {
//                sliceInfo.tx = parts[index + 1]
//                
//            }
//        }
//        
//        return sliceInfo
//    }
    
    

    
    
    // raise event and send to view controller
    func UpdateRadio(radioInstance: RadioInstance) {
        
        
        // we have an update, let the GUI know
        radioDelegate?.didUpdateRadio(sender: radio)
        
    }
    
    internal func CloseAll() {
        radio.close()
        radioFactory.close()
    }
        
    
    func printDebugMessage (_ object: Any) {
        #if DEBUG
            print(object)
        #endif
    }

} // end class
