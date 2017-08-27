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
    //var mainViewController: ViewController!
    
    
    
    // Array of available Radios
    var availableRadios = [(model: String, nickname: String, ipAddress: String, default: String)]()
    private var defaultRadio = ""
    private let defaultColumnValue = "" // default column identifier
    
    // outlets
    @IBOutlet weak var tableViewRadioPicker: NSTableView!
    
    // actions
    @IBAction func buttonOk(_ sender: Any) {
        self.dismiss(self)
    }
    
    @IBAction func buttonDefault(_ sender: Any) {
    }
    
    // send a message back to the main view controller to connect the radio
    @IBAction func buttonConnect(_ sender: NSButton) {
        if defaultRadio != "" {
            preferenceManager.connectToRadio(serialNumber: defaultRadio)
        }
        //self.preferenceManagerDelegate?.doConnectRadio(nickname: defaultRadio)
    }
    
    // generated code
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferenceManager = PreferenceManager()
        //mainViewController = ViewController()
        
        //mainViewController.mainViewControllerDelegate = self
        
        tableViewRadioPicker.dataSource = self
        tableViewRadioPicker.delegate = self
        
        
        retrieveUserDefaults()
    }
    
    override func viewWillDisappear() {
        
        let allTextField = findTextfield(view: self.view)
        
        // save all on exit
        for txtField in allTextField
        {
            UserDefaults.standard.set(txtField.stringValue, forKey: String(txtField.tag))
        }
        
       
            
//            for row in 0..<tableViewRadioPicker.numberOfRows {
//                
//                _ = NSIndexPath(forItem: row, inSection: 0)
//                
//                
//                // do what you want with the cell
//                
//            }
        
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
        
        defaultRadio = UserDefaults.standard.string(forKey: "defaultRadio") ?? ""
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


