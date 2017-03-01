//
//  RadioInstance.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/28/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa
import Foundation

// RadioInstance:  Class to hold the specific information for each
// FlexRadio Systems 6000 series radio found by the RadioFactory via
// the radio disovery protocol.

// RENAME to RadioInstance Only when ready to use
class RadioInstanceS {

    // ipAddress:  The IP address of the radio represented by this instance.
    // NOTE:  The IP address is in decimal doted format - ie "1.1.1.1" as a string.
    var ipAddress: String = ""

    // port: The TCP port number for accessing the Ethernet control API.
    var port: NSNumber!

    // model: The model number of the radio returned as a string.  Currently
    // this is ""FLEX-6300", FLEX-6500" or "FLEX-6700".
    var model: String = ""

    // serialNum:  The serial number of the radio represented in string form.
    var serialNum: String = ""

    // name: The user configurable name of this radio instance as a string.
    var name: String = ""

//     callsign: The user configurable callsign of this radio instance as a string
    var callsign: String = ""

    // dpVersion: The version of the discovery protocol emitted by this radio
    var dpVersion: String = ""

    // version: The version of software in this radio
    var version: String = ""

    // status:  status of this radio instance
    var status: String = ""

    // lastSeen:  The date and time of which a discovery message from this radio instance was last received.
    var lastSeen: Date!

//    func initWithData(ipAddress: String, port: NSNumber, model: String, serialNum: String, name: String, callsign: String, dpVersion: String, version: String, status: String) -> RadioInstance{
//
//        self.ipAddress = ipAddress
//        self.port = port
//        self.model = model
//        self.serialNum = serialNum
//        self.name = name
//        if callsign != "" {
//            self.callsign = callsign
//        }
//        if dpVersion != "" {
//            self.dpVersion = dpVersion
//        }
//        if version != "" {
//            self.version = version
//        }
//        if status != "" {
//            self.status = status
//        }
//        self.lastSeen = Date()
//
//    return self
//
//    }
    
   
    // may be better way with Swift
    func isEqual(_ radio: RadioInstance) -> Bool {
        //let radio: RadioInstance? = (object as? RadioInstance)
        if (self.ipAddress == radio.ipAddress) && (self.port == radio.port) && (self.model == radio.model) && (self.serialNum == radio.serialNum) {
            return true
        }
        return false
    }

} // end class
