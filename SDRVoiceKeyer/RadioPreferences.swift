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
class RadioPreferences: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    // class variables
    var preferenceManager: PreferenceManager!
   
    
    // Array of available Radios
    var availableRadios = [(model: String, nickname: String, ipAddress: String, default: String)]()
    private var defaultRadio = (model: "", nickname: "", ipAddress: "", default: "")
    private var radioKey = [String : String]()
    private var isDefaultSet = false
    
    // MARK: outlets
    @IBOutlet weak var tableViewRadioPicker: NSTableView!
    @IBOutlet weak var buttonDefaultControl: NSButton!
    @IBOutlet weak var buttonConnectControl: NSButton!
    
     // MARK: actions
    @IBAction func buttonOk(_ sender: Any) {
        self.dismiss(self)
    }
    
    @IBAction func buttonDefault(_ sender: Any) {
        
        isDefaultSet = true
        defaultRadio.default = "Yes"
        
        saveUserDefaults()
        
        tableViewRadioPicker.reloadData()
    }
    
    // connect the radio in the main view controller by caling delegate in preference manager
    // should be able to connect to any radio
    @IBAction func buttonConnect(_ sender: NSButton) {
        if defaultRadio.default == "Yes" {
            self.dismiss(self)
            preferenceManager.connectToRadio(serialNumber: defaultRadio.nickname)
        }
    }
    
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

    
    // MARK: generated code
    
    // retrive the user defaults when the view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
        retrieveUserDefaults()
        
        tableViewRadioPicker.dataSource = self
        tableViewRadioPicker.delegate = self
        
        
    }
    
    // save the user defaults when the view is closed
    override func viewWillDisappear() {
        saveUserDefaults()
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
        
        // UserDefaults.standard.set(nil, forKey: "defaultRadio")
        
        if let nickname = UserDefaults.standard.string(forKey: "defaultRadio") {
            defaultRadio.nickname = nickname
        }

        for i in 0..<availableRadios.count {
            if availableRadios[i].nickname == defaultRadio.nickname && availableRadios[i].model == defaultRadio.model {
                availableRadios[i].default = "Yes"
            } else {
                availableRadios[i].default = "No"
            }
            
        }

    }
    
    // persist the user defaults
    func saveUserDefaults() {
        
        let allTextField = findTextfield(view: self.view)
        
        // save all on exit
        for txtField in allTextField
        {
            UserDefaults.standard.set(txtField.stringValue, forKey: String(txtField.tag))
        }
        
        defaultRadio = availableRadios[tableViewRadioPicker.selectedRow]
        
        if isDefaultSet == true {
            var def = [String : String]()
            def["madel"] = defaultRadio.model
            def["nickname"] = defaultRadio.nickname
            def["ipAddress"] = defaultRadio.ipAddress
            def["default"] = defaultRadio.default
            
            UserDefaults.standard.set(def, forKey: "defaultRadio")
        }
        
        for i in 0..<availableRadios.count {
            if availableRadios[i].nickname == defaultRadio.nickname && availableRadios[i].model == defaultRadio.model {
                availableRadios[i].default = "Yes"
            } else {
                availableRadios[i].default = "No"
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
    
   
    // ----------------------------------------------------------------------------
    // MARK: - NSTableView DataSource methods
    
    /// Tableview numberOfRows delegate method
    ///
    /// - Parameter aTableView: the Tableview
    /// - Returns: number of rows
    ///
    func numberOfRows(in aTableView: NSTableView) -> Int {
        
        // get the number of rows
        print ("rows: ")
        return availableRadios.count
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - NSTableView Delegate methods
    
    /// Tableview view delegate method
    ///
    /// - Parameters:
    ///   - tableView: the Tableview
    ///   - tableColumn: a Tablecolumn
    ///   - row: the row number
    /// - Returns: an NSView
    ///
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        var result = ""
        
        let columnIdentifier = tableColumn?.identifier
        
        if columnIdentifier == "model" {
            result = availableRadios[row].model
        }
        if columnIdentifier == "nickname" {
            result = availableRadios[row].nickname
        }
        if columnIdentifier == "ipAddress" {
            result = availableRadios[row].ipAddress
        }
        if columnIdentifier == "default" {
            result = availableRadios[row].default
        }
        
        return result
    }
    
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        if let tableView = notification.object as? NSTableView {
//            defaultRadio = availableRadios[tableView.selectedRow]
//            
//            // now set default to Yes"
//            defaultRadio.default = "Yes"
//            
//            if isDefaultSet == true {
//                for i in 0..<availableRadios.count {
//                    if availableRadios[i].nickname == defaultRadio.nickname && availableRadios[i].model == defaultRadio.model {
//                        availableRadios[i].default = "Yes"
//                    } else {
//                        availableRadios[i].default = "No"
//                    }
//                    
//                }
//            }
            
            
            //tableView.reloadData()
            
            buttonDefaultControl.isEnabled = true
            buttonConnectControl.isEnabled = true
        }
    }
    
} // end class


