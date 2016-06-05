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
    @IBOutlet weak var stopTypeSelector: UISegmentedControl!
    
    var minsLabel: UILabel!
    var secsLabel: UILabel!
    
    var timeData: TimeData = TimeData()
    
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
    
    @IBAction func startPressed() {
        
        
        // Commit and send
        timeData.timeChange = true
        commitChanges()
        timeService.sendTimeData(timeData)
    }
    
    @IBAction func pausePressed() {
        
        
        // Commit and send
        timeData.timeChange = true
        commitChanges()
        timeService.sendTimeData(timeData)
    }
    
    @IBAction func cancelPressed() {
        
        // Commit and send
        timeData.timeChange = true
        commitChanges()
        timeService.sendTimeData(timeData)
    }
    
    @IBAction func changedStopType(sender: UISegmentedControl) {
        timeData.stopType = StopType(rawValue: sender.selectedSegmentIndex)!
        
        // Not time change, just commit and send
        commitChanges()
        timeService.sendTimeData(timeData)
    }
    
    @IBAction func invitePeers(sender: AnyObject) {
        let inviteView = MCBrowserViewController.init(serviceType: timeService.serviceType, session: timeService.session);
        inviteView.delegate = self
        self.presentViewController(inviteView, animated: true, completion: nil)
    }
    
    // Observes changes to the TimeData, then applies those changes to the app
    func commitChanges() {
        if timeData.timeChange == true {
            
        } else {
            // No change in time or what not, just hard/soft stop
            NSLog("%d", timeData.stopType.rawValue)
            stopTypeSelector.selectedSegmentIndex = timeData.stopType.rawValue
        }
        timeData.timeChange = false
    }
    
    // Runs during the timer loop
    func updateTime() {
        if timeData.timer <= 0 && timeData.stopType == .Hard {
            self.finishTimer()
        }
        self.updateLabel() //Update the label
        timeData.timer -= 1 //Count down the time
    }
    
    // Upon timer completion, this runs
    func finishTimer() {
        
    }
    
    func updateLabel() {
        
    }
    
    // Fades picker/timer in and out based on current state
    func animateState() {
        if timeData.timeState == .Running {
            UIView.animateWithDuration(0.5) {
                self.timerPicker.alpha = 0.0
                self.timerLabel.alpha = 1.0
            }
        } else if timeData.timeState == .Stopped {
            UIView.animateWithDuration(0.5) {
                self.timerPicker.alpha = 1.0
                self.timerLabel.alpha = 0.0
            }
        } else {
            self.timerPicker.alpha = 0.0
            self.timerLabel.alpha = 1.0
        }
    }
    
    // Changes view based on rotation of device
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
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func timeDataReceived(data: TimeData) {
        self.timeData = data
        commitChanges()
    }
    
}

extension TimerViewController: MCBrowserViewControllerDelegate {
    
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
