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
        autoAcceptSwitch.isOn = UserSettings.sharedSettings().autoAccept
        autoFullscreenSwitch.isOn = UserSettings.sharedSettings().autoFull
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func done() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func autoAcceptSwitchPressed() {
        UserSettings.sharedSettings().autoAccept = autoAcceptSwitch.isOn
    }
    
    @IBAction func autoFullSwitchPressed() {
        UserSettings.sharedSettings().autoFull = autoFullscreenSwitch.isOn
    }

}
