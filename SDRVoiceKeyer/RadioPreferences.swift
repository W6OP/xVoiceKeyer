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
    private let radioKey = "defaultRadio"
    private var isDefaultSet = false
    
    // MARK: outlets
    @IBOutlet weak var tableViewRadioPicker: NSTableView!
    @IBOutlet weak var buttonDefaultControl: NSButton!
    @IBOutlet weak var buttonConnectControl: NSButton!
    
    // MARK: actions
    
    /**
        Close this view.
     */
    @IBAction func buttonOk(_ sender: Any) {
        self.dismiss(self)
    }
    
    /**
        Save the default radio and reload the tableview.
     */
    @IBAction func buttonDefault(_ sender: Any) {
        
        isDefaultSet = true
        
        saveUserDefaults()
        
        tableViewRadioPicker.reloadData()
    }
    
    /**
        Connect the radio in the main view controller by calling delegate in preference manager.
     */
    @IBAction func buttonConnect(_ sender: NSButton) {
        if defaultRadio.default == YesNo.Yes.rawValue {
            self.dismiss(self)
            preferenceManager.connectToRadio(serialNumber: defaultRadio.nickname)
        }
    }
    
    /**
        Find the correct field using the tag value and populate it.
     */
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
    
    /**
        Retrieve the user settings when the view loads.
        Set the datasource and delegate for the tableview.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        retrieveUserDefaults()
        
        tableViewRadioPicker.dataSource = self
        tableViewRadioPicker.delegate = self
        
        // double click to connect
        //tableViewRadioPicker.doubleAction = #selector(RadioPreferencesViewController.selectButton(_:))
  
    }
    
    /**
        Save the user defaults when the view is closed.
     */
    override func viewWillDisappear() {
        
        isDefaultSet = false // don't save radio on exit
        saveUserDefaults()
    }
    
    /**
        Retrieve the user settings. File paths and the default radio.
        Populate the fields and the tableview
     */
    func retrieveUserDefaults() {
        
        let allTextField = findTextfield(view: self.view)
        
        for txtField in allTextField
        {
            let tag = txtField.tag
            if let filePath = UserDefaults.standard.string(forKey: String(tag)) {
                txtField.stringValue = filePath
            }
        }
        
        if let def = UserDefaults.standard.dictionary(forKey: radioKey) {
            self.defaultRadio.model = def["model"] as! String
            self.defaultRadio.nickname = def["nickname"] as! String
            self.defaultRadio.ipAddress = def["ipAddress"] as! String
            self.defaultRadio.default = def["default"] as! String
        }
        
        for i in 0..<availableRadios.count {
            if availableRadios[i].nickname == defaultRadio.nickname && availableRadios[i].model == defaultRadio.model {
                availableRadios[i].default = YesNo.Yes.rawValue
            } else {
                availableRadios[i].default = YesNo.No.rawValue
            }
        }
        
        //tableViewRadioPicker.selectRow(0)
        
    }
    
    /**
        Persist the user settings. File paths and the default radio.
     */
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
            def["model"] = defaultRadio.model
            def["nickname"] = defaultRadio.nickname
            def["ipAddress"] = defaultRadio.ipAddress
            def["default"] = YesNo.Yes.rawValue
            
            UserDefaults.standard.set(def, forKey: radioKey)
            
            for i in 0..<availableRadios.count {
                if availableRadios[i].nickname == defaultRadio.nickname && availableRadios[i].model == defaultRadio.model {
                    availableRadios[i].default = YesNo.Yes.rawValue
                } else {
                    availableRadios[i].default = YesNo.No.rawValue
                }
            }
        }
    }
    
    
    /**
        Collect all the textfields from view and subviews
        - parameter view: - the view to search
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
    
   
    // ----------------------------------------------------------------------------
    // MARK: - NSTableView DataSource methods
    
    /**
        Tableview numberOfRows delegate method.
        - parameter aTableView: the Tableview
        - returns: number of rows
     */
    func numberOfRows(in aTableView: NSTableView) -> Int {
        
        // get the number of rows
        print ("rows: ")
        return availableRadios.count
    }
    
    // ----------------------------------------------------------------------------
    // MARK: - NSTableView Delegate methods
    
    ///
    ///
    /// - Parameters:
    ///   - tableView: the Tableview
    ///   - tableColumn: a Tablecolumn
    ///   - row: the row number
    /// - Returns: an NSView
    ///
    
    /**
     Tableview view delegate method.
     - parameter tableView: a Tableview
     - parameter tableColumn: a tableColumn
     - returns: an NSView
     */
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
    
//    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
//        
//        //tableView.deselectAll(<#T##sender: Any?##Any?#>)
//        
//    }
    
    /**
        Tableview view selection change method. Enable the buttons on the view.
        - parameter notification: a notification
     */
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        if (notification.object as? NSTableView) != nil {
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


