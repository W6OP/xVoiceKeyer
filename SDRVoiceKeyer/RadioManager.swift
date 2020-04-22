/**
 * Copyright (c) 2019 Peter Bourget W6OP
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

/*
 RadioManager.swift
 SDRVoiceKeyer
 
 Created by Peter Bourget on 7/11/17.
 Copyright © 2019 Peter Bourget W6OP. All rights reserved.
 
 Description: This is a wrapper for the xLib6000 framework written by Doug Adams K3TZR
 The purpose is to simplify the interface into the API and allow the GUI to function
 without a reference to the API or even knowledge of the API.
 */

import Foundation
import xLib6000
import Repeat
import os

// MARK: Extensions ------------------------------------------------------------------------------------------------

/** breaks an array into chunks of a specific size, the last chunk may be smaller than the specified size
 this is used to split the audio buffer into 128 samples at a time to send to the vita parser
 via the rate timer
 */
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[idx1..<idx2])
    }
}

// MARK: Helper Functions ------------------------------------------------------------------------------------------------

/** utility functions to run a UI or background thread
 // USAGE:
 BG() {
 everything in here will execute in the background
 }
 https://www.electrollama.net/blog/2017/1/6/updating-ui-from-background-threads-simple-threading-in-swift-3-for-ios
 */
func BG(_ block: @escaping ()->Void) {
    DispatchQueue.global(qos: .background).async(execute: block)
}

/**  USAGE:
 UI() {
 everything in here will execute on the main thread
 }
 */
func UI(_ block: @escaping ()->Void) {
    DispatchQueue.main.async(execute: block)
}

// MARK: Event Delegates ------------------------------------------------------------------------------------------------

/**
 Implement in your viewcontroller to receive messages from the radio manager
 */
protocol RadioManagerDelegate: class {
    // radio and gui clients were discovered - notify GUI
    func didDiscoverGUIClients(discoveredGUIClients: [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: String)], isGuiClientUpdate: Bool)
    
    func didAddGUIClients(discoveredGUIClients: [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: String)], isGuiClientUpdate: Bool)
    
    func didUpdateGUIClients(discoveredGUIClients: [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: String)], isGuiClientUpdate: Bool)
    
    func didRemoveGUIClients(discoveredGUIClients: [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: String)], isGuiClientUpdate: Bool)
    
    func didAddSlice(slice: [(sliceLetter: UInt16, voiceMode: Bool, txEnabled: Bool, sliceHandle: UInt32)])
    
    func didRemoveSlice(sliceHandle: UInt32)
    
    // notify the GUI the tcp connection to the radio was closed
    func didDisconnectFromRadio()
    // send message to view controller
    //func radioMessageReceived(messageKey: RadioManagerMessage)
    // update slice, mode or frequency
    func updateView(components: (slice: String, mode: String, frequency: String, station: String))
}

// MARK: - Enums ------------------------------------------------------------------------------------------------

/**
 Unify message nouns going to the view controller
 */
//public enum RadioManagerMessage : String {
//    case VALIDMODE = "Valid Mode"
//    case INVALIDMODE = "Invalid Mode"
//    case TXSLICEAVAILABLE = "TX Slice Available"
//    case NOTXSLICE = "No TX Slice"
//}

public enum SliceMode : String {
    case usb = "USB"
    case lsb = "LSB"
    case fm = "FM"
}


// MARK: - Class Definition ------------------------------------------------------------------------------------------------

/**
 Wrapper class for the FlexAPI Library xLib6000 written for the Mac by Doug Adams K3TZR.
 This class will isolate other apps from the API implemenation allowing reuse by multiple
 programs.
 */
class RadioManager: NSObject, ApiDelegate {
    
    func addReplyHandler(_ sequenceNumber: SequenceNumber, replyTuple: ReplyTuple) {
        os_log("addReplyHandler added.", log: RadioManager.model_log, type: .info)
    }
    
    func defaultReplyHandler(_ command: String, sequenceNumber: SequenceNumber, responseValue: String, reply: String) {
        os_log("defaultReplyHandler added.", log: RadioManager.model_log, type: .info)
    }
    
    // KVO
    var _observationList: Dictionary = [ObjectId: [NSKeyValueObservation]]()
    
    // setup logging for the RadioManager
    static let model_log = OSLog(subsystem: "com.w6op.RadioManager-Swift", category: "xVoiceKeyer")
    
    // delegate to pass messages back to viewcontroller
    weak var radioManagerDelegate:RadioManagerDelegate?
    
    // MARK: - Internal properties ----------------------------------------------------------------------------
    
    // view of discovered radios - passed to the view controller to abstract it from the radio
    var guiClientView = [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: String)]()
    
    // local dictionary of slices
    var availableSlices = [UInt32: Slice]()
    // view of available slices for the view controller
    //var sliceView = [(sliceLetter: UInt16, mode: SliceMode?, txEnabled: Bool, sliceHandle: UInt32)]()
    
    // MARK: - Internal Radio properties ----------------------------------------------------------------------------
    
    // Radio currently running
    var activeRadio: DiscoveryPacket?
    var activeStation: String
    var activeStationHandle: String
    
    // this starts the discovery process - Api to the Radio
    var api = Api.sharedInstance
    let discovery = Discovery.sharedInstance
    
    // MARK: - Private properties ----------------------------------------------------------------------------
    
    var audiomanager: AudioManager!
    
    // Notification observers
    var notifications = [NSObjectProtocol]()
    
    //let log = Logger.sharedInstance //(NSApp.delegate as! AppDelegate)
    let clientProgram = "SDRVoiceKeyer"
    var txAudioStream: DaxTxAudioStream!
    var txAudioStreamId: StreamId 
    var txAudioStreamRequested = false
    var audioBuffer = [Float]()
    var audioStreamTimer :Repeater? // timer to meter audio chunks to radio at 24khz sample rate
    var xmitGain = 35
    
    // MARK: - RadioManager Initialization ----------------------------------------------------------------------------
    
    /**
     Initialize the class, create the RadioFactory, add notification listeners
     */
    override init() {
        
        audiomanager = AudioManager()
        activeStation = ""
        activeStationHandle = ""
        txAudioStreamId = StreamId("0")
        
        super.init()
        
        // add notification subscriptions
        addNotificationListeners()
        
        api.delegate = self
    }
    
    // MARK: - Open and Close Radio Methods - Required by xLib6000 - Not Used ----------------------------------------------------------------------------
    
    func sentMessage(_ text: String) {
        _ = 1 // unused in xVoiceKeyer
    }
    
    func receivedMessage(_ text: String) {
        // get all except the first character // unused in xVoiceKeyer
        //_ = String(text.dropFirst())
        os_log("Message received.", log: RadioManager.model_log, type: .info)
        
    }
    
    //    func addReplyHandler(_ sequenceId: SequenceId, replyTuple: ReplyTuple) {
    //        // unused in xVoiceKeyer
    //        //replyHandlers[sequenceId] = replyTuple
    //        os_log("addReplyHandler added.", log: RadioManager.model_log, type: .info)
    //    }
    
    func defaultReplyHandler(_ command: String, seqNum: String, responseValue: String, reply: String) {
        // unused in xVoiceKeyer
        os_log("defaultReplyHandler called.", log: RadioManager.model_log, type: .info)
    }
    
    func vitaParser(_ vitaPacket: Vita) {
        // unused in xVoiceKeyer
        os_log("Vita parser added.", log: RadioManager.model_log, type: .info)
    }
    
    // MARK: - Notification Methods ----------------------------------------------------------------------------
    
    /**
     Add subscriptions to Notifications from the xLib6000 API
     */
    func addNotificationListeners() {
        let nc = NotificationCenter.default
        
        // Available Radios changed
        nc.addObserver(forName:Notification.Name(rawValue:"discoveredRadios"),
                       object:nil, queue:nil,
                       using:discoveryPacketsReceived)
        
        nc.addObserver(forName:Notification.Name(rawValue:"guiClientHasBeenAdded"),
                       object:nil, queue:nil,
                       using:clientsAdded)
        
        nc.addObserver(forName:Notification.Name(rawValue:"guiClientHasBeenUpdated"),
                       object:nil, queue:nil,
                       using:clientsUpdated)
        
        nc.addObserver(forName:Notification.Name(rawValue:"guiClientHasBeenRemoved"),
                       object:nil, queue:nil,
                       using:clientsRemoved)
        
        
        nc.addObserver(forName: Notification.Name(rawValue: "sliceHasBeenAdded"), object:nil, queue:nil,
                       using:sliceHasBeenAdded)
        
        nc.addObserver(forName: Notification.Name(rawValue: "sliceWillBeRemoved"), object:nil, queue:nil,
                       using:sliceWillBeRemoved)
    }
    
    // MARK: - Implementation ----------------------------------------------------------------------------
    
    /**
     Exposed function for the GUI to indicate which radio to connect to.
     - parameters:
     - serialNumber: a string representing the serial number of the radio to connect
     */
    func connectToRadio(serialNumber: String, clientStation: String, clientId: String, doConnect: Bool) -> Bool {
        
        os_log("Connect to the Radio.", log: RadioManager.model_log, type: .info)
        
        // allow time to hear the UDP broadcasts
        usleep(1500)
        
        if (doConnect){
            for (_, foundRadio) in discovery.discoveredRadios.enumerated() where foundRadio.serialNumber == serialNumber {
                activeRadio = foundRadio
                
                if api.connect(activeRadio!, programName: "SDRVoiceKeyer", clientId: nil, isGui: false) {
                    os_log("Connected to the Radio.", log: RadioManager.model_log, type: .info)
                    return true
                }
            }
        }
        return false
    }
    
    /**
     Bind to a specific station so we get their messages and updates
     */
    func bindToStation(clientId: String) -> Bool {
        
        if api.radio?.boundClientId != clientId {
            api.radio?.boundClientId = clientId
            
            if let view = self.guiClientView.firstIndex(where: {$0.clientId == clientId}) {
                activeStation = self.guiClientView[view].stationName
                activeStationHandle = self.guiClientView[view].handle
                os_log("Bound to the Client.", log: RadioManager.model_log, type: .info)
                return true
            }
        }
        
        return false
    }
    
    // cleanup so we can bind with another station
    func cleanUp() {
        api.radio?.boundClientId = nil
    }
    
    /**
     Stop the active radio. Remove observations of Radio properties.
     Perform an orderly close of the Radio resources.
     */
    func closeRadio() {
        // TODO:
        //api.disconnect()
        activeRadio = nil
    }
    
    // MARK: - Radio Methods ----------------------------------------------------------------------------
    
    /** 
     Notification that one or more radios were discovered.
     - parameters:
     - note: a Notification instance
     */
    func discoveryPacketsReceived(_ note: Notification) {
        // receive the updated list of Radios
        let discoveredRadios = (note.object as! [DiscoveryPacket])
        
        self.guiClientView = [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String, handle: String)]()
        
        // just collect the radio's gui clients
        for radio in discoveredRadios {
            for client in radio.guiClients {
                self.guiClientView.append((radio.model, radio.nickname, client.station, "No", radio.serialNumber, client.clientId ?? "", String(client.handle)))
            }
        }
        
        if guiClientView.count > 0 {
            // let the view controller know a radio was discovered
            // this is the first thing to occur after xLib adds a radio
            UI() {
                os_log("Radios updated.", log: RadioManager.model_log, type: .info)
                self.radioManagerDelegate?.didDiscoverGUIClients(discoveredGUIClients: self.guiClientView, isGuiClientUpdate: false)
            }
        }
    }
    
    /**
     When another GUI client appears we receive a notification.
     Let the view controller know there has been an update.
     */
    func clientsAdded(_ note: Notification) {
        
        if let station = note.object as? String {
            if let view = self.guiClientView.firstIndex(where: {$0.stationName == station}) {
                guiClientView[view].stationName = station
            }
            
            if guiClientView.count > 0 {
                // let the view controller know a radio was discovered or updated
                UI() {
                    os_log("GUI clients have been added.", log: RadioManager.model_log, type: .info)
                    self.radioManagerDelegate?.didAddGUIClients(discoveredGUIClients: self.guiClientView, isGuiClientUpdate: true)
                }
            }
        }
    }
    
    // Do bind after this
    func clientsUpdated(_ note: Notification) {
        
        if let station = note.object as? String {
            let clientId = getClientId(station: station)
            
            if let view = self.guiClientView.firstIndex(where: {$0.stationName == station}) {
                guiClientView[view].clientId = clientId
            }
            
            if guiClientView.count > 0 {
                // let the view controller know a radio was discovered or updated
                UI() {
                    os_log("GUI clients have been updated.", log: RadioManager.model_log, type: .info)
                    self.radioManagerDelegate?.didUpdateGUIClients(discoveredGUIClients: self.guiClientView, isGuiClientUpdate: true)
                }
            }
        }
    }
    
    /**
     Get the client id for a station name.
     - parameter station: String
     */
    func getClientId(station: String) -> String {
        
        guard let clientId = activeRadio?.guiClients[0].clientId else { return "" }
        
        return clientId
    }
    
    // get handle - TODO: this needs work
    func clientsRemoved(_ note: Notification) {
        
//        guard let handle = (note.object as? UInt64)else {
//            return
//        }
//
//        if self.guiClientView.first(where: { $0.handle == String(handle) }) != nil {
//            self.guiClientView = self.guiClientView.filter {$0.handle != String(handle)}
//        }
        
        if let station = note.object as? String {
            if let view = self.guiClientView.firstIndex(where: {$0.stationName == station}) {
                guiClientView[view].stationName = station
            }
            
            if guiClientView.count > 0 {
                // let the view controller know a radio was removed
                UI() {
                    os_log("GUI clients have been removed.", log: RadioManager.model_log, type: .info)
                    self.radioManagerDelegate?.didRemoveGUIClients(discoveredGUIClients: self.guiClientView, isGuiClientUpdate: true)
                }
            }
        }
    }
    
    
    // MARK: - Slice handling
    
    /**
     Notification that one or more slices were added.
     The slice that is added becomes the active slice.
     - parameters:
     - note: a Notification instance
     */
    func sliceHasBeenAdded(_ note: Notification){
        
        let slice: xLib6000.Slice = (note.object as! xLib6000.Slice)
        var isValidMode = false
        
        var sliceView = [(sliceLetter: UInt16, voiceMode: Bool, txEnabled: Bool, sliceHandle: UInt32)]()
        
        switch SliceMode(rawValue: slice.mode) {
        case .lsb, .usb, .fm:
            isValidMode = true
        default:
            isValidMode = false
        }
        
        sliceView.append((sliceLetter: slice.id, voiceMode: isValidMode, txEnabled: slice.txEnabled, sliceHandle: slice.clientHandle))
        
        // now notify the view controller
         UI() {
            self.radioManagerDelegate?.didAddSlice(slice: sliceView)
        }
        
        os_log("Slice has been addded.", log: RadioManager.model_log, type: .info)
    }
    
    /**
     Notification that one or more slices were removed. Iterate through collection
     and remove the slice from the array of available slices.
     - parameters:
     - note: a Notification instance
     */
    func sliceWillBeRemoved(_ note: Notification){
        
        let slice: xLib6000.Slice = (note.object as! xLib6000.Slice)
    
         os_log("Slice has been removed.", log: RadioManager.model_log, type: .info)

         UI() {
            self.radioManagerDelegate?.didRemoveSlice(sliceHandle: slice.clientHandle)
        }

        //checkSliceStatus ()
    }
    
    /**
     Observer handler to update the slice information for the labels on the GUI
     when a new slice is added.
     - parameters:
     - slice:
     */
    func updateSliceStatus(_ slice: xLib6000.Slice, _ change: Any){
        
        #if DEBUG
        print ("Slice \(slice.sliceLetter ?? "Unknown") has been updated.")
        print ("Slice \(activeStationHandle) :  \(String(slice.clientHandle)) has been updated.")
        #endif
        //os_log("Slice has been updated.", log: RadioManager.model_log, type: .info)
        
        // we only care if txEnabled has changed and only care about that slice
        if slice.txEnabled{
            #if DEBUG
            print ("Slice \(slice.sliceLetter ?? "Unknown") is txEnabled.")
            #endif
            
//            UI() {
//                self.radioManagerDelegate?.updateView(components: self.findTxEnabledSlice(clientHandle: slice.clientHandle))
//                self.radioManagerDelegate?.radioMessageReceived(messageKey: RadioManagerMessage.TXSLICEAVAILABLE)
//            }
//            // now check for a valid mode
//            if checkForValidMode() {
//                print("Valid Mode")
//                UI() {
//                    self.radioManagerDelegate?.radioMessageReceived(messageKey: RadioManagerMessage.VALIDMODE)
//                }
//            } else {
//                print("Invalid Mode")
//                UI() {
//                    self.radioManagerDelegate?.radioMessageReceived(messageKey: RadioManagerMessage.INVALIDMODE)
//                }
//            }
            
            return
        } else {
            //checkSliceStatus ()
        }
    }
    
    
    /**
     Now see if any slices are txUpdated - this is necessary to update GUI
     when no slices are txEnabled and then one is enabled or disabled again.
     */
//    func checkSliceStatus () {
//
//        if api.radio?.slices.count == 0 {
//            UI() {
//                self.radioManagerDelegate?.radioMessageReceived(messageKey: RadioManagerMessage.NOTXSLICE)
//            }
//        } else {
//            let results = api.radio?.slices.filter { $0.value.txEnabled == true }
//            if results?.count == 0 {
//                UI() {
//                    self.radioManagerDelegate?.radioMessageReceived(messageKey: RadioManagerMessage.NOTXSLICE)
//                }
//            }
//        }
//    }
    
    /**
     Find the slice configured to transmit.
     - parameters:
     - components: tuple with slice information for the GUI
     */
    func findTxEnabledSlice(clientHandle: UInt32) -> ((slice: String, mode: String, frequency: String, station: String)) {
        
        var components = (slice: "No TX", mode: "", frequency: "", station: "")
        
        for (_, slice) in (api.radio?.slices)! {
            if slice.txEnabled && slice.clientHandle == clientHandle {
                components.mode = slice.mode
                components.frequency = convertFrequencyToDecimalString(frequency: slice.frequency)
                components.slice = slice.sliceLetter!
                components.station = activeStation
            }
        }
        
        return components
    }
    
    // MARK: - Utlity Functions for Slices
    
    /**
     Convert the frequency (10136000) to a string with a decimal place (10136.000)
     Use an extension to String to format frequency correctly
     */
    func convertFrequencyToDecimalString (frequency: Int) -> String {
        
        // 160M = 7 digits - 80M - 40
        // 30 M = 8
        let frequencyString = String(frequency)
        
        switch frequencyString.count {
        case 7:
            let start = frequencyString[0..<1]
            let end = frequencyString[1..<4]
            let extend = frequencyString[4..<6]
            //print ("\(start).\(end)")
            return ("\(start).\(end).\(extend)")
        default:
            let start = frequencyString[0..<2]
            let end = frequencyString[2..<5]
            let extend = frequencyString[5..<7]
            //print ("\(start).\(end).\(extend)")
            return ("\(start).\(end).\(extend)")
        }
    }
    
    /**
     Convert the slice number to a slice leter
     */
    //    private func convertSliceNumberToLetter (sliceNumber: String) -> String {
    //
    //        switch sliceNumber {
    //        case "0":
    //            return "A"
    //        case "1":
    //            return "B"
    //        case "2":
    //            return "C"
    //        case "3":
    //            return "D"
    //        case "4":
    //            return "E"
    //        case "5":
    //            return "F"
    //        case "6":
    //            return "G"
    //        case "7":
    //            return "H"
    //        default:
    //            return "??"
    //        }
    //    }
    
    
    // MARK: Transmit methods ----------------------------------------------------------------------------
    
    /**
     Prepare to key the selected Radio. Create the audio stream to be sent.
     
     - parameters:
     - doTransmit: true create and send an audio stream, false will unkey MOX
     - buffer: an array of floats representing an audio sample in PCM format
     */
    func keyRadio(doTransmit: Bool, buffer: [Float]? = nil, xmitGain: Int) {
        
        self.xmitGain = xmitGain
        
        if doTransmit  {
            self.audioBuffer = buffer!
            if txAudioStreamRequested == false {
                txAudioStreamRequested = true
                api.radio!.requestDaxTxAudioStream(callback: updateTxStreamId)
            }
            else{
                if clearToTransmit(){
                    DispatchQueue.global(qos: .userInteractive).async {
                        self.sendTxAudioStream()
                    }
                }
            }
        } else{
            self.audioStreamTimer = nil
            api.radio?.mox = false
        }
    }
    
    /**
     Callback for the TX Stream Request command.
     
     - Parameters:
     - command:        the original command
     - seqNum:         the Sequence Number of the original command
     - responseValue:  the response value
     - reply:          the reply
     */
    // _ command: String, sequenceNumber: SequenceNumber, responseValue: String, reply: String
    func updateTxStreamId(_ command: String, sequenceNumber: UInt, responseValue: String, reply: String) {
        
        guard responseValue == "0" else {
            // Anything other than 0 is an error, log it and ignore the Reply
            os_log("Error requesting tx audio stream ID.", log: RadioManager.model_log, type: .error)
            // TODO: notify GUI
            return
        }
        
        // check if we have a stream requested
        if !self.txAudioStreamRequested {
            os_log("Unsolicited audio stream received.", log: RadioManager.model_log, type: .error)
            return
        }
        
        // can be optional
        if let streamId = reply.streamId {
            
            self.txAudioStream = api.radio?.daxTxAudioStreams[streamId]
            
            if clearToTransmit(){
                DispatchQueue.global(qos: .userInteractive).async {
                    self.sendTxAudioStream()
                }
            }
        }
    }
    
    /**
     Check to see if there is any reason we can't transmit.
     */
    func clearToTransmit() -> Bool {
        
        // see if the GUI has gone away and cleanup if it has
        if api.radio == nil {
            UI() {
                self.radioManagerDelegate?.didDisconnectFromRadio()
            }
            
            _observationList.removeAll()
            activeRadio = nil
            self.txAudioStream = nil
            
            return false
        }
        
        
//        if (api.radio?.slices.count)! > 0 {
//            return checkForValidMode ()
//        } else {
//            // can't do anything without an active slice
//            UI() {
//                self.radioManagerDelegate?.radioMessageReceived(messageKey: RadioManagerMessage.NOTXSLICE)
//            }
            return false
//        }
    }
    
    /**
     Check to see if a valid mode for phone is selected.
     */
    func checkForValidMode() -> Bool {
        
        for (_, slice) in (api.radio?.slices)! {
            if slice.txEnabled {
                let modeEnum = Slice.Mode(rawValue: slice.mode)!
                switch (modeEnum){
                case .USB, .LSB, .AM, .FM:
                    return true
                default:
                    return false
                }
            }
        }
        
        return false
    }
    
    /**
     Send the audio buffer in 128 frame chunks for the Vita parser. This must be
     sent at a 24 khz rate (5300 microseconds).
     */
    func sendTxAudioStream(){
        var frameCount: Int = 0
        let result = self.audioBuffer.chunked(into: 128)
        
        //print("Chunks: \(result.count)")
        
        
        //api.radio?.localPttEnabled = true // set to true and then check if true - how do I know it worked - look to see if enabled
        // this is new and turns on button - can't get status
        api.radio?.transmit.daxEnabled = true
        api.radio?.mox = true
        txAudioStream.isTransmitChannel = true // WAS .transmit
        txAudioStream.txGain = self.xmitGain
        
        // define the repeating timer for 24000 hz - why 5300, seems it should be 4160
        self.audioStreamTimer = Repeater.every(.microseconds(5300), count: result.count, tolerance: .nanoseconds(1), queue: DispatchQueue(label: "com.w6op", qos: .userInteractive)) { _ in
            let _ = self.txAudioStream.sendTXAudio(left: result[frameCount], right: result[frameCount], samples: Int(result[frameCount].count))
            frameCount += 1
        }
        
        // stop transmitting when you run out of audio - could also be interrupted by STOP button
        self.audioStreamTimer!.onStateChanged = { (_ timer: Repeater, _ state: Repeater.State) in
            if self.audioStreamTimer!.state.isFinished {
                self.api.radio?.mox = false
                // this is new and turns on button - can't get status
                self.api.radio?.transmit.daxEnabled = false
                self.audioStreamTimer = nil
            }
        }
        // start the timer
        self.audioStreamTimer?.start()
    }
    
    func sendCWMessage(message: String)
    {
        
        api.radio?.cwx.send("w6op")
        
    }
} // end class

