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
    @IBOutlet weak var inviteButton:UIButton!
    @IBOutlet weak var timerPicker: UIPickerView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var buttonContainerView: UIView!
    @IBOutlet weak var stopTypeSelector: UISegmentedControl!
    
    var minsLabel: UILabel!
    var secsLabel: UILabel!
    
//    var timeData: TimeData = TimeData()
    
    var displayTime: Double = 0
    var startTime: NSTimeInterval = -1
    var stopType: StopType = .Hard
    var duration: Double = 300
    var timerIsRunning: Bool = false
    var timerFinished: Bool = false
    var timerCancelled: Bool = false
    
    var timeUponExit: NSDate!
    
    var timer = NSTimer()
    
    let timeService = TimeServiceManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        timeService.delegate = self
        
        startButton.layer.cornerRadius = 10;
        pauseButton.layer.cornerRadius = 10;
        cancelButton.layer.cornerRadius = 10;
        inviteButton.layer.cornerRadius = 10;
        
        minsLabel = UILabel(frame: CGRectMake(self.view.frame.size.width/2-42, 162/2-11, 44, 22))
        minsLabel.font = UIFont.systemFontOfSize(17.0)
        minsLabel.text = "mins"
        timerPicker.addSubview(minsLabel)
        
        secsLabel = UILabel(frame: CGRectMake(self.view.frame.size.width/2+48, 162/2-11, 44, 22))
        secsLabel.font = UIFont.systemFontOfSize(17.0)
        secsLabel.text = "secs"
        timerPicker.addSubview(secsLabel)
        
        timerPicker.selectRow(5, inComponent: 0, animated: false)
        pauseButton.hidden = true
        cancelButton.hidden = true
        
        //Update the view for rotation and add listener for rotation
        self.rotated()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TimerViewController.rotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startPressed() {
        if timerCancelled && !timerIsRunning {
            // Fresh timer, set duration to picker
            duration = getTimeFromPicker()
            startTime = NSDate.timeIntervalSinceReferenceDate()
            timeService.sendTimeData(["action":"start", "startTime": startTime, "duration": duration])
            start()
        } else if !timerCancelled && !timerIsRunning {
            // Paused, should resume
            startTime = NSDate.timeIntervalSinceReferenceDate()
            timeService.sendTimeData(["action":"start", "startTime": startTime, "duration": duration])
            start()
        }
    }
    
    @IBAction func pausePressed() {
        // Only pause if running
        if timerIsRunning {
            pause()
            timeService.sendTimeData(["action":"pause", "duration": duration])
        }
    }
    
    @IBAction func cancelPressed() {
        if !timerCancelled && !timerIsRunning {
            cancel()
            timeService.sendTimeData(["action":"cancel"])
        }
    }
    
    @IBAction func changedStopType(sender: UISegmentedControl) {
        stopType = StopType(rawValue: sender.selectedSegmentIndex)!
        timeService.sendTimeData(["action":"changeStopType", "stopType": stopType.rawValue])
    }
    
    @IBAction func invitePeers(sender: AnyObject) {
        let inviteView = MCBrowserViewController.init(serviceType: timeService.serviceType, session: timeService.session);
        inviteView.delegate = self
        self.presentViewController(inviteView, animated: true, completion: nil)
    }
    
    func start() {
        // Only if the timer is not already running should something happen
        if !timerIsRunning {
            NSLog("Starting")
            timerIsRunning = true
            displayTime = duration
            animateState()
            updateButtons()
            
            // Calculate the delay from when the start button was actually pushed
            let numSecsPassed = NSDate.timeIntervalSinceReferenceDate()
            let diff = numSecsPassed - startTime
            var delay = 1.0 - diff
            //If coming in while started update the displayTime to match the actual based on how much has passed
            if diff > 1.0 {
                delay = 1.0 - ((numSecsPassed - floor(numSecsPassed)) - (startTime - floor(startTime)))
                displayTime -= floor(numSecsPassed) - floor(startTime)
                
            }
            
            // It's possible the delay caused the timer to end, then we need to finish the timer
            if checkForFinish() { return }
            
            // Otherwise update the label
            updateLabel()
            
            if timerIsRunning {
                // Run the delayed time
                NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: #selector(TimerViewController.postDelay), userInfo: nil, repeats: false)
            }
        }
    }
    
    func pause() {
        // Only pause if the timer is running
        if timerIsRunning {
            timer.invalidate()
            timerIsRunning = false
            
            //Calculate the new duration based on how much time passed
            NSLog("%.2f", NSDate.timeIntervalSinceReferenceDate() - startTime)
//            duration -= (floor(NSDate.timeIntervalSinceReferenceDate()) - floor(startTime))
//            displayTime = duration
            duration = displayTime
            
            updateLabel()
            updateButtons()
        }
    }
    
    func cancel() {
        // Only allow canceled when canceled
        if !timerIsRunning && !timerCancelled {
            timer.invalidate()
            timerIsRunning = false
            timerFinished = false
            timerCancelled = true
            
            updateButtons()
            updateLabel()
            animateState()
        }
    }
    
    // Checks if the clock needs to be stopped, then stops it
    func checkForFinish() -> Bool {
        if displayTime <= 0 && stopType == .Hard {
            finishTimer()
            return true
        }
        return false
    }
    
    // Upon timer completion, this runs
    func finishTimer() {
        timer.invalidate()
        timerFinished = true
        timerIsRunning = false
        timerCancelled = false
        
        updateButtons()
        updateLabel()
        
        // Play sound here
    }
    
    func postDelay() {
        if checkForFinish() { return }
        displayTime -= 1 //Bring timer count down again
        updateLabel()
        if timerIsRunning {
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(TimerViewController.updateTime), userInfo: nil, repeats: true) //Start the repetitive timer 1 second apart each
        }
    }
    
    // Runs during the timer loop
    func updateTime() {
        if checkForFinish() { return }
        displayTime -= 1 //Count down the time
        self.updateLabel() //Update the label
    }
    
    func updateLabel() {
        if displayTime >= 0 {
            if displayTime < 60 {
                timerLabel.textColor = UIColor.redColor()
            } else if displayTime < 120 {
                timerLabel.textColor = UIColor.orangeColor()
            } else {
                timerLabel.textColor = UIColor.blackColor()
            }
            var timeToShow: Double!;
            if !timerIsRunning && timerCancelled {
                timeToShow = getTimeFromPicker()
            } else {
                timeToShow = displayTime
            }
            let (m,s) = secondsToMinutesSeconds(Int(timeToShow))
            self.timerLabel.text = String(format: "%02d:%02d",m,s)
            if timerFinished {
                timerLabel.textColor = UIColor.redColor()
                self.timerLabel.text = String("00:00")
            }
        } else {
            timerLabel.textColor = UIColor.redColor()
            var timeToShow: Double!
            if timerCancelled {
                timeToShow = getTimeFromPicker()
            } else {
                timeToShow = displayTime
            }
            let (m,s) = secondsToMinutesSeconds(Int(abs(timeToShow)))
            self.timerLabel.text = String(format: "+%02d:%02d",m,s)
            if timerFinished {
                timerLabel.textColor = UIColor.redColor()
                self.timerLabel.text = String("00:00")
            }
        }
    }
    
    func updateButtons() {
        if timerIsRunning && !timerCancelled && !timerFinished {
            cancelButton.hidden = true
            startButton.hidden = true
            inviteButton.hidden = true
            pauseButton.hidden = false
        } else if timerCancelled && !timerIsRunning && !timerFinished {
            cancelButton.hidden = true
            startButton.hidden = false
            inviteButton.hidden = false
            pauseButton.hidden = true
        } else if timerFinished && !timerCancelled && !timerIsRunning {
            cancelButton.hidden = true
            startButton.hidden = true
            inviteButton.hidden = true
            pauseButton.hidden = true
        } else if !timerFinished && !timerCancelled && !timerIsRunning {
            cancelButton.hidden = false
            startButton.hidden = false
            inviteButton.hidden = false
            pauseButton.hidden = true
        }
    }
    
    //Get the total duration (seconds) from the picker
    func getTimeFromPicker() -> Double {
        let minsToSecs = timerPicker.selectedRowInComponent(0)*60
        let secs = timerPicker.selectedRowInComponent(1)
        let time = Double(minsToSecs + secs)
        return time
    }
    
    //Convert the seconds into the minutes time and seconds time
    func secondsToMinutesSeconds (seconds : Int) -> (Int, Int) {
        return ( (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    // Fades picker/timer in and out based on current state
    func animateState() {
        NSLog("Animating")
        if timerIsRunning {
            UIView.animateWithDuration(0.5) {
                self.timerPicker.alpha = 0.0
                self.timerLabel.alpha = 1.0
            }
        } else if timerCancelled {
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
        duration = getTimeFromPicker()
        timeService.sendTimeData(["action":"selectDuration", "duration": duration])
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
    
    func changesReceived(data: Dictionary<String, AnyObject>) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            NSLog("Changes received")
            switch data["action"] as! String {
            case "start":
                self.startTime = data["startTime"] as! NSTimeInterval
                self.duration = data["duration"] as! Double
                self.start()
            case "pause":
                self.duration = data["duration"] as! Double
                self.pause()
            case "cancel":
                self.cancel()
            case "changeStopType":
                // No change in time or what not, just hard/soft stop
                self.stopType = StopType(rawValue: data["stopType"] as! Int)!
                self.stopTypeSelector.selectedSegmentIndex = self.stopType.rawValue
            case "selectDuration":
                let (min, sec) = self.secondsToMinutesSeconds(data["duration"] as! Int)
                self.timerPicker.selectRow(min, inComponent: 0, animated: true)
                self.timerPicker.selectRow(sec, inComponent: 1, animated: true)
            default:
                break
            }
        }
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
