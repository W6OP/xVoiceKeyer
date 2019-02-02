//
//  FilePreferences.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/2/19.
//  Copyright © 2019 Peter Bourget. All rights reserved.
//

import Cocoa

class FilePreferences: NSViewController, NSTextFieldDelegate {

    // used to limit number of characters in a text field
    @IBOutlet weak var buttonLabelField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.buttonLabelField.delegate = self
    }
    
    let TEXT_FIELD_LIMIT = 5
    func textField(textField: NSTextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        return (textField.stringValue.utf16.count ) + string.utf16.count - range.length <= TEXT_FIELD_LIMIT
    }
    
}
