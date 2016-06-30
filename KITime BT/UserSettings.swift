//
//  SharedSettings.swift
//  KITime BT
//
//  Created by Drew Dunne on 6/9/16.
//  Copyright © 2016 Know Innovation. All rights reserved.
//

import UIKit

class UserSettings: NSObject {
    
    // Settings
    var autoAccept: Bool = false
    var autoFull: Bool = false
    
    override init() {
        super.init()
        autoAccept = false
        autoFull = false
    }
    
    class func sharedSettings() -> UserSettings {
        return settingsSingleton
    }

}

var settingsSingleton = UserSettings()