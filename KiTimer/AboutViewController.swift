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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 && indexPath.row == 1 {
            // Open Website
            UIApplication.sharedApplication().openURL(NSURL(string: "http://knowinnovation.com")!)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }

}
