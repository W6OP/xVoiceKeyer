
/**
 * Copyright (c) 2017 W6OP
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
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
        return scanUpToCharacters(from: set, into: &result) ? (result as String?) : nil // 2.
    }
    
    func scanUpTo(_ string: String) -> String? {
        var result: NSString?
        return self.scanUpTo(string, into: &result) ? (result as String?) : nil
    }
    
    func scanDouble() -> Double? {
        var double: Double = 0
        return scanDouble(&double) ? double : nil
    }
}

//// structure to pass data back to view controller
//struct SliceInfo {
//    let handle: String
//    let slice: String
//    let mode: String
//    let tx: String
//    let complete: Bool
//}
//
//enum TransmitMode{
//    case Invalid
//    case USB
//    case LSB
//    case SSB
//    case AM
//}

// event delegate
// implemnt in your viewcontroller to receive messages from the radio manager
//protocol RadioManagerDelegate: class {
//    func didUpdateRadio(serialNumber: String, activeSlice: String, transmitMode: TransmitMode)
//}

// begin class
internal class RadioManagerOld: NSObject {
    
    var radioManagerDelegate:RadioManagerDelegate?
    
    //var radioFactory: RadioFactory
    //var radio: Radio
    //var availableRadioInstances: [String : RadioInstance]
    var availableSlices: [String: SliceInfo]
    //
    
    // temporary
    var serialNumber: String = "Disconnected"
    
    // TODO: Make sure exception handling works
    override init() {
       
        
//        radioFactory = RadioFactory.init()
//        radio = Radio()
//        availableRadioInstances = [String : RadioInstance]()
        availableSlices = [String: SliceInfo]()
//
         super.init()
//
//        NotificationCenter.default.addObserver(self, selector: #selector(self.radioChanged), name: NSNotification.Name.init(rawValue: "K6TURadioFactory"), object: nil)
//
//        radioFactory.InitializeRadioFactory()
    }
    
    // Create a RadioFactory which starts the discovery process
    // Get the first radio's serial number to return to the view controller
    // TODO: Account for being called multiple times
    // TODO: Account for multiple radios
    internal func InitializeRadioInstances ()  -> String { // throws
        
//        var serialNumber = "Radio Not Found"
//        var numberOfRadios = 0
//        var keys: [String]
//
//        // this force casts an NSArray to Swift Array
//        //radioInstances = radioFactory.availableRadioInstances() as! [RadioInstance]
//
//        availableRadioInstances = radioFactory.discoveredRadios  //as! [RadioInstance]
//
//        if availableRadioInstances.count > 0 {
//
//            keys = Array(availableRadioInstances.keys)
//
//            for key in keys {
//                serialNumber = key
//                break
//            }
//
//            switch availableRadioInstances.count {
//            case 1:
//                numberOfRadios = 1
//            default:
//                // do something else
//                numberOfRadios = availableRadioInstances.count
//            }
//
//            radio = Radio.init(radioInstanceAndDelegate: availableRadioInstances[serialNumber], delegate: radioManagerDelegate)
//
//            printDebugMessage ("The number of radios on the network is \(numberOfRadios) -- \(serialNumber)")
//
//        } else {
//            printDebugMessage ("Their were no radios found on the network")
//        }
        
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
        
        // debug.print
        //print (payload)
        
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
            
            //sliceInfo = SliceInfo(handle: sliceHandle, slice: slice, mode: mode, tx: tx, complete: complete)
            
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
//               sliceInfoMode = SliceInfo(handle: sliceInfo.handle, slice: sliceInfo.slice, mode: val.mode, tx: sliceInfo.tx, complete: sliceInfo.complete)
               availableSlices["slice" + slice] = sliceInfoMode
               updated = true
            } else {
                if sliceInfo.mode != val.mode {
//                    sliceInfoMode = SliceInfo(handle: sliceInfo.handle, slice: sliceInfo.slice, mode: sliceInfo.mode, tx: sliceInfo.tx, complete: sliceInfo.complete)
                    availableSlices["slice" + slice] = sliceInfoMode
                    updated = true
                }
            }
           
//            if sliceInfo.tx.isEmpty {
//                if updated == true {
//                    sliceInfoTx = SliceInfo(handle: sliceInfoMode.handle, slice: sliceInfoMode.slice, mode: sliceInfoMode.mode, tx: val.tx, complete: sliceInfoMode.complete)
//                    
//                } else {
//                     sliceInfoTx = SliceInfo(handle: sliceInfo.handle, slice: sliceInfo.slice, mode: sliceInfo.mode, tx: val.tx, complete: sliceInfo.complete)
//                }
//                
//                availableSlices["slice" + slice] = sliceInfoTx
//            } else {
//                if sliceInfo.tx != val.tx {
//                    if updated == true {
//                        sliceInfoTx = SliceInfo(handle: sliceInfoMode.handle, slice: sliceInfoMode.slice, mode: sliceInfoMode.mode, tx: sliceInfo.tx, complete: sliceInfoMode.complete)
//                        
//                    } else {
//                        sliceInfoTx = SliceInfo(handle: sliceInfo.handle, slice: sliceInfo.slice, mode: sliceInfo.mode, tx: sliceInfo.tx, complete: sliceInfo.complete)
//                    }
//                    
//                    availableSlices["slice" + slice] = sliceInfoTx
//                }
//            }
            
        } else { // add the slice
            availableSlices["slice" + slice] = sliceInfo
        }
        
    }
    
    // Notification handler - this will fire when the first radio is discovered and
    // anytime a new radio is discovered, or an existing radio has a major change
    // If an error occurs in the RadioFactory.m a dictionary will be posted
    // TODO: Need to account for multiple entries into this function
    func radioChanged(notification: NSNotification){
        
        var activeSlice = "No Active Slice"
        let mode = TransmitMode.USB
        //var serialNumber: String = "Disconnected"
        
        if var info = notification.userInfo as? Dictionary<String,String> {
            // Check if value present before using it
            if let error = info["Error"] {
                serialNumber = error
                return
            }
        }
        
        // this calls RadioManager.analyzePayload
        if var info = notification.userInfo as? Dictionary<String,String> {
            // Check if value present before using it
            if let payload = info["RadioPayload"] {
                // debug.print
                //print ("Payload Data --> \(payload)")
                
                let availableSlices = self.analyzePayload(payload: payload) as [String: SliceInfo]
                
                //activeSlice = "No Active Slice"
//                for (slice, sliceInfo) in availableSlices {
//                    switch slice {
//                    case "slice0":
//                        if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
//                            activeSlice = "Slice A Active"
//                        }
//                    case "slice1":
//                        if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
//                            activeSlice = "Slice B Active"
//                        }
//                    case "slice2":
//                        if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
//                            activeSlice = "Slice C Active"
//                        }
//                    case "slice3":
//                        if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
//                            activeSlice = "Slice D Active"
//                        }
//                    case "slice4":
//                        if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
//                            activeSlice = "Slice E Active"
//                        }
//                    case "slice5":
//                        if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
//                            activeSlice = "Slice F Active"
//                        }
//                    case "slice6":
//                        if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
//                            activeSlice = "Slice G Active"
//                        }
//                    case "slice7":
//                        if sliceInfo.tx == "1" && (sliceInfo.mode == "USB" || sliceInfo.mode == "LSB" || sliceInfo.mode == "AM") {
//                            activeSlice = "Slice H Active"
//                        }
//                    default:
//                        activeSlice = "No Active Slice"
//                    }
//                    
//                }
                
                UpdateRadio(serialNumber: serialNumber, activeSlice: activeSlice, mode: mode)
                return
                
            }
        }
        
        //do {
            serialNumber = "S/N " + self.InitializeRadioInstances()
            
            UpdateRadio(serialNumber: serialNumber, activeSlice: activeSlice, mode: mode)
//        }
//        catch let error as NSError {
//            // debug.print
//            print("Error: \(error.localizedDescription)")
//        }
    }

    
    
    // raise event and send to view controller
    // not currently using
    func UpdateRadio(serialNumber: String, activeSlice: String, mode: TransmitMode) {
        
        // we have an update, let the GUI know
        radioManagerDelegate?.didUpdateRadio(serialNumber: serialNumber, activeSlice: activeSlice, transmitMode: mode)
        
    }
    
    internal func CloseAll() {
        //radio.close()
        //radioFactory.close()
    }
        
    
    func printDebugMessage (_ object: Any) {
        #if DEBUG
            print(object)
        #endif
    }

} // end class
