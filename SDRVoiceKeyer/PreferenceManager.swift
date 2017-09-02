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
//  PreferenceManager.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/23/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa

// http://stackoverflow.com/questions/28008262/detailed-instruction-on-use-of-nsopenpanel
/**
    Extension to open a preference panel.
 */
extension NSOpenPanel {
    var selectUrl: URL? {
        title = "Select File"
        allowsMultipleSelection = false
        canChooseDirectories = false
        canChooseFiles = true
        canCreateDirectories = false
        allowedFileTypes = ["wav"]  // to allow only images, just comment out this line to allow any file type to be selected
        return runModal() == NSFileHandlingPanelOKButton ? urls.first : nil
        // This works with Swift 4
        //return runModal() == NSApplication.ModalResponse.OK ? urls.first : nil
    }
}

/**
    Protocol to pass messages back to viewcontroller.
 */
protocol PreferenceManagerDelegate: class {
    // radio was discovered
    func doConnectRadio(serialNumber: String)
}

enum YesNo: String {
    case No = "No"
    case Yes = "Yes"
}

class PreferenceManager: NSObject {
    
    /**
        Delegate to pass messages back to viewcontroller.
     */
    var preferenceManagerDelegate:PreferenceManagerDelegate?
    
    // TODO: Make sure exception handling works
    override init() {
        super.init()
    }
    
    /**
        Get the file path from the selected item.
        - returns: String
     */
    internal func getFilePath() -> String {
        var filePath = ""
        
        if let url = NSOpenPanel().selectUrl {
            filePath = url.path
        }
        
        return filePath
    }
    
    /**
        Send a message to delegate subscriber to call doConnectRadio() method
        using the radio's serial number.
        - parameter serialNumber: String
     */
    @objc func connectToRadio(serialNumber: String){
        
        self.preferenceManagerDelegate?.doConnectRadio(serialNumber: serialNumber)
        
    }

} // end class
