//
//  RadioFactory.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/16/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa
import Foundation


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
let MAX_NAME_LENGTH: UInt16 = 32

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
    case inuseipToken
    case inusehostToken
}

//  The converted code is limited by 2 KB.
//  Upgrade your plan to remove this limitation.

//  Converted with Swiftify v1.0.6242 - https://objectivec2swift.com/
class RadioFactory: NSObject, GCDAsyncUdpSocketDelegate {
    var tag: Int = 0
    var udpSocket: GCDAsyncUdpSocket!
    
    var availableRadioInstances: [String : RadioInstance]!
    var discoveredRadios: [String : RadioInstance]!
    var timeoutTimer: Timer!
    var parserTokens = [AnyHashable: vitaTokens]()
    
    
    override init() {
        super.init()
    }
    
   internal func InitializeRadioFactory() {
        
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        udpSocket.setPreferIPv4()
        udpSocket.setIPv6Enabled(false)
        try? udpSocket.enableBroadcast(true)
        // added W6OP 02/14/2017 so multiple clients can discover radio
        try? udpSocket.enableReusePort(true)
        
        let error: Error? = nil
    
        if !(((try? udpSocket.bind(toPort: UInt16(FLEX_DISCOVERY))) != nil)) {
            print("Error binding: \(error)")
            // can't get exceptions to work so post a message with the error // added W6OP 02/15/2017
            let errorInfo: [AnyHashable: Any]? = ["Error": error?.localizedDescription ?? ""]
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "K6TURadioFactory"), object: self, userInfo: errorInfo)
            
            // TODO: Handle this error somehow
            //return nil
            return
        }
        
        // TODO: does this just bury error? This call THROWS so I should handle that
        try? udpSocket.receiveOnce()
        
        // Initialize dictionary
        self.discoveredRadios = [String : RadioInstance]() /* capacity: 0 */
    
        // Start timeout timer
        self.timeoutTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.radioTimeoutCheck), userInfo: nil, repeats: true)
    
        print("Ready")
        
        // Initialize parser tokens
        self.parserTokens = [
            "ip" : vitaTokens.ipToken,
            "port" : vitaTokens.portToken,
            "model" : vitaTokens.modelToken,
            "serial" : vitaTokens.serialToken,
            "callsign" : vitaTokens.callsignToken,
            "nickname" : vitaTokens.nameToken,
            "discovery_protocol_version" : vitaTokens.dpVersionToken,
            "version" : vitaTokens.versionToken,
            "status" : vitaTokens.statusToken,
            "inuse_ip" : vitaTokens.inuseipToken,
            "inuse_host" : vitaTokens.inusehostToken
        ]
        
    }

    // cleanup when closing the application
    func close() {
        self.discoveredRadios.removeAll()
        udpSocket.close()
        // TODO: Is this needed
        //udpSocket.delegate = nil
        self.timeoutTimer.invalidate()
    }
    
    
    // TODO: All of this needs checking
    func radioFound(_ radio: RadioInstance) {
        // Check if in list...
        var key: String = radio.ipAddress
        var inList: RadioInstance?
        
        // TODO: need to figure out what means
        let lockQueue = DispatchQueue(label: "self")
        
        lockQueue.sync {
            //inList = self.discoveredRadios[key]!
            if let test = self.discoveredRadios[key] {
                inList = self.discoveredRadios[key]!
            }
        }
        
        if inList == nil {
            // New radio for us - simply add
            let lockQueue = DispatchQueue(label: "self")
            lockQueue.sync {
                self.discoveredRadios[key] = radio
            }
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "K6TURadioFactory"), object: self)
            //NotificationCenter.default.post(name: "K6TURadioFactory", object: self)
            print("Radio added")
        }
//        else if !(inList?.isEqual(radio))! {
        else if !(inList!.serialNum.isEqual(radio.serialNum)) {
            // The radio instance has changed... a different radio is at the same address
            // or some attribute of it has changed.
            let lockQueue = DispatchQueue(label: "self")
            lockQueue.sync {
                self.discoveredRadios.removeValue(forKey: key)
                self.discoveredRadios[key] = radio
                radio.lastSeen = Date() // added W6OP
            }
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "K6TURadioFactory"), object: self)
            //NotificationCenter.default.post(name: "K6TURadioFactory", object: self)
            print("Radio updated")
        }
        else {
            // Update the last time this radio was seen
            inList?.lastSeen = Date()
        }
    }
    
    //TODO: need to make sure this is working
    func radioTimeoutCheck(_ timer: Timer) {
        var now = Date()
        var sendNotification: Bool = false
        var keys = [String] (discoveredRadios.keys)
        
        let lockQueue = DispatchQueue(label: "self")
        
        lockQueue.sync {
            //keys = self.discoveredRadios.keys
            //for i in 0..<keys.count {
            for key in keys {
                var radio: RadioInstance = (self.discoveredRadios[key])!
                if now.timeIntervalSince(radio.lastSeen) > 5.0 {
                    // This radio has timed out - remove it
                    self.discoveredRadios.removeValue(forKey: key)
                    sendNotification = true
                    print("Radio timeout")
                }
            }
        }
        if sendNotification {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "K6TURadioFactory"), object: self)
            //NotificationCenter.default.post(name: "K6TURadioFactory", object: self)
        }
    }
    
    // MARK: availabeRadioInstances
    
    //    func availableRadioInstances() -> [Any] {
    //        let lockQueue = DispatchQueue(label: "self")
    //        lockQueue.sync {
    //            return self.discoveredRadios.allValues()
    //        }
    //    }
    
    // MARK:
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        //let MAX_NAME_LENGTH = 32
        var host: NSString?
        var hostPort: UInt16 = 0
        
        GCDAsyncUdpSocket.getHost(&host, port: &hostPort, fromAddress: address)
        
        // The typedef below is only used here - it is the format of the discovery packets
        // emitted by the 6000 series radios.  Since we could get other forms of packets or
        // there could be a corruption (unlikely), we check that the port included in the
        // packet matches what we expect.  Probably should check the model number as well
        // to make sure its one we support.
        
        // NOTA BENE: The byte ordering of the data in the payload is little endian for all
        // integer fields - loading 32 bits works without a swap, 16 bits have to be swapped.
        // Go figure...
        
//        struct _discovery {
//            var ip: UInt32
//            var port: UInt16
//            var radios: UInt16
//            var mask: UInt32
//            var model_len: UInt32
//            var model: [CChar] = [CChar](repeating: CChar(), count: Int(MAX_NAME_LENGTH))
//            var serial_len: UInt32
//            var serial: [CChar] = [CChar](repeating: CChar(), count: Int(MAX_NAME_LENGTH))
//            var name_len: UInt32
//            var name: [CChar] = [CChar](repeating: CChar(), count: Int(MAX_NAME_LENGTH))
//        }
//        
//        var discovery_type: _discovery! // = _discovery(ip: 0, port: hostPort, radios: 0,mask: 0,model_len: 0,model: [CChar()],serial_len: 0,serial: [CChar()],name_len: 0,name: [CChar()])
//        
//        var thisRadio: discovery_type? = (CChar(data.bytes) as? discovery_type)
//        
         //this is never true as far as I can tell - W6OP
//                if CFSwapInt16(thisRadio?.port) == FLEX_CONNECT {
//                    var cPort = Int(CFSwapInt16(thisRadio?.port))
//                    var model = String(utf8String: thisRadio?.model)
//                    var serialNum = String(utf8String: thisRadio?.serial)
//                    var name = String(utf8String: thisRadio?.name)
//                    var newRadio = RadioInstance(data: host, port: cPort, model: model, serialNum: serialNum, name: name, callsign: nil, dpVersion: nil, version: nil, status: nil)
//                    self.radioFound(newRadio)
//                }
//                else {
        // Could be a VITA encoded discovery packet - sent on the same UDP Port
        let vita: VITA = VITA(packet: data)
        let newRadio = RadioInstance()
        if vita.classIdPresent && vita.packetClassCode == UInt16(VS_Discovery) {
            
            // Vita encoded discovery packet - crack the payload and parse
            // Payload is a series of strings separated by ' '
            // this needs to be checked to make sure it works correctly, added describing:
            //let ds = String(describing: (bytes: vita.payload, length: vita.payloadLength, encoding: String.Encoding.ascii))
            //http://stackoverflow.com/questions/35620543/swift-converting-byte-array-into-string
            var ds = NSString(bytes: vita.payload, length: Int(vita.payloadLength),encoding: String.Encoding.ascii.rawValue)
            //NSString *ds = [[NSString alloc] initWithBytes:vita.payload length:vita.payloadLength encoding:NSASCIIStringEncoding];
            let fields: [String] = ds!.components(separatedBy: " ")
            
            for p: String in fields {
                var kv: [Any] = p.components(separatedBy: "=")
                let k: String = kv[0] as! String
                let v: String = kv[1] as! String
                
                
                //let token2: String = (self.parserTokens[k] as! NSString) as String
                //let score = Int(self.parserTokens[k] as? String ?? "") ?? 0
                
                //let token: Int = (self.parserTokens[k] as! NSString).integerValue
                let token: vitaTokens = self.parserTokens[k]!
                
                switch token {
                    case vitaTokens.ipToken :
                        newRadio.ipAddress = v
                    case vitaTokens.portToken :
                        newRadio.port = Int((v as NSString).integerValue) as NSNumber!
                    case vitaTokens.modelToken :
                        newRadio.model = v
                    case vitaTokens.serialToken :
                        newRadio.serialNum = v
                    case vitaTokens.nameToken :
                        newRadio.name = v
                    case vitaTokens.callsignToken :
                        newRadio.callsign = v
                    case vitaTokens.dpVersionToken :
                        newRadio.dpVersion = v
                    case vitaTokens.versionToken :
                        newRadio.version = v
                    case vitaTokens.statusToken :
                        newRadio.status = v
                    case vitaTokens.inuseipToken:
                        newRadio.status = v
                    case vitaTokens.inusehostToken:
                        newRadio.status = v
                    default:
                        break
                    }
                
                    newRadio.lastSeen = Date()
                }
                self.radioFound(newRadio)
            }
        //}
        
        var error: Error? = nil
        // need to handle error probably
        try? udpSocket.receiveOnce()
    }
} // end class

