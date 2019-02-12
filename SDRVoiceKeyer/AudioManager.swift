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
 AudioManager.swift
 SDRVoiceKeyer
 
 Created by Peter Bourget on 2/20/17.
 Copyright © 2019 Peter Bourget W6OP. All rights reserved.
 
 Description: This class manages all of the audio processing. It loads the audio
 files off the disk, checks their format and loads an audio buffer. Converts the
 sample rate if necessary and returns a Float Array to be sent to the radio by
 the RadioManager class.
 */

import Cocoa
import AVFoundation
import AudioToolbox
import os

// send message to view controller
protocol AudioManagerDelegate: class {
    func audioMessageReceived(messageKey: AudioMessage, message: String)
}

// enforce error literals
public enum AudioMessage : String {
    case ButtonNotConfigured = "BUTTON"
    case Error = "ERROR"
    case FileMissing = "FILE"
    case InvalidFileType = "FILETYPE"
    case InvalidSampleRate = "SAMPLERATE"
}

// Start of class definition.
class AudioManager: NSObject {
    
    weak var audioManagerDelegate:AudioManagerDelegate?
    
    // setup logging for the RadioManager
    static let model_log = OSLog(subsystem: "com.w6op.AudioManager-Swift", category: "Model")
    static let Required_Sample_Rate: Double = 24000
    
    var audioPlayer: AVAudioPlayer!
    var buffers = [Int: [Float]]() // cache for audio buffers to reduce disk reads
    
    override init() {
        
    }
    
    /**
     Retrieve the file from the user preferences that matches this buttonNumber (tag).
     Pass it on the the method that will load the file and send it to the radio
     - parameter buttonNumber: the tag associated with the button
     - returns: PCM encoded audio as an array of floats at 24khz bit rate
     */
    func selectAudioFile(buttonNumber: Int) -> [Float] {
        var floatArray = [Float]()
        let fileManager = FileManager.default
        
        if let filePath = UserDefaults.standard.string(forKey: String(buttonNumber)) {
            
            if filePath.isEmpty {
                notifyViewController(key: AudioMessage.ButtonNotConfigured, messageData: String(buttonNumber))
                return floatArray
            }
            
            // check cache first
            if buffers[buttonNumber] != nil {
                return buffers[buttonNumber]!
            }
            
            if (fileManager.fileExists(atPath: filePath))
            {
                let soundUrl = URL(fileURLWithPath: filePath)
                do{
                    floatArray = try loadAudioSignal(audioURL: soundUrl as NSURL)
                    if floatArray.count > 0 // if buffer does not contain value already
                    {
                        buffers.updateValue(floatArray, forKey: buttonNumber)
                    } else {
                        buffers.removeValue(forKey: buttonNumber)
                    }
                } catch{
                    notifyViewController(key: AudioMessage.Error, messageData: String(error.localizedDescription))
                }
            } else {
                notifyViewController(key: AudioMessage.FileMissing, messageData: filePath)
            }
        }
        
        return floatArray
    }
    
    /**
     Read an audio file from disk and convert it to PCM.
     - parameter filePath: path to the file to be converted
     - returns: tuple (array of floats, rate, frame count)
     */
    func loadAudioSignal(audioURL: NSURL) throws -> ([Float]) {
        var floatArray = [Float]()
        var sourceFileID: AudioFileID? = nil
        
        // read the file to a stream
        guard let stream = try? AVAudioFile(forReading: audioURL as URL) else {
            notifyViewController(key: AudioMessage.InvalidFileType, messageData: audioURL.absoluteString!)
            return floatArray
        }
        
        // Get the source data format
        AudioFileOpenURL(audioURL as CFURL, .readPermission, 0, &sourceFileID)
        defer {AudioFileClose(sourceFileID!)}
        
        var sourceDescription = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout.stride(ofValue: sourceDescription))
        AudioFileGetProperty(sourceFileID!, kAudioFilePropertyDataFormat, &size, &sourceDescription)
        
        #if DEBUG
        //print("Source File description:")
        //self.printAudioStreamBasicDescription(sourceDescription)
        #endif
        
        let sampleRate = stream.fileFormat.sampleRate
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false)
        var buffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(stream.length))
        
        // if sample rate is less than 24khz, just notify user
        if sampleRate < AudioManager.Required_Sample_Rate {
            notifyViewController(key: AudioMessage.InvalidSampleRate, messageData: "\(audioURL)", "\(sampleRate)")
            return floatArray
        }
        
        do {
            try stream.read(into: buffer!)
        } catch let error {
            notifyViewController(key: AudioMessage.Error, messageData: audioURL.absoluteString! + "    \(error.localizedDescription)")
            return floatArray
        }
        
        // convert to 24khz if necessary
        if sampleRate > AudioManager.Required_Sample_Rate {
            if Int32(sampleRate.truncatingRemainder(dividingBy: AudioManager.Required_Sample_Rate)) == 0 {
                buffer = convertPCMBufferSampleRate(inBuffer: buffer!, inputFormat: format!, inputSampleRate: sampleRate)
            } else {
                notifyViewController(key: AudioMessage.InvalidSampleRate, messageData: "\(audioURL)", "\(sampleRate)")
                
                return floatArray
            }
        }
        
        // swift 4
        floatArray = Array(UnsafeBufferPointer(start: buffer?.floatChannelData?[0], count: Int(buffer!.frameLength)))
        
        return (floatArray)
    }
    
    // https://forums.developer.apple.com/message/193747#193747
    // https://forums.developer.apple.com/message/263741#263741
    /**
     Convert an audio file sample rate to 24khz.
     - parameter inBuffer: the PCM buffer to be coverted
     - parameter inputFormat: the format of the buffer to be converted
     - returns: AVAudioPCMBuffer converted to 24khz
     */
    func convertPCMBufferSampleRate(inBuffer : AVAudioPCMBuffer, inputFormat: AVAudioFormat, inputSampleRate: Double) -> AVAudioPCMBuffer {
        
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: AudioManager.Required_Sample_Rate, channels: 1, interleaved: false)
        let converter = AVAudioConverter(from: inputFormat, to: outputFormat!)
        
        os_log("Sample rate conversion requested.", log: AudioManager.model_log, type: .info)
        
        // need to reduce the frame capacity or you get multiple replays
        let divisor: UInt32 = UInt32(inputSampleRate/AudioManager.Required_Sample_Rate)
        
        let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat!, frameCapacity: AVAudioFrameCount(inBuffer.frameCapacity/divisor))
        
        let inputBlock : AVAudioConverterInputBlock = {
            inNumPackets, outStatus in
            outStatus.pointee = AVAudioConverterInputStatus.haveData
            return inBuffer
        }
        
        var error : NSError?
        _ = converter!.convert(to: convertedBuffer!, error: &error, withInputFrom: inputBlock)
        
        return convertedBuffer!
    }
    
    /**
     print the detailed information about an audio file.
     - parameter asbd: printAudioStreamBasicDescription - description object for the file
     */
    func printAudioStreamBasicDescription(_ asbd: AudioStreamBasicDescription) {
        print(String(format: "Sample Rate:         %10.0f",  asbd.mSampleRate))
        //print(String(format: "Format ID:                 \(asbd.mFormatID.fourCharString)"))
        print(String(format: "Format Flags:        %10X",    asbd.mFormatFlags))
        print(String(format: "Bytes per Packet:    %10d",    asbd.mBytesPerPacket))
        print(String(format: "Frames per Packet:   %10d",    asbd.mFramesPerPacket))
        print(String(format: "Bytes per Frame:     %10d",    asbd.mBytesPerFrame))
        print(String(format: "Channels per Frame:  %10d",    asbd.mChannelsPerFrame))
        print(String(format: "Bits per Channel:    %10d",    asbd.mBitsPerChannel))
        print()
    }
    
    /**
     pass messages to the view controller
     - parameter key: AudioMessage - enum value for the message
     - parameter messageData: String - data to be added to the message
     */
    func notifyViewController(key: AudioMessage, messageData: String...){
        
        var message: String
        
        switch key {
        case AudioMessage.FileMissing:
            message = "The file \(NSString(string: messageData[0]).removingPercentEncoding!) could not be found."
        case AudioMessage.InvalidFileType:
            message = "The file \(NSString(string: messageData[0]).removingPercentEncoding!) could not be read. It may be corrupt or an invalid file type."
        case AudioMessage.ButtonNotConfigured  :
            message = "Button \(NSString(string: messageData[0]).removingPercentEncoding!) does not have an audio file configured."
        case AudioMessage.Error:
            message = "The file \(NSString(string: messageData[0]).removingPercentEncoding!) could not be read. It may be corrupt or an invalid file type."
        case AudioMessage.InvalidSampleRate:
            message = "The file \(NSString(string: messageData[0]).removingPercentEncoding!) could not be processed. The sample rate should be 24000. This files sample rate is \(messageData[1])"
        }
        
        UI() {
            self.audioManagerDelegate?.audioMessageReceived(messageKey: key, message: message)
        }
    }
    
    // TODO: if I ever want to add recording
    // https://stackoverflow.com/questions/26472747/recording-audio-in-swift
    // https://github.com/snyuryev/m4a-converter-swift/blob/master/ConverterTest/ViewController.swift
    
} // end class

