/**
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

/**
 FilePreferences.swift
 SDRVoiceKeyer
 
 Created by Peter Bourget on 2/2/19.
 Copyright © 2019 Peter Bourget. All rights reserved.
 
 Description: Loads and save the user defaults and settings.
 */

import Cocoa

// http://stackoverflow.com/questions/28008262/detailed-instruction-on-use-of-nsopenpanel
/**
 Extension to open a preference panel.
 */
extension NSOpenPanel {
    var selectUrl: URL? {
        title = "Select Audio File"
        allowsMultipleSelection = false
        canChooseDirectories = false
        canChooseFiles = true
        canCreateDirectories = false
        allowedFileTypes = ["wav", "mp3", "m4a", "aac", "aiff"]
        // This works with Swift 4
        return runModal() == NSApplication.ModalResponse.OK ? urls.first : nil
    }
}

class FilePreferences: NSViewController {
    
    // class variables
    var preferenceManager: PreferenceManager!
    
    var allTextFields: Dictionary = [Int: NSTextField]()
    var timerState: String = "ON"
    
    @IBOutlet weak var timerInterval: NSTextField!
    @IBOutlet weak var fileSelector: NSButton!
    @IBOutlet weak var timerAudioFile: NSTextField!
    @IBOutlet weak var timerEnabler: NSButton!
    
    /**
     Enable call ID reminder timer.
     - parameters:
     - button: Handle to the button clicked.
     */
    @IBAction func setTimerState(_ sender: NSButton) {
        
        switch sender.state {
        case .on:
            preferenceManager.enableTimer(isEnabled: true, interval: Int(timerInterval.stringValue) ?? 10)
        case .off:
            preferenceManager.enableTimer(isEnabled: false, interval: Int(timerInterval.stringValue) ?? 10)
        default: break
        }
    }
    
    /**
     Select the file to be used for the ID timer.
     - parameters:
     - button: Handle to the button clicked.
     */
    @IBAction func selectTimerFile(_ sender: NSButton) {
        let filePath = self.getFilePath()
        
        let textField: NSTextField = allTextFields[sender.tag]!
        
        if !filePath.isEmpty {
            textField.stringValue = filePath
        }
    }
    
    
    /**
     View loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        findTextfieldByIndex(view: self.view)
        retrieveUserDefaults()
        
        #if DEBUG
        print("\(#function) - \(URL(fileURLWithPath: #file).lastPathComponent.dropLast(6))")
        #endif
    }
    
    /**
     View will appear.
     */
    override   func viewWillAppear() {
        self.view.window?.titleVisibility = .hidden
        self.view.window?.titlebarAppearsTransparent = true
        
        self.view.window?.styleMask.insert(.fullSizeContentView)
        
        //self.view.window?.styleMask.remove(.closable)
        self.view.window?.styleMask.remove(.fullScreen)
        self.view.window?.styleMask.remove(.miniaturizable)
        self.view.window?.styleMask.remove(.resizable)
    }
    
    override func viewWillDisappear() {
        saveUserDefaults()
        preferenceManager.updateButtonLables()
        
            #if DEBUG
            print("\(#function) - \(URL(fileURLWithPath: #file).lastPathComponent.dropLast(6))")
            #endif
    }
    
    /**
     Find the correct field using the tag value and populate it.
     */
    @IBAction func loadFileNameClicked(_ sender: NSButton) {
        
        let filePath = self.getFilePath()
        let offset = 10
        
        let textField: NSTextField = allTextFields[sender.tag]!
        let labelField: NSTextField = allTextFields[sender.tag + offset]!
        let label = labelField.stringValue
        
        if !filePath.isEmpty {
            textField.stringValue = filePath
        }
        
        if (label.isEmpty) {
            let fileName = NSURL(fileURLWithPath: filePath).deletingPathExtension!.lastPathComponent
            labelField.stringValue = fileName
        }
    }
    
    /**
     Collect all the textfields from view and subviews at load time
     - parameter view: - the view to search
     */
    func findTextfieldByIndex(view: NSView) {
        
        for subview in view.subviews as [NSView] {
            if let textField = subview as? NSTextField {
                allTextFields[textField.tag] = textField
            } else {
                findTextfieldByIndex(view: subview)
            }
        }
    }
    
    /**
     Collect all the textfields from view and subviews
     - parameter view: - the view to search
     - returns: array of NSTextField
     */
    func findTextfield(view: NSView) -> [NSTextField] {
        
        var results = [NSTextField]()
        
        for subview in view.subviews as [NSView] {
            if let textField = subview as? NSTextField {
                results += [textField]
            } else {
                results += findTextfield(view: subview)
            }
        }
        return results
    }
    
    /**
     Get the file path from the selected item.
     - returns: String
     */
    func getFilePath() -> String {
        var filePath = ""
        
        if let url = NSOpenPanel().selectUrl {
            filePath = url.path
        }
        
        return filePath
    }
    
    /**
     Retrieve the user settings. File paths and the default radio.
     Populate the fields and the tableview
     */
    func retrieveUserDefaults() {
        
        for item in allTextFields
        {
            let tag = item.key
            
            // this takes care of timer interval too since it is duplicated as a tag and TimerInterval
            if let filePath = UserDefaults.standard.string(forKey: String(tag)) {
                if tag != 0 { // skip labels
                    allTextFields[tag]!.stringValue = filePath
                }
            }
        }
    }
    
    /**
     Persist the user settings. File paths and the button labels.
     */
    func saveUserDefaults() {
        
        for item in allTextFields
        {
            let tag = item.key
            
            if tag == 0 {
                continue
            }
            
            if allTextFields[tag]!.stringValue.isEmpty
            {
                UserDefaults.standard.set("", forKey: String(tag))
                if tag == 101 {
                    UserDefaults.standard.set("10", forKey: "TimerInterval")
                }
            } else {
                UserDefaults.standard.set(allTextFields[tag]!.stringValue, forKey: String(tag))
                if tag == 101 {
                    UserDefaults.standard.set(allTextFields[tag]!.stringValue, forKey: "TimerInterval")
                }
            }
        }
    }
    
} // end class
