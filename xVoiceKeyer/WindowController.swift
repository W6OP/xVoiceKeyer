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
 WindowController.swift
 xVoiceKeyer
 
 Created by Peter Bourget on 1/29/2019.
 Copyright © 2019 Peter Bourget W6OP. All rights reserved.
 Description: Window controller to capture events from the touchbar.
 
 https://spin.atomicobject.com/2017/11/18/nstouchbar-storyboards/
 */

import Cocoa

internal class WindowController: NSWindowController {
    
    /**
     Handle the Stop button on the touchbar
     */
    @IBAction func stopButton(_ sender: NSButton) {
        let viewController = contentViewController as! ViewController;
        viewController.stopTransmitting()
    }
    
    /**
     Handle the Segment control on the touchbar. Treat as an
     array of buttons.
     */
    @IBAction func segmentControl(_ sender: NSSegmentedCell) {
        //print("Segment Test \(sender.selectedSegment)")
        let segment = sender.selectedSegment
        let buttonNumber: Int = segment + 1
        
        let viewController = contentViewController as! ViewController;
        viewController.voiceButtonSelected(buttonNumber: buttonNumber)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.windowFrameAutosaveName = "xVoiceKeyer"
    }
    
}
