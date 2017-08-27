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
    private var defaultSet = false
    
    // outlets
    @IBOutlet weak var tableViewRadioPicker: NSTableView!
    @IBOutlet weak var buttonDefaultControl: NSButton!
    @IBOutlet weak var buttonConnectControl: NSButton!
    
    // actions
    @IBAction func buttonOk(_ sender: Any) {
        self.dismiss(self)
    }
    
    @IBAction func buttonDefault(_ sender: Any) {
        
        defaultSet = true
    }
    
    // send a message back to the main view controller to connect the radio
    @IBAction func buttonConnect(_ sender: NSButton) {
        if defaultRadio.default == "Yes" {
            preferenceManager.connectToRadio(serialNumber: defaultRadio.nickname)
        }
    }
    
    // generated code
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferenceManager = PreferenceManager()
        
        tableViewRadioPicker.dataSource = self
        tableViewRadioPicker.delegate = self
        
        retrieveUserDefaults()
    }
    
    override func viewWillDisappear() {
        
        saveUserDefaults()
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
        
        if let data = UserDefaults.standard.object(forKey: "defaultRadio") as? NSData {
            defaultRadio = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! (model: String, nickname: String, ipAddress: String, default: String)
            
            buttonConnectControl.isEnabled = true
        }
        
    }
    
    func saveUserDefaults() {
        
        //var dictionary = [String : (model: String, nickname: String, ipAddress: String, default: String)]()
        let allTextField = findTextfield(view: self.view)
        
        // save all on exit
        for txtField in allTextField
        {
            UserDefaults.standard.set(txtField.stringValue, forKey: String(txtField.tag))
        }
        
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: defaultRadio), forKey: "defaultRadio")
    
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
            defaultRadio = availableRadios[tableView.selectedRow]
            
            
            //let selected: Int = tableView.selectedRow
//            let selectedRow: NSTableCellView? = tableView.view(atColumn: 0, row: selected, makeIfNecessary: true) as! NSTableCellView
//            let selectedRowTextField: NSTextField? = selectedRow?.textField
            //selectedRowTextField?.textColor =
            
            
        //let cell = tableView.view(atColumn: 3, row:selected, makeIfNecessary:true)
        
            
            //tableView.editColumn(3, row: selected, with: nil, select: true)
            
//            var cellView: NSTableCellView? = (tableView.view(atColumn: 3, row: selected, makeIfNecessary: true) as? NSTableCellView)
//            if (cellView?.textField?.acceptsFirstResponder)! {
//                cellView?.window?.makeFirstResponder(cellView?.textField)
//                //cellView?.textField?.stringValue = "Yes"
//            }
            
            
            
          
            // now set default to Yes"
            defaultRadio.default = "Yes"
            
            for i in 0..<availableRadios.count {
                if availableRadios[i].nickname == defaultRadio.nickname {
                    availableRadios[i].default = "Yes"
                } else {
                    availableRadios[i].default = "No"
                }
                
            }
            
//            for var radio in availableRadios {
//                if radio.nickname == defaultRadio.nickname {
//                    radio.default = "Yes"
//                }
//            }
            
            tableView.reloadData()
            
            buttonDefaultControl.isEnabled = true
            buttonConnectControl.isEnabled = true
        }
    }
    
//    func getSelectedTextField(tableView: NSTableRowView) {
//        let selected: Int = tableView.selectedRow
//        // Get row at specified index
//        let selectedRow: NSTableCellView? = tableView.view(atColumn: 0, row: selected, makeIfNecessary: true)
//        // Get row's text field
//        let selectedRowTextField: NSTextField? = selectedRow?.textField
//        // Focus on text field to make it auto-editable
//        //window().makeFirstResponder(selectedRowTextField)
//        // Set the keyboard carat to the beginning of the text field
//        selectedRowTextField?.currentEditor()?.selectedRange = NSRange(location: 0, length: 0)
//    }

    
    // to set values use this
//    private func tableView(tableView: NSTableView!, setObjectValue object: AnyObject!, forTableColumn tableColumn: NSTableColumn!, row: Int){
//        
//        var result = ""
//        
//        let columnIdentifier = tableColumn.identifier
//        
//        if columnIdentifier == "model" {
//            result = availableRadios[row].model
//        }
//        if columnIdentifier == "nickname" {
//            result = availableRadios[row].nickname
//        }
//        if columnIdentifier == "ipAddress" {
//            result = availableRadios[row].ipAddress
//        }
//        if columnIdentifier == "default" {
//            result = availableRadios[row].default
//        }
//        //return result
//        
//    }
    
    // ----------------------------------------------------------------------------
    // MARK: RadioManager implementation
    
//    func didDiscoverRadio(discoveredRadios: [(model: String, nickname: String, ipAddress: String, default: String)]) {
//        
//        //DispatchQueue.main.async { [unowned self] in
//            self.availableRadios = discoveredRadios
//            
//            
//            
//        //}
//    }

    
} // end class


