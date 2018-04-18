//
//  SoundManager.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/20/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa
import AVFoundation

internal class AudioManager: NSObject {
    
    // for sinewave generator
//    var ae: AVAudioEngine
//    var player: AVAudioPlayerNode
//    var mixer: AVAudioMixerNode
//    var buffer: AVAudioPCMBuffer
    
    
    var audioPlayer: AVAudioPlayer!
    
    // TODO: Make sure exception handling works
    override init() {
        // initialize objects for sinewave generator
//        ae = AVAudioEngine()
//        player = AVAudioPlayerNode()
//        mixer = ae.mainMixerNode;
//        //var format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24000, channels: 1, interleaved: false)
//        buffer = AVAudioPCMBuffer(pcmFormat: player.outputFormat(forBus: 0), frameCapacity: 128)
//        buffer.frameLength = 128
    }
    
    /**
        Retrieve the file from the user preferences that matches this buttonNumber (tag).
        Pass it on the the method that will load the file and send it to the radio
        - parameter buttonNumber: the tag associated with the button
        - returns: PCM encoded audio as an array of floats
     */
    internal func selectAudioFile(buttonNumber: Int) -> [Float] {
        var floatArray = [Float]()
        let fileManager = FileManager.default

        if let filePath = UserDefaults.standard.string(forKey: String(buttonNumber)) {
            
            //playAudioFile(filePath: filePath)
            
            if(fileManager.fileExists(atPath: filePath))
            {
                //floatArray = convertToPCM(filePath: filePath)

                let soundUrl = URL(fileURLWithPath: filePath)
                let reply = loadAudioSignal(audioURL: soundUrl as NSURL)
                floatArray = reply.signal
            }
        }
        
        //floatArray = generateSineWave()
        //print("floatArray \(floatArray)\n")
        
        return floatArray
    }
    
    


    
    /**
     Read an audio file from disk and convert it to PCM.
         - parameter filePath: path to the file to be converted
             - returns: tuple (array of floats, rate, frame count)
     */
    func loadAudioSignal(audioURL: NSURL) -> (signal: [Float], rate: Double, frameCount: Int) {
        
        let file = try! AVAudioFile(forReading: audioURL as URL)
        
        // Get the source data format.
        
        var sourceFileID: AudioFileID? = nil
        AudioFileOpenURL(audioURL as CFURL, .readPermission, 0, &sourceFileID)
        var sourceFormat = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout.stride(ofValue: sourceFormat))
        AudioFileGetProperty(sourceFileID!, kAudioFilePropertyDataFormat, &size, &sourceFormat)
        print("Source File format:")
        self.printAudioStreamBasicDescription(sourceFormat)
        
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false)
        //let audioFormat = file.processingFormat
        let buffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(file.length))
        
        try! file.read(into: buffer!) // You probably want better error handling
        
// ---------- using NSDATA ---------------------
//        var audioData = try! Data(contentsOf: audioURL as URL)
//        var audio = audioData.subdata(in: 44..<audioData.count - 44)
//        var buffer2 = toPCMBuffer(data: audio as NSData)
        
// ---------------------------------------------------------------------
        // "/Users/pavankumar/Desktop/Testing/Java.txt"
//        let soundUrl = URL(fileURLWithPath: "/Users/pbourget/Desktop/w6op.wav")
//        let settings = [
//            AVFormatIDKey: kAudioFormatLinearPCM,
//            AVSampleRateKey: sourceFormat.mSampleRate,
//            AVNumberOfChannelsKey: 1 ] as [String : Any]
//        let file2 = try! AVAudioFile(forWriting: soundUrl, settings: settings, commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: false)
//        try! file2.write(from: buffer)
// ---------------------------------------------------------------------
        
        
//        let inputSoundfile = AFSoundfile.initAsInput()
//        let status = inputSoundFile.openURL(URL.fileURL(withPath: "existingSoundfile.wav", isDirectory: false))
        
        //let data: Data = toNSData(PCMBuffer: buffer) as Data
        //playAudioFile(data: data)
        // float array, sounds same as floatArray does
//        let arr2 = data.withUnsafeBytes {
//            Array(UnsafeBufferPointer<Float>(start: $0, count: data.count/MemoryLayout<Float>.size))
//        }
        
        
        // swift 4
        let floatArray = Array(UnsafeBufferPointer(start: buffer?.floatChannelData?[0], count: Int(buffer!.frameLength)))
        
        return (signal: floatArray, rate: file.fileFormat.sampleRate, frameCount: Int(file.length))
        
    }
    
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
    
    //    create new rate converter
    func createRateConverter() {
//        var inputDescription: AudioStreamBasicDescription
//        var outputDescription: AudioStreamBasicDescription
//        var status: OSStatus
//        if rateConverter {
//            //  remove any previous rate converter
//            AudioConverterReset(rateConverter)
//            AudioConverterDispose(rateConverter)
//            rateConverter = nil
//        }
//        //    get AudioInfo's asbd, but set number of channels to numberOfClientChannels (number of active channels in channelMap)
//        inputDescription = audioHALUnit.outputUnitASBD
//        outputDescription = inputDescription
//        outputDescription.mSampleRate = (resamplingRate < 100) ? 48000.0 : resamplingRate as? Float64 ?? Float64()
//        //  create a default converter as sanity check
//        status = AudioConverterNew(inputDescription, outputDescription, rateConverter)
//        if status != 0 {
//            print("""
//        AFInputSoundcard: setupRateConverter error.
//
//        """)
//            rateConverter = nil
//        }
//        if rateConverter != nil {
//            needNewRateConverter = false
//            justStarted = true
//        }
    }

    
    
    func toNSData(PCMBuffer: AVAudioPCMBuffer) -> NSData {
        let channelCount = 1  // given PCMBuffer channel count is 1
        let channels = UnsafeBufferPointer(start: PCMBuffer.floatChannelData, count: channelCount)
        let ch0Data = NSData(bytes: channels[0], length:Int(PCMBuffer.frameCapacity * PCMBuffer.format.streamDescription.pointee.mBytesPerFrame))
        return ch0Data
    }
    
    func toPCMBuffer(data: NSData) -> AVAudioPCMBuffer {
        let audioFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 8000, channels: 1, interleaved: false)  // given NSData audio format
        let PCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: UInt32(data.length) / (audioFormat?.streamDescription.pointee.mBytesPerFrame)!)
        PCMBuffer?.frameLength = (PCMBuffer?.frameCapacity)!
        // swift 4
        let channels = UnsafeBufferPointer(start: PCMBuffer?.floatChannelData, count: Int(PCMBuffer!.format.channelCount))
        data.getBytes(UnsafeMutableRawPointer(channels[0]) , length: data.length)
        //data.getBytes(to: UnsafeMutableRawBufferPointer(channels[0]) , count: data.count)
        //data.copyBytes(to: channels[0])
        // data.getBytes(UnsafeMutableRawPointer(channels[0]) , count: data.count) - Original
        return PCMBuffer!
    }
    
    func playAudioFile(data: Data) {
        
        audioPlayer = AVAudioPlayer()
        
        do {
            self.audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: "Wave")
        }
        catch {
            print(error.localizedDescription)
        }
        
        audioPlayer.play()
    }
    
    
    // play the audio file when a button is clicked
    func playAudioFile(filePath: String) {
        
        audioPlayer = AVAudioPlayer()
        
        let fileManager = FileManager.default
        
        if(fileManager.fileExists(atPath: filePath))
        {
            let soundUrl = URL(fileURLWithPath: filePath)
            
            // Create audio player object and initialize with URL to sound
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
                
                audioPlayer.play()
            }
            catch {
                // debug.print
                print (" failed ")
            }
        } else {
            // TODO: will want to notify user
        }

    }
    
    // read an audio file and convert it to PCM
    // https://stackoverflow.com/questions/34751294/how-can-i-generate-an-array-of-floats-from-an-audio-file-in-swift
    
    /**
     Read an audio file from disk and convert it to PCM.
         - parameter filePath: path to the file to be converted
             - returns: array of floats
     */
    func convertToPCM(filePath: String) -> [Float] {
        
        var floatArray = [Float]()
        
        let url = URL(fileURLWithPath: filePath) //Bundle.main.url(forResource: filePath, withExtension: "wav")
        let file = try! AVAudioFile(forReading: url)
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false) // sampleRate: file.fileFormat.sampleRate
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(file.length)) // was 1024
        try! file.read(into: buffer!)
        
        // this makes a copy, might not want that
        // swift 4
        floatArray = Array(UnsafeBufferPointer(start: buffer?.floatChannelData?[0], count:Int(buffer!.frameLength)))
        
        print("floatArray \(floatArray)\n")
        
        return floatArray
    }
    
    
    // TODO: if I ever want to add recording
    // https://stackoverflow.com/questions/26472747/recording-audio-in-swift
    
    
    func generateSineWave() -> [Float] {

        var floatArray = [Float]()
//        var tempArray = [Float]()
//
//        // generate sine wave
//        let sr:Float = Float(mixer.outputFormat(forBus: 0).sampleRate)
//        let n_channels = mixer.outputFormat(forBus: 0).channelCount
//
//        for i in stride(from: 0, to: Int(buffer.frameLength), by: Int(n_channels)){
//            let val = sinf(441.0*Float(i)*2*Float(Double.pi)/sr)
//            buffer.floatChannelData?.pointee[i] = val * 0.5
//            floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0], count:Int(buffer.frameLength)))
//            tempArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0], count:Int(buffer.frameLength)))
//
//            for _ in 0..<50000 {
//                floatArray.append(contentsOf: tempArray)
//            }
//        }

        
       
//        // setup audio engine
//        ae.attach(player)
//        ae.connect(player, to: mixer, format: player.outputFormat(forBus: 0))
//        try! ae.start()
//        // play player and buffer
//        player.play()
//        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)

//                for var i = 0; i < Int(buffer.frameLength); i+=Int(n_channels) {
//                    var val = sinf(441.0*Float(i)*2*Float(Double.pi)/sr)
//
//                    buffer.floatChannelData?.pointee[i] = val * 0.5
//                }
        

        return floatArray
    }
    
    // https://stackoverflow.com/questions/41132418/load-a-pcm-into-a-avaudiopcmbuffer
//    func loadSoundfont(_ pitch : String) {
//        let path: String = Bundle.main.path(forResource: "\(pitch)", ofType: "f32")!
//        let url = URL(fileURLWithPath: path)
//        
//        do {
//            let data = try Data(contentsOf: url)
//            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: true)
//            
//            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(data.count))
//            
//            buffer.floatChannelData!.pointee.withMemoryRebound(to: UInt8.self, capacity: data.count) {
//                let stream = OutputStream(toBuffer: $0, capacity: data.count)
//                stream.open()
//                _ = data.withUnsafeBytes {
//                    stream.write($0, maxLength: data.count)
//                }
//                stream.close()
//            }
//            
//        } catch let error as NSError {
//            print("ERROR HERE", error.localizedDescription)
//        }
//    }
    

} // end class
extension Data {
    func castToCPointer<T>() -> T {
        return self.withUnsafeBytes { $0.pointee }
    }
}
