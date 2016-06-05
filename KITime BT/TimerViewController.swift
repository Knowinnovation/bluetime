//
//  TimerViewController.swift
//  KITime BT
//
//  Created by Drew Dunne on 5/30/16.
//  Copyright © 2016 Know Innovation. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class TimerViewController: UIViewController {
    
    @IBOutlet weak var startButton:UIButton!
    @IBOutlet weak var pauseButton:UIButton!
    @IBOutlet weak var cancelButton:UIButton!
    @IBOutlet weak var timerPicker: UIPickerView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var buttonContainerView: UIView!
    
    var minsLabel: UILabel!
    var secsLabel: UILabel!
    
    var time: NSInteger = 300
    var startTime: NSTimeInterval!
    var timeState: TimerState = .Stopped
    var stopType: StopType = .Hard
    
    //The timer variable to reference for invalidation
    var timer = NSTimer()
    
    let timeService = TimeServiceManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        timeService.delegate = self
        
        startButton.layer.cornerRadius = 10;
        pauseButton.layer.cornerRadius = 10;
        cancelButton.layer.cornerRadius = 10;
        
        minsLabel = UILabel(frame: CGRectMake(self.view.frame.size.width/2-42, 162/2-11, 44, 22))
        minsLabel.font = UIFont.systemFontOfSize(17.0)
        minsLabel.text = "mins"
        timerPicker.addSubview(minsLabel)
        
        secsLabel = UILabel(frame: CGRectMake(self.view.frame.size.width/2+48, 162/2-11, 44, 22))
        secsLabel.font = UIFont.systemFontOfSize(17.0)
        secsLabel.text = "secs"
        timerPicker.addSubview(secsLabel)
        
        //Update the view for rotation and add listener for rotation
        self.rotated()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TimerViewController.rotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func invitePeers(sender: AnyObject) {
        let inviteView = MCBrowserViewController.init(serviceType: timeService.serviceType, session: timeService.session);
        inviteView.delegate = self
        self.presentViewController(inviteView, animated: true, completion: nil)
    }
    
    func rotated() {
        minsLabel.frame = CGRectMake(self.view.frame.size.width/2-42, 162/2-11, 44, 22)
        secsLabel.frame = CGRectMake(self.view.frame.size.width/2+48, 162/2-11, 44, 22)
        if self.view.frame.size.height <= 320 {
            var newFrame = startButton.frame
            newFrame.size.height = 75
            startButton.frame = newFrame
            pauseButton.frame = newFrame
        } else {
            var newFrame = startButton.frame
            newFrame.size.height = 90
            startButton.frame = newFrame
            pauseButton.frame = newFrame
        }
//        startButton.layer.cornerRadius = startButton.bounds.size.height/2
    }
    
}

extension TimerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 60
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row)
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 1 {
            if row == 0 && pickerView.selectedRowInComponent(0) == 0 {
                pickerView.selectRow(1, inComponent: 1, animated: true)
            }
        } else {
            if row == 0 && pickerView.selectedRowInComponent(1) == 0 {
                pickerView.selectRow(1, inComponent: 0, animated: true)
            }
        }
        //If in control of timer, post the value of the picker to firebase
//        if inControl {
//            timeSelectorRef.setValue(getTimeFromPicker())
//        }
    }
    
    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component == 1 {
            return 120
        }
        return 50
    }
}

extension TimerViewController: TimeServiceManagerDelegate {
    func foundPeer() {
        
    }
    
    func lostPeer() {
        
    }
    
    func invitationWasReceived(fromPeer: String) {
        let alert = UIAlertController(title: "", message: "\(fromPeer) wants to chat with you.", preferredStyle: UIAlertControllerStyle.Alert)
        
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            self.timeService.invitationHandler?(true, self.timeService.session)
        }
        
        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
            self.timeService.invitationHandler?(false, self.timeService.session)
        }
        
        alert.addAction(acceptAction)
        alert.addAction(declineAction)
    }
    
    func timeDataChanged(data: TimeData) {
        
    }
    
}

extension TimerViewController: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        NSLog("%@", "Finished")
//        for (_, aPeer) in timeService.foundPeers.enumerate() {
//            browserViewController.browser?.invitePeer(aPeer, toSession: timeService.session, withContext: nil, timeout: 10)
//
//        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        NSLog("%@", "Cancelled")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
