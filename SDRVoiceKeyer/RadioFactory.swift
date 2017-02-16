//
//  RadioFactory.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/16/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Foundation
import Cocoa

//  Converted with Swiftify v1.0.6242 - https://objectivec2swift.com/
//
//  K6TURadioFactory.m
//
//  Created by STU PHILLIPS on 8/2/13.
//  Copyright (c) 2013 STU PHILLIPS. All rights reserved.
//
// NOTE: THe license under which this software will be generally released
// is still under consideration.  For now, use of this software requires
// the specific approval of Stu Phillips, K6TU.








let FLEX_DISCOVERY = 4992
let FLEX_CONNECT = 4992
// MARK: Radio Instance
// Enum definition for VITA formed discovery message parser
enum vitaTokens : Int {
    case nullToken = 0
    case ipToken
    case portToken
    case modelToken
    case serialToken
    case callsignToken
    case nameToken
    case dpVersionToken
    case versionToken
    case statusToken
}

class RadioInstance {
    
    var ipAddress: String = ""
    var port: NSNumber = 4492
    var model: String = ""
    var serialNum: String = ""
    var name: String = ""
    var callsign: String = ""
    var dpVersion: String = ""
    var version: String = ""
    var status: String = ""
    var lastSeen: Date
    
    
    

    
     init(data ipAddress: String, port: NSNumber, model: String, serialNum: String, name: String, callsign: String, dpVersion: String, version: String, status: String) {
        //super.init()
        self.ipAddress = ipAddress
        self.port = port
        self.model = model
        self.serialNum = serialNum
        self.name = name
        if callsign != "" {
            self.callsign = callsign
        }
        if dpVersion != "" {
            self.dpVersion = dpVersion
        }
        if version != "" {
            self.version = version
        }
        if status != "" {
            self.status = status
        }
        self.lastSeen = Date()
    }
    
    func isEqual(_ object: Any) -> Bool {
        let radio: RadioInstance? = (object as? RadioInstance)
        if (self.ipAddress == radio?.ipAddress) && (self.port == radio?.port) && (self.model == radio?.model) && (self.serialNum == radio?.serialNum) {
            return true
        }
        return false
    }
}

//  The converted code is limited by 2 KB.
//  Upgrade your plan to remove this limitation.

//  Converted with Swiftify v1.0.6242 - https://objectivec2swift.com/
class RadioFactory {
    var tag: Int = 0
    var udpSocket: GCDAsyncUdpSocket!
    
    
    var discoveredRadios = [AnyHashable: Any]()
    var timeoutTimer: Timer!
    var parserTokens = [AnyHashable: Any]()
    
    func radioFound(_ radio: RadioInstance) {
        // Check if in list...
        var key: String = radio.ipAddress
        var inList: RadioInstance?
        let lockQueue = DispatchQueue(label: "self")
        lockQueue.sync {
            inList = self.discoveredRadios[key] as! RadioInstance?
        }
        if inList == nil {
            // New radio for us - simply add
            let lockQueue = DispatchQueue(label: "self")
            lockQueue.sync {
                self.discoveredRadios[key] = radio
            }
            // FIX
            //NotificationCenter.default.post(name: "K6TURadioFactory", object: self)
            print("Radio added")
        }
        else if !(inList?.isEqual(radio))! {
            // The radio instance has changed... a different radio is at the same address
            // or some attribute of it has changed.
            let lockQueue = DispatchQueue(label: "self")
            lockQueue.sync {
                self.discoveredRadios.removeValue(forKey: key)
                self.discoveredRadios[key] = radio
            }
            // FIX
            //NotificationCenter.default.post(name: "K6TURadioFactory", object: self)
            print("Radio updated")
        }
        else {
            // Update the last time this radio was seen
            inList?.lastSeen = Date()
        }
        
    }
    
    func radioTimeoutCheck(_ timer: Timer) {
        var now = Date()
        var sendNotification: Bool = false
        var keys: [Any]
        #if DEBUG
            // [[NSNotificationCenter defaultCenter] postNotificationName:@"K6TURadioFactory" object:self];
            // return;   // Comment this out to renable timeout
        #endif
        let lockQueue = DispatchQueue(label: "self")
        lockQueue.sync {
            keys = self.discoveredRadios.keys
            for i in 0..<keys.count {
                var radio: RadioInstance? = (self.discoveredRadios[keys[i]] as? String)
                if (radio != nil) && now.timeIntervalSince((radio?.lastSeen)!) > 5.0 {
                    // This radio has timed out - remove it
                    self.discoveredRadios.removeValue(forKey: keys[i] as! AnyHashable)
                    sendNotification = true
                    print("Radio timeout")
                }
            }
        }
        if sendNotification {
            // FIX
            //NotificationCenter.default.post(name: "K6TURadioFactory", object: self)
        }
    }
    // MARK: availabeRadioInstances
    
    func availableRadioInstances() -> [Any] {
        let lockQueue = DispatchQueue(label: "self")
        lockQueue.sync {
            return self.discoveredRadios.values
        }
    }
    // MARK:
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any) {
        let MAX_NAME_LENGTH = 32
// The typedef below is only used here - it is the format of the discovery packets
// emitted by the 6000 series radios.  Since we could get other forms of packets or
// there could be a corruption (unlikely), we check that the port included in the
// packet matches what we expect.  Probably should check the model number as well
// to make sure its one we support.
        // NOTA BENE: The byte ordering of the data in the payload is little endian for all
        // integer fields - loading 32 bits works without a swap, 16 bits have to be swapped.
        // Go figure...
        var host = ""
        var hostPort: UInt16 = 0
        GCDAsyncUdpSocket.getHost(host, port: hostPort, fromAddress: address)
        var discovery_type = struct_discovery{UInt32ip;UInt16port;UInt16radios;UInt32mask;UInt32model_len;charmodel[MAX_NAME_LENGTH];UInt32serial_len;charserial[MAX_NAME_LENGTH];UInt32name_len;charname[MAX_NAME_LENGTH];}()
        var thisRadio = ((data.bytes as! CChar) as! discovery_type)
        if CFSwapInt16(thisRadio.port) == FLEX_CONNECT {
            // Passes the first test...  FLEX-DISCOVERY protocol and FLEX_CONNECT as
            // the port...
            var cPort = Int(CFSwapInt16(thisRadio.port))
            var model = NSString.stringWithUTF8String(thisRadio.model)
            var serialNum = NSString.stringWithUTF8String(thisRadio.serial)
            var name = NSString.stringWithUTF8String(thisRadio.name)
            var newRadio = RadioInstance(data: host, port: cPort, model: model, serialNum: serialNum, name: name, callsign: nil, dpVersion: nil, version: nil, status: nil)
            self.radioFound(newRadio)
        }
        else {
            // Could be a VITA encoded discovery packet - sent on the same UDP Port
            var vita = VITA(packet: data)
            var newRadio = RadioInstance()
            if vita.classIdPresent && vita.packetClassCode == VS_Discovery {
                // Vita encoded discovery packet - crack the payload and parse
                // Payload is a series of strings separated by ' '
                var ds = String!(bytes: vita.payload, length: vita.payloadLength, encoding: NSASCIIStringEncoding)
                var fields = ds.componentsSeparatedByString(" ")
                for p: String in fields {
                    var kv = p.componentsSeparatedByString("=")
                    var k = kv[0]
                    var v = kv[1]
                    var token = Int((self.parserTokens[k] as NSString ?? "0").intValue)
                    switch token {
                    case ipToken:
                        newRadio.ipAddress = v
                    case portToken:
                        newRadio.port = Int(Int((v as NSString ?? "0").intValue))
                    case modelToken:
                        newRadio.model = v
                    case serialToken:
                        newRadio.serialNum = v
                    case nameToken:
                        newRadio.name = v
                    case callsignToken:
                        newRadio.callsign = v
                    case dpVersionToken:
                        newRadio.dpVersion = v
                    case versionToken:
                        newRadio.version = v
                    case statusToken:
                        newRadio.status = v
                    default:
                        break
                    }
                }
                self.radioFound(newRadio)

                // Post a new read
                //NSError *error = nil;
                
                //[udpSocket receiveOnce:&error];
}
