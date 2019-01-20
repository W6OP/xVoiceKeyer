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

internal class AudioManager: NSObject {
    
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
    internal func selectAudioFile(buttonNumber: Int) -> [Float] {
        var floatArray = [Float]()
        let fileManager = FileManager.default
        
        if let filePath = UserDefaults.standard.string(forKey: String(buttonNumber)) {
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
                    print("error \(error.localizedDescription)")
                }
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
        } catch {
            return floatArray
        }
        
        // convert to 24khz if necessary
        if stream.fileFormat.sampleRate != 24000{
            buffer = convertPCMBufferSampleRate(inBuffer: buffer!, inputFormat: format!)
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
    func convertPCMBufferSampleRate(inBuffer : AVAudioPCMBuffer, inputFormat: AVAudioFormat) -> AVAudioPCMBuffer {

        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24000, channels: 1, interleaved: false)
        let converter = AVAudioConverter(from: inputFormat, to: outputFormat!)
        
        let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat!, frameCapacity: AVAudioFrameCount(inBuffer.frameCapacity))
        
        let inputBlock : AVAudioConverterInputBlock = {
            inNumPackets, outStatus in
            outStatus.pointee = AVAudioConverterInputStatus.haveData
            return inBuffer
        }
        
        var error : NSError?
        _ = converter!.convert(to: convertedBuffer!, error: &error, withInputFrom: inputBlock)
        //assert(status != .error)
//        print(status.rawValue)
//        print(inBuffer.format)
//        print(convertedBuffer!.format)
//        print(convertedBuffer!.floatChannelData)
//        print(convertedBuffer!.format.streamDescription.pointee.mBytesPerFrame)
        
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
    
    // TODO: if I ever want to add recording
    // https://stackoverflow.com/questions/26472747/recording-audio-in-swift
    // https://github.com/snyuryev/m4a-converter-swift/blob/master/ConverterTest/ViewController.swift
   
} // end class


