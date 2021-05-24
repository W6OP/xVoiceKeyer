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
 xVoiceKeyer
 
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
protocol AudioManagerDelegate: AnyObject {
  func audioMessageReceived(messageKey: audioMessage, message: String)
}

// enforce error literals
public enum audioMessage : String {
  case buttonNotConfigured = "BUTTON"
  case error = "ERROR"
  case fileMissing = "FILE"
  case invalidFileType = "FILETYPE"
  case invalidSampleRate = "SAMPLERATE"
  case KeyRadio = "KeyRadio"
}

extension FileManager {
  
  open func secureCopyItem(at srcURL: URL, to dstURL: URL, message: inout String) -> Bool {
    do {
      if FileManager.default.fileExists(atPath: dstURL.path) {
        try FileManager.default.removeItem(at: dstURL)
      }
      try FileManager.default.copyItem(at: srcURL, to: dstURL)
    } catch (let error) {
      message = error.localizedDescription
      print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
      return false
    }
    return true
  }
}

// Start of class definition.
class AudioManager: NSObject {
  
  weak var audioManagerDelegate:AudioManagerDelegate?
  
  // setup logging for the RadioManager
  static let model_log = OSLog(subsystem: "com.w6op.AudioManager-Swift", category: "Model")
  static let Required_Sample_Rate: Double = 24000
  
  var audioPlayer: AVAudioPlayer!
  var buffers = [Int: [Float]]() // cache for audio buffers to reduce disk reads
  
  //
  override init() {
    
  }
  
  /**
   Clear the file cache when the file preferences were changed
   in case a new file with the same label was loaded.
   */
  func clearFileCache() {
    buffers.removeAll()
  }
  
  func getDocumentsDirectory() -> URL {
    // find all possible documents directories for this user
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

    // just send back the first one, which ought to be the only one
    return paths[0]
  }

  /**
   Retrieve the file from the user preferences that matches this buttonNumber (tag).
   Pass it on the the method that will load the file and send it to the radio
   - parameter buttonNumber: the tag associated with the button
   - returns: PCM encoded audio as an array of floats at 24khz bit rate
   */
  func selectAudioFile(buttonNumber: Int) -> [Float] {
    var floatArray = [Float]()

    // fileArray = [sourceFilePath, labelText, destURL.absoluteString]
    guard let fileArray = UserDefaults.standard.array(forKey: String(buttonNumber)) else {
      return floatArray
    }



    if let filePath = fileArray[2] as? String { //UserDefaults.standard.string(forKey: String(buttonNumber)) {

      if filePath.isEmpty {
        notifyViewController(key: audioMessage.buttonNotConfigured, messageData: String(buttonNumber))
        return floatArray
      }

      // temp code
      if filePath == "KeyRadio" {
        notifyViewController(key: audioMessage.KeyRadio, messageData: String(buttonNumber))
        return floatArray
      }

      //  check cache first
      if buffers[buttonNumber] != nil {
        return buffers[buttonNumber]!
      }

      let fileName = NSURL(fileURLWithPath: filePath).lastPathComponent
      let soundUrl = self.getDocumentsDirectory().appendingPathComponent(fileName!)

      if FileManager.default.fileExists(atPath: soundUrl.path) {
        do{
          floatArray = try loadAudioSignal(audioURL: soundUrl as NSURL)
          if floatArray.count > 0 // if buffer does not contain value already
          {
            buffers.updateValue(floatArray, forKey: buttonNumber)
          } else {
            buffers.removeValue(forKey: buttonNumber)
          }
        } catch{
          notifyViewController(key: audioMessage.error, messageData: String(error.localizedDescription))
        }
      }
      else {
        notifyViewController(key: audioMessage.fileMissing, messageData: filePath)
      }
    }

    return floatArray
  }

  /// Mark: - Legacy

  /**
   Retrieve the file from the user preferences that matches this buttonNumber (tag).
   Pass it on the the method that will load the file and send it to the radio
   - parameter buttonNumber: the tag associated with the button
   - returns: PCM encoded audio as an array of floats at 24khz bit rate
   */
//  func selectAudioFile(buttonNumber: Int) -> [Float] {
//      var floatArray = [Float]()
//      let fileManager = FileManager.default
//
//      if let filePath = UserDefaults.standard.string(forKey: String(buttonNumber)) {
//
//          if filePath.isEmpty {
//              notifyViewController(key: audioMessage.buttonNotConfigured, messageData: String(buttonNumber))
//              return floatArray
//          }
//
//        // temp code
////        if filePath == "KeyRadio" {
////          notifyViewController(key: audioMessage.KeyRadio, messageData: String(buttonNumber))
////            return floatArray
////        }
//
//
//          // check cache first
////          if buffers[buttonNumber] != nil {
////              return buffers[buttonNumber]!
////          }
//
//        // let destinationUrl = documentsDirectoryURL.appendingPathComponent("\(reciter.name): \(surah.number).mp3")
//
//          if (fileManager.fileExists(atPath: filePath))
//          {
//              let soundUrl = URL(fileURLWithPath: filePath)
//              do{
//                  floatArray = try loadAudioSignal(audioURL: soundUrl as NSURL)
//                  if floatArray.count > 0 // if buffer does not contain value already
//                  {
//                      buffers.updateValue(floatArray, forKey: buttonNumber)
//                  } else {
//                      buffers.removeValue(forKey: buttonNumber)
//                  }
//              } catch{
//                  notifyViewController(key: audioMessage.error, messageData: String(error.localizedDescription))
//              }
//          } else {
//              notifyViewController(key: audioMessage.fileMissing, messageData: filePath)
//          }
//      }
//
//      return floatArray
//  }

  /// Mark: - End Legacy
  ///
  /**
   Read an audio file from disk and convert it to PCM.
   - parameter filePath: path to the file to be converted
   - returns: tuple (array of floats, rate, frame count)
   */
  func loadAudioSignal(audioURL: NSURL) throws -> ([Float]) {
    var floatArray = [Float]()
    var sourceFileID: AudioFileID? = nil
    var stream: AVAudioFile
    
    // read the file to a stream
//    guard let stream = try? AVAudioFile(forReading: audioURL as URL) else {
//      notifyViewController(key: audioMessage.invalidFileType, messageData: audioURL.absoluteString!)
//      return floatArray
//    }
    /*
     file:///Users/pbourget/Documents/Ham%20Radio/Voice%20Files/Flex%20Wav%20Files/W6OP_Once.wav
     file:///Users/pbourget/Documents/Ham%20Radio/Voice%20Files/Flex%20Wav%20Files/W6OP_Once.wav
     file:///Users/pbourget/Library/Containers/com.w6op.xVoiceKeyer/Data/Documents/W6OP_Once.wav
     */

    // let destinationUrl = documentsDirectoryURL.appendingPathComponent("\(reciter.name): \(surah.number).mp3")
    do {
      stream = try AVAudioFile(forReading: audioURL as URL)
       } catch let error {
           //showAlert(title: Alerts.AudioFileError, message: String(describing: error))
        print ("Error: \(error)")
        notifyViewController(key: audioMessage.invalidFileType, messageData: audioURL.absoluteString!)
        return floatArray
       }

    // debugging
    //return floatArray


    // Get the source data format
    AudioFileOpenURL(audioURL as CFURL, .readPermission, 0, &sourceFileID)
    defer {AudioFileClose(sourceFileID!)}
    
    var sourceDescription = AudioStreamBasicDescription()
    var size = UInt32(MemoryLayout.stride(ofValue: sourceDescription))
    AudioFileGetProperty(sourceFileID!, kAudioFilePropertyDataFormat, &size, &sourceDescription)
    
    #if DEBUG
    //print("Source File description:")
    self.printAudioStreamBasicDescription(sourceDescription)
    #endif
    
    let sampleRate = stream.fileFormat.sampleRate
    let format = stream.processingFormat
    var buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(stream.length))
    
    // if sample rate is less than 24khz, just notify user
    if sampleRate < AudioManager.Required_Sample_Rate {
      notifyViewController(key: audioMessage.invalidSampleRate, messageData: "\(audioURL)", "\(sampleRate)")
      return floatArray
    }
    
    do {
      try stream.read(into: buffer!)
    } catch let error {
      notifyViewController(key: audioMessage.error, messageData: audioURL.absoluteString! + "    \(error.localizedDescription)")
      return floatArray
    }
    
    // convert to 24khz if necessary
    if sampleRate > AudioManager.Required_Sample_Rate {
      buffer = convertPCMBufferSampleRate(inBuffer: buffer!, inputFormat: format, inputSampleRate: sampleRate)
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
    // this divisor works for multiples of 24000 but not 44100
    let modulo = inputSampleRate.truncatingRemainder(dividingBy: AudioManager.Required_Sample_Rate)
    
    let divisor: UInt32 = UInt32(inputSampleRate/AudioManager.Required_Sample_Rate)
    
    // this works for most 44100
    let sampleRateConversionRatio: Double = inputSampleRate/AudioManager.Required_Sample_Rate
    
    var convertedBuffer: AVAudioPCMBuffer
    if modulo != 0 {
      let framelength = Double(inBuffer.frameCapacity)
      let newDivisor = framelength / sampleRateConversionRatio
      
      convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat!, frameCapacity: AVAudioFrameCount(newDivisor))! // THIS WORKS FOR A LONG FILE BUT NOT A SHORT ONE
    } else {
      //print("divisor: \(sampleRateConversionRatio) inbuffer length: \(inBuffer.frameCapacity)")
      convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat!, frameCapacity: AVAudioFrameCount(inBuffer.frameCapacity)/divisor)! // /divisor
    }
    
    let inputBlock : AVAudioConverterInputBlock = {
      inNumPackets, outStatus in
      outStatus.pointee = AVAudioConverterInputStatus.haveData
      return inBuffer
    }
    
    var error : NSError?
    _ = converter!.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
    
    return convertedBuffer
  }
  
  /**
   print the detailed information about an audio file.
   - parameter asbd: printAudioStreamBasicDescription - description object for the file
   */
  func printAudioStreamBasicDescription(_ asbd: AudioStreamBasicDescription) {
    print(String(format: "Sample Rate:         %10.0f",  asbd.mSampleRate))
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
   - parameter key: audioMessage - enum value for the message
   - parameter messageData: String - data to be added to the message
   */
  func notifyViewController(key: audioMessage, messageData: String...){
    
    var message: String
    
    switch key {
    case .fileMissing:
      message = "The file \(NSString(string: messageData[0]).removingPercentEncoding!) could not be found."
    case .invalidFileType:
      message = "The file \(NSString(string: messageData[0]).removingPercentEncoding!) could not be read. It may be corrupt or an invalid file type."
    case .buttonNotConfigured  :
      message = "Button \(NSString(string: messageData[0]).removingPercentEncoding!) does not have an audio file configured."
    case .error:
      message = "The file \(NSString(string: messageData[0]).removingPercentEncoding!) could not be read. It may be corrupt or an invalid file type."
    case .invalidSampleRate:
      message = "The file \(NSString(string: messageData[0]).removingPercentEncoding!) could not be processed. The sample rate should be 24000. This files sample rate is \(messageData[1])"
    case .KeyRadio:
      message = "Key Radio"
    }
    
    UI() {
      self.audioManagerDelegate?.audioMessageReceived(messageKey: key, message: message)
    }
  }
  
  // TODO: if I ever want to add recording
  // https://stackoverflow.com/questions/26472747/recording-audio-in-swift
  // https://github.com/snyuryev/m4a-converter-swift/blob/master/ConverterTest/ViewController.swift
  
} // end class

