//
//  RadioPreferences.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/21/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa

// This class shows a preference panel and allows users to select or input
// the audio files they want to use for the voice keyer.
class RadioPreferences: NSViewController {

    // class variables
    var preferenceManager: PreferenceManager!
    
    // outlets
    
    
    // actions
    @IBAction func buttonOk(_ sender: Any) {
        self.dismiss(self)
    }

    // generated code
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        preferenceManager = PreferenceManager()
        
        retrieveUserDefaults()
    }
    
    override func viewWillDisappear() {
        let allTextField = findTextfield(view: self.view)
        
        // save all on exit
        for txtField in allTextField
        {
            UserDefaults.standard.set(txtField.stringValue, forKey: String(txtField.tag))
        }
    }
    
    // actions
  
    // TODO: exception handling
    // find the correct field using the tag value and populate it
    @IBAction func loadFileNameClicked(_ sender: NSButton) {
       
        let filePath = preferenceManager.getFilePath()
        let allTextField = findTextfield(view: self.view)
        
        for txtField in allTextField
        {
            if txtField.tag == sender.tag && !filePath.isEmpty {
                txtField.stringValue = filePath
            }
        }
    }
    
    // collect all the textfields from view and subview
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
    
    // retrieve the user defaults and populate the correct fields
    // TODO: account for multiple profiles
    func retrieveUserDefaults() {
        
        let allTextField = findTextfield(view: self.view)
        
        for txtField in allTextField
        {
            let tag = txtField.tag
            if let filePath = UserDefaults.standard.string(forKey: String(tag)) {
                txtField.stringValue = filePath
            }
        }
    }
    
} // end class
