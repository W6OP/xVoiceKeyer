//
//  Dax.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 6/18/18.
//  Copyright © 2018 Peter Bourget. All rights reserved.
//

import Foundation




/**
 Connect / Disconnect the selected Radio.
 
 - parameters:
 - selectedRadioParameters: an object representing a radio
 */
//    private func openRadio(_ selectedRadioParameters: RadioParameters?) -> Bool {
//
//        if api.connect(selectedRadioParameters!, clientName: clientName, isGui: false) {
//
//            self.selectedRadio = selectedRadioParameters
//
//            if selectedRadio != nil && selectedRadio == activeRadio {
//                // Disconnect the active Radio
//                closeRadio()
//            } else if selectedRadio != nil {
//                if activeRadio != nil {
//                    // Disconnect the active Radio
//                    closeRadio()
//                }
//
//            }
//            return true
//        }
//
//        return false
//    }

//<62706c69 73743030 d4010203 04050615 16582476 65727369 6f6e5824 6f626a65 63747359 24617263 68697665 72542474 6f701200 0186a0a3 07080f55 246e756c 6cd3090a 0b0c0d0e 554e5352 47425c4e 53436f6c 6f725370 61636556 24636c61 73734631 20312030 00100180 02d21011 12135a24 636c6173 736e616d 65582463 6c617373 6573574e 53436f6c 6f72a212 14584e53 4f626a65 63745f10 0f4e534b 65796564 41726368 69766572 d1171854 726f6f74 80010811 1a232d32 373b4148 4e5b6269 6b6d727d 868e919a acafb400 00000000 00010100 00000000 00001900 00000000 00000000 00000000 0000b6>

//<62706c69 73743030 d4010203 04050615 16582476 65727369 6f6e5824 6f626a65 63747359 24617263 68697665 72542474 6f701200 0186a0a3 07080f55 246e756c 6cd3090a 0b0c0d0e 554e5352 47425c4e 53436f6c 6f725370 61636556 24636c61 73734631 20312031 00100180 02d21011 12135a24 636c6173 736e616d 65582463 6c617373 6573574e 53436f6c 6f72a212 14584e53 4f626a65 63745f10 0f4e534b 65796564 41726368 69766572 d1171854 726f6f74 80010811 1a232d32 373b4148 4e5b6269 6b6d727d 868e919a acafb400 00000000 00010100 00000000 00001900 00000000 00000000 00000000 0000b6>

//            let result = self.audioBuffer.chunked(into: 128)
//
//            api.send("xmit 1", diagnostic: false, replyTo: transmitSetHandler)
//
//            // 72 msec = 48Khz - 0.072
//            self.timer = Repeater.every(.seconds(0.072), count: result.count) { _ in
//
//                print("Timer fired: \(frameCount):\(result[frameCount])\n")
//                let _ = self.txAudioStream.sendTXAudio(left: result[frameCount], right: result[frameCount], samples: Int(result[frameCount].count))
//                frameCount += 1
//            }
//            timer?.start()


//let errorString = FlexErrors(rawString:"50000016").description()

//        if !doTransmit  {
//            // swift 4
//            api.radio?.transmit(false) { (result) -> () in
//                // RESET the daxEnabled status to its persisted value
//                self.txAudioStream.transmit = false
//                // swift 4
//                print("Stop Transmit: \(result)")
//                // TODO: account for failure - resend
//            }
//        }

// https://community.flexradio.com/flexradio/topics/how-to-control-the-dax-subsystem-via-the-ethernet-api
//dax audio set <dax channel> slice=<slice index>
// dax audio set <dax channel> tx=0|1



// GET the daxEnabled status and preserve it
// SET the daxEnabled status to true (enabled)

//    /** Key the radio and send the audio stream to the radio.
//
//        - Parameters:
//            - txAudioStream: the audio stream to send
//     */
//    private func sendTxAudioStream(_ txAudioStream: TxAudioStream) {
//
//        self.txAudioStream = txAudioStream
//        self.txAudioStream.txGain = 35
//        self.txAudioStreamRequested = false
//
////        let txAudioActive = false
////
////        // TODO: explore the dax tx handling
////        txAudioStream.transmit = txAudioActive
//
//          //api.radio?.transmitSet(true, callback: transmitSetHandler)
//        // public func send(_ command: String, diagnostic flag: Bool = false, replyTo callback: ReplyHandler? = nil)
//
//        //api.radio?.transmitSet(true) { (result) -> () in
//
//
//        // THIS SHOULD BE WHERE I USE A TIMER TO METER IN THE AUDIO
//        // 128 bytes at a time at a 24k rate
//        // PCM 24kHz mono    188ms
//            // THIS WORKS! https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
//            let result = self.audioBuffer.chunked(into: 128)
//            // for loop to send in pieces of result - metered
//            let _ = txAudioStream.sendTXAudio(left: self.audioBuffer, right: self.audioBuffer, samples: Int(self.audioBuffer.count))
//        //}
//    }
//
//    /**
//     The audio stream has been removed.
//
//        - parameters:
//            - note: a Notification instance
//     */
//    @objc private func txAudioStreamWillBeRemoved(_ note: Notification) {
//        // do I need to do anything ???
//    }

/**
 Let the view controller or other object know the radio was initialized.
 At this point I have the radio but may not have slice and other information.
 i.e. SmartSDR may not be running
 
 - parameters:
 - note: a Notification instance
 */
//    private func radioInitialized(_ note: Notification) {
//
//        // the Radio class has been initialized
//        if let radio = note.object as? Radio {
//            os_log("The Radio has been initialized.", log: RadioManager.model_log, type: .info)
//            DispatchQueue.main.async { [unowned self] in
//                print (radio.slices.count)
//                self.updateRadio()
//                // use delegate to pass message to view controller ??
//                // or use the radio available ??
//            }
//        }
//    }


/**
 Raise event and send to view controller.
 Not in use currently.
 */
//    func updateRadio() {
//
//        os_log("An update to the Radio has been received.", log: RadioManager.model_log, type: .info)
//
//        // we have an update, let the GUI know
//        //radioManagerDelegate?.didUpdateRadio(serialNumber: serialNumber!, activeSlice: activeSlice, transmitMode: mode)
//    }


// MARK: - Slice Methods ----------------------------------------------------------------------------

/**
 Process a newly added Slice - when the radio first starts up you will get a
 notification for each slice that exists.
 
 - parameters:
 - note: a Notification instance
 */
//    private func sliceHasBeenAdded(_ note: Notification) {
//
//        if let slice = note.object as? xLib6000.Slice {
//
//            // TODO: USE xLib60000 SLICE OBJECT ???
////            print ("slice: \(slice.id)")
////            print ("sliceActive: \(slice.active)")
////            print ("sliceTxEnabled: \(slice.txEnabled)")
//
//             var sliceInfo = SliceInfo()
//             sliceInfo.populateSliceInfo(sliceId: Int(slice.id)!, mode: slice.mode, isActiveSlice: slice.active, txEnabled: slice.txEnabled)
////            //let sliceInfo = SliceInfo(sliceId: Int(slice.id)!, mode: slice.mode, isActiveSlice: slice.active, txEnabled: slice.txEnabled)
////
//            print ("sliceInfo: \(sliceInfo.sliceId)")
//
//            availableSlices[sliceInfo.sliceId] = sliceInfo
//
//            //radioManagerDelegate?.didUpdateSlice(availableSlices: availableSlices)
//
//        }
//    }

/**
 Cleanup when a slice has been removed.
 
 - parameters:
 - note: a Notification instance
 */
//    private func sliceWillBeRemoved(_ note: Notification) {
//
//        if let slice = note.object as? xLib6000.Slice {
//            print (slice.id)
//        }
//    }



// ----------------------------------------------------------------------------
//    /**
//     Process the tcpDidConnect Notification.
//
//        - parameters:
//            - note: a Notification instance
//    */
//    private func tcpDidConnect(_ note: Notification) {
//        os_log("A TCP connection has been established.", log: RadioManager.model_log, type: .info)
//    }
//
//    /**
//     Process the tcpDidDisconnect Notification.
//
//        - parameters:
//            - note: a Notification instance
//    */
//    private func tcpDidDisconnect(_ note: Notification) {
//
//        os_log("The TCP connection is being terminated.", log: RadioManager.model_log, type: .info)
//
//        if ((note.object as! Api.DisconnectReason) == .normal) {
//            // let the view controller know a radio was disconnected to
//            self.radioManagerDelegate?.didDisconnectFromRadio()
//
//        }
//    }

////            self.createTxAudioStream()
//
//            let result = self.audioBuffer.chunked(into: 128)
//
//
//
//            //let streams = api.radio!.audioStreams.values.filter { $0.daxChannel == 1 }
//
//             //api.radio?.mox = true
//
//            // 72 msec = 48Khz - 0.072
//            self.audioStreamTimer = Repeater.every(.seconds(0.072), count: result.count) { _ in
//
//                //print("Timer fired: \(frameCount):\(result[frameCount])\n")
//                let _ = self.txAudioStream.sendTXAudio(left: result[frameCount], right: result[frameCount], samples: Int(result[frameCount].count))
//                frameCount += 1
//            }
//            // stop transmitting when you run out of audio - could also be interrupted
//            self.audioStreamTimer!.onStateChanged = { (_ timer: Repeater, _ state: Repeater.State) in
//                if self.audioStreamTimer!.state.isFinished {
//                    self.api.radio?.mox = false
//                    //self.api.send("xmit 0")
//                    self.audioStreamTimer = nil
//                }
//            }
//
//            audioStreamTimer?.start()
//
//
//
//            //api.send("xmit 1", diagnostic: false, replyTo: transmitSetHandler)

