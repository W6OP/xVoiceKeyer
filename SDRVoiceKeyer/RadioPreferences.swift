//
//  RadioPreferences.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/21/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa

class RadioPreferences: NSViewController {

    var preferenceManager: PreferenceManager!
    
    // generated code
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        preferenceManager = PreferenceManager()
    }
    
    // actions
  
    @IBAction func loadFileNameClicked(_ sender: NSButton) {
       
        let filePath = preferenceManager.getFilePath()
        let allTextField = getTextfield(view: self.view)
        
        for txtField in allTextField
        {
            if txtField.tag == sender.tag && !filePath.isEmpty {
                txtField.stringValue = filePath
            }
        }
    }
    
    /** extract all the textfield from view **/
    func getTextfield(view: NSView) -> [NSTextField] {
        var results = [NSTextField]()
        for subview in view.subviews as [NSView] {
            if let textField = subview as? NSTextField {
                results += [textField]
            } else {
                results += getTextfield(view: subview)
            }
        }
        return results
    }
    
    // outlets
    
    @IBOutlet weak var textFilePath: NSTextField!
    
    @IBAction func buttonOk(_ sender: Any) {
        self.dismiss(self)
    }
} // end class
