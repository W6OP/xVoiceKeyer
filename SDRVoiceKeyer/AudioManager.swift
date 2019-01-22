//
//  SoundManager.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/20/17.
//  Copyright © 2019 Peter Bourget W6OP. All rights reserved.
//

import Cocoa
import AVFoundation
import MediaPlayer
import AudioToolbox

protocol AudioManagerDelegate: class {
    // send message to view controller
    func audioMessageReceived(messageKey: AudioMessage, message: String)
}

public enum AudioMessage : String {
    case ButtonNotConfigured = "BUTTON"
    case Error = "ERROR"
    case FileMissing = "FILE"
    case InvalidFileType = "FILETYPE"
}

internal class AudioManager: NSObject {
    
    weak var audioManagerDelegate:AudioManagerDelegate?
    
    var audioPlayer: AVAudioPlayer!
    var buffers = [Int: [Float]]() // cache for audio buffers to reduce disk reads
    
    let Required_Sample_Rate: Double = 24000
    
    override init() {
       
    }
    
    /**
     Retrieve the file from the user preferences that matches this buttonNumber (tag).
     Pass it on the the method that will load the file and send it to the radio
     - parameter buttonNumber: the tag associated with the button
     - returns: PCM encoded audio as an array of floats at 24khz bit rate
     */
    internal func selectAudioFile(buttonNumber: Int) -> [Float] {
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
                    // if buffer does not contain value already
                    buffers.updateValue(floatArray, forKey: buttonNumber)
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
        
        print("Source File description:")
        self.printAudioStreamBasicDescription(sourceDescription)
        
       
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: stream.fileFormat.sampleRate, channels: 1, interleaved: false)
        var buffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(stream.length))
    
        
        do {
            try stream.read(into: buffer!)
        } catch let error {
            notifyViewController(key: AudioMessage.Error, messageData: audioURL.absoluteString! + "    \(error.localizedDescription)")
            return floatArray
        }
        
        // convert to 24khz if necessary
        if stream.fileFormat.sampleRate != Required_Sample_Rate{
            buffer = convertPCMBufferSampleRate(inBuffer: buffer!, inputFormat: format!, inputSampleRate: stream.fileFormat.sampleRate)
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

        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Required_Sample_Rate, channels: 1, interleaved: false)
        let converter = AVAudioConverter(from: inputFormat, to: outputFormat!)
        
        // need to reduce the frame capacity or you get multiple replays
        let divisor: UInt32 = UInt32(inputSampleRate/Required_Sample_Rate)
        
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
    func notifyViewController(key: AudioMessage, messageData: String){
    
        var message: String
        
        switch key {
        case AudioMessage.FileMissing:
            message = "The file \(messageData) could not be found."
        case AudioMessage.InvalidFileType:
            message = "The file \(messageData) could not be read. It may be corrupt or an invalid file type."
        case AudioMessage.ButtonNotConfigured  :
            message = "Button \(messageData) does not have an audio file configured."
        case AudioMessage.Error:
            message = "The file \(messageData) could not be read. It may be corrupt or an invalid file type."
        }
        
        UI() {
            self.audioManagerDelegate?.audioMessageReceived(messageKey: key, message: message)
        }
    }
    
    // TODO: if I ever want to add recording
    // https://stackoverflow.com/questions/26472747/recording-audio-in-swift
    // https://github.com/snyuryev/m4a-converter-swift/blob/master/ConverterTest/ViewController.swift
   
} // end class

