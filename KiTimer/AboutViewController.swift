//
//  AboutViewController.swift
//  KITime BT
//
//  Created by Drew Dunne on 6/20/16.
//  Copyright © 2016 Know Innovation. All rights reserved.
//

import UIKit

class AboutViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 1 && (indexPath as NSIndexPath).row == 1 {
            // Open Website
            UIApplication.shared.openURL(URL(string: "http://knowinnovation.com")!)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

}
