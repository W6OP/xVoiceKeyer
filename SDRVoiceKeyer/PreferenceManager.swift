//
//  PreferenceManager.swift
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/23/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

import Cocoa

// http://stackoverflow.com/questions/28008262/detailed-instruction-on-use-of-nsopenpanel
extension NSOpenPanel {
    var selectUrl: URL? {
        title = "Select File"
        allowsMultipleSelection = false
        canChooseDirectories = false
        canChooseFiles = true
        canCreateDirectories = false
        allowedFileTypes = ["wav"]  // to allow only images, just comment out this line to allow any file type to be selected
        return runModal() == NSFileHandlingPanelOKButton ? urls.first : nil
    }
}

class PreferenceManager: NSObject {
    
    // TODO: Make sure exception handling works
    override init() {
        
    }
    
    internal func getFilePath() -> String {
        var filePath = ""
        
        if let url = NSOpenPanel().selectUrl {
            filePath = url.path
        }
        
        return filePath
    }
    
//    internal func getFilePath() -> String {
//        var filePath = ""
//        
//        let panel = NSOpenPanel()
//        // This method displays the panel and returns immediately.
//        // The completion handler is called when the user selects an
//        // item or cancels the panel.
//        panel.begin(completionHandler: {(_ result: Int) -> Void in
//            if result == NSFileHandlingPanelOKButton {
//                let theDoc: URL? = panel.urls[0]
//                print(theDoc?.absoluteURL) // this gives the file path
//                filePath = String(describing: theDoc?.absoluteURL)
//            }
//        })
//        
//            return filePath
//       
//    }

} // end class
