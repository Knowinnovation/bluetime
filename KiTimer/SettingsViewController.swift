//
//  SettingsViewController.swift
//  KITime BT
//
//  Created by Drew Dunne on 6/9/16.
//  Copyright © 2016 Know Innovation. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var autoAcceptSwitch: UISwitch!
    @IBOutlet weak var autoFullscreenSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        autoAcceptSwitch.on = UserSettings.sharedSettings().autoAccept
        autoFullscreenSwitch.on = UserSettings.sharedSettings().autoFull
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func done() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func autoAcceptSwitchPressed() {
        UserSettings.sharedSettings().autoAccept = autoAcceptSwitch.on
    }
    
    @IBAction func autoFullSwitchPressed() {
        UserSettings.sharedSettings().autoFull = autoFullscreenSwitch.on
    }

}
