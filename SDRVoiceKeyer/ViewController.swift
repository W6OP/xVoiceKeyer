/**
 * Copyright (c) 2017 W6OP
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
//
//  MainViewController.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/10/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa


// http://stackoverflow.com/questions/29418310/set-color-of-nsbutton-programmatically-swift

class ViewController: NSViewController, RadioManagerDelegate {
    
    var radioManager: RadioManager!
    var audiomanager: AudioManager!
    //var radio: Radio!
    var transmitMode: TransmitMode = TransmitMode.Invalid
    
    // outlets
    @IBOutlet weak var voiceButton1: NSButton!
    @IBOutlet weak var serialNumberLabel: NSTextField!
    @IBOutlet weak var activeSliceLabel: NSTextField!
    @IBOutlet weak var buttonStackView: NSStackView!

    // actions
    // this handles all of the voice buttons - use the tag value to determine which audio file to load
    @IBAction func voiceButtonClicked(_ sender: NSButton) {
        audiomanager.selectAudioFile(tag: sender.tag)
    }
    
    // show the preference pane
    @IBAction func buttonShowPreferences(_ sender: AnyObject) {
        showPreferences(sender)
    }
    
    // generated code
    override func viewDidLoad() {
        super.viewDidLoad()

        //radio = Radio()
        
        // create an instance of my radio manager and assign a delegate from it so I can handle events it raises
        //do {
            radioManager = RadioManager()
            radioManager.radioManagerDelegate = self
            
            audiomanager = AudioManager()
//        }
//        catch let error as NSError {
//            // debug.print
//            print("Error: \(error.userInfo.description)")
//        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // cleanup network sockets when application terminates
    // TODO: put method in RadioManager and also close Radio object
    override func viewWillDisappear() {
        radioManager.CloseAll()
    }
    
    // my code
    
     // event handler from Radiomanager - do stuff like updating the UI
    // if we have a serial number, an active slice and the slice is set to a voice mode we can enable the buttons
    func didUpdateRadio(serialNumber: String, activeSlice: String, transmitMode: TransmitMode) {
        
        serialNumberLabel.stringValue = serialNumber
        activeSliceLabel.stringValue = activeSlice
        self.transmitMode = transmitMode
    }
    
    // show the preferences panel and populate it
    func showPreferences(_ sender: AnyObject) {
        let SB = NSStoryboard(name: "Main", bundle: nil)
        let PVC: RadioPreferences = SB.instantiateController(withIdentifier: "radioPreferences") as! RadioPreferences
        
        presentViewControllerAsSheet(PVC)
    }
    
} // end class

