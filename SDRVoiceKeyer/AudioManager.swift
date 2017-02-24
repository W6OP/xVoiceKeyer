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
    
    var audioPlayer: AVAudioPlayer!
    
    // TODO: Make sure exception handling works
    override init() {
        
    }
    
    // When one of the buttons on the main form is clicked its tag will be sent.
    // Retrieve the file from the user preferences that matches this tag and
    // pass it on the the method that will load the file and send it to the radio
    // TODO: add code for multiple profiles
    internal func selectAudioFile(tag: Int) {
        
        if let filePath = UserDefaults.standard.string(forKey: String(tag)) {
            playAudioFile(filePath: filePath)
        }
        
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
    
    
    

} // end class
