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


/*
 RadioPreferences.swift
 SDRVoiceKeyer

 Created by Peter Bourget on 2/21/17.
 Copyright © 2019 Peter Bourget W6OP. All rights reserved.
 
 Description: Loads and save the user defaults and settings.
*/

import Cocoa

// This class shows a preference panel and allows users to select or input
// the audio files they want to use for the voice keyer.
class RadioPreferences: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    // class variables
    var preferenceManager: PreferenceManager!
   
    // Array of available Radios from view controller
//    var radios = [(model: String, nickname: String, stationName: String, default: String, serialNumber: String, clientId: String)]()
    // Array of available radios per station name
    var station = [(model: "", nickname: "", stationName: "", default: "", serialNumber: "", clientId: "")]
    private var defaultStation = (model: "", nickname: "", stationName: "", default: "", serialNumber: "", clientId: "")
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
        saveUserDefaults()
        preferenceManager.updateButton()
        self.dismiss(self)
    }
    
    /**
        Save the default radio and reload the tableview.
     */
    @IBAction func buttonDefault(_ sender: Any) {
        
        isDefaultSet = true
        
        saveUserDefaults()
        
        tableViewRadioPicker.reloadData()
        
        buttonConnectControl.isEnabled = true
    }
    
    /**
        Connect the radio in the main view controller by calling delegate in preference manager.
     */
    @IBAction func buttonConnect(_ sender: NSButton) {
        if defaultStation.default == YesNo.Yes.rawValue {
            saveUserDefaults()
            self.dismiss(self)
            preferenceManager.connectToRadio(serialNumber: defaultStation.serialNumber, stationName: defaultStation.stationName, clientId: defaultStation.clientId)
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
    }
    
    // View Will Appear
    override   func viewWillAppear() {
        self.view.window?.titleVisibility = .hidden
        self.view.window?.titlebarAppearsTransparent = true
        
        self.view.window?.styleMask.insert(.fullSizeContentView)
        
        self.view.window?.styleMask.remove(.fullScreen)
        self.view.window?.styleMask.remove(.miniaturizable)
        self.view.window?.styleMask.remove(.resizable)
    }
    
    /**
        Save the user defaults when the view is closed.
     */
    override func viewWillDisappear() {
        
        isDefaultSet = false // don't save radio on exit
        saveUserDefaults()
    }
    
    /**
     
     */
    func buildStationList(radios: [(model: String, nickname: String, stationNames: [String], default: String, serialNumber: String)]) {

        //for radio in radios {
            //for client in radio.stationNames {
               //station.append((model: radio.model, nickname: radio.nickname, stationName: client, default: radio.default, serialNumber: radio.serialNumber))
            //}
        //}
    }
    
    /**
        Retrieve the user settings. File paths and the default radio.
        Populate the fields and the tableview
     */
    func retrieveUserDefaults() {
        
        if let defaults = UserDefaults.standard.dictionary(forKey: radioKey) {
            self.defaultStation.model = defaults["model"] as! String
            self.defaultStation.nickname = defaults["nickname"] as! String
            self.defaultStation.stationName = defaults["stationName"] as! String
            self.defaultStation.default = defaults["default"] as! String
            self.defaultStation.default = defaults["serialNumber"] as! String
        }
        
        for i in 0..<station.count {
            if station[i].nickname == defaultStation.nickname && station[i].model == defaultStation.model && station[i].stationName == defaultStation.stationName {
                station[i].default = YesNo.Yes.rawValue  //YES
            } else {
                station[i].default = YesNo.No.rawValue //NO
            }
        }
        
        // why did this stop working elsewhere
        buttonDefaultControl.isEnabled = true
    }
    
    /**
        Persist the user settings. File paths and the default radio.
     */
    func saveUserDefaults() {
    
        if (station.count > 0) {
            //for client in radios
            defaultStation = station[tableViewRadioPicker.selectedRow]

            if isDefaultSet == true {
                var defaults = [String : String]()
                defaults["model"] = defaultStation.model
                defaults["nickname"] = defaultStation.nickname
                defaults["stationName"] = defaultStation.stationName
                defaults["default"] = YesNo.Yes.rawValue
                defaults["serialNumber"] = defaultStation.serialNumber

                UserDefaults.standard.set(defaults, forKey: radioKey)

                defaultStation.default = YesNo.Yes.rawValue

                for i in 0..<station.count {
                    if station[i].nickname == defaultStation.nickname && station[i].model == defaultStation.model && station[i].stationName == defaultStation.stationName {
                        station[i].default = YesNo.Yes.rawValue
                    } else {
                        station[i].default = YesNo.No.rawValue
                    }
                }
            }
        }
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
        //print ("rows: ")
        return station.count
    }
    
    // MARK: - NSTableView Delegate methods ----------------------------------------------------------------------------
    
    /**
     Tableview view delegate method.
     - parameter tableView: a Tableview
     - parameter tableColumn: a tableColumn
     - row: the row number
     - returns: an NSView
     */
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        var result = ""
        
        let columnIdentifier = tableColumn?.identifier
        
        // swift 4
        if columnIdentifier!.rawValue == "model" {
            result = station[row].model
        }
        if columnIdentifier!.rawValue == "nickname" {
            result = station[row].nickname
        }
        if columnIdentifier!.rawValue == "station" {
            //result = radios[row].stationName
        }
        if columnIdentifier!.rawValue == "default" {
            result = station[row].default
        }
        
        return result
    }
    
    /**
        Tableview view selection change method. Enable the buttons on the view.
        - parameter notification: a notification
     */
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        if (notification.object as? NSTableView) != nil {
            buttonDefaultControl.isEnabled = true
            buttonConnectControl.isEnabled = true
        }
    }
    
} // end class


