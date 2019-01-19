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

internal class AudioManager: NSObject {
    
    var audioPlayer: AVAudioPlayer!
    
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
            if(fileManager.fileExists(atPath: filePath))
            {
                let soundUrl = URL(fileURLWithPath: filePath)
                do{
                    floatArray = try loadAudioSignal(audioURL: soundUrl as NSURL)
                    //let reply = try loadAudioSignal(audioURL: soundUrl as NSURL)
                    //floatArray = reply.signal
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
    //func loadAudioSignal(audioURL: NSURL) throws -> (signal: [Float], rate: Double, frameCount: Int) {
    func loadAudioSignal(audioURL: NSURL) throws -> ([Float]) {
        var floatArray = [Float]()
        
        guard let file = try? AVAudioFile(forReading: audioURL as URL) else {
            return floatArray
        }
        
        // Get the source data format
        var sourceFileID: AudioFileID? = nil
        
        AudioFileOpenURL(audioURL as CFURL, .readPermission, 0, &sourceFileID)
        
        var sourceFormat = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout.stride(ofValue: sourceFormat))
        AudioFileGetProperty(sourceFileID!, kAudioFilePropertyDataFormat, &size, &sourceFormat)
        
        print("Source File format:")
        self.printAudioStreamBasicDescription(sourceFormat)
        
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false)
        let buffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(file.length))
        
        do {
            try file.read(into: buffer!) // You probably want better error handling
        } catch {
            return floatArray
        }
        
//                if file.fileFormat.sampleRate != 24000{
//                    //convert to 24khz
//                    buffer = convertAudioFormat(buffer: buffer!)
//                }
        
        // swift 4
        floatArray = Array(UnsafeBufferPointer(start: buffer?.floatChannelData?[0], count: Int(buffer!.frameLength)))
        
        return (floatArray)
        //return (signal: floatArray, rate: file.fileFormat.sampleRate, frameCount: Int(file.length))
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


