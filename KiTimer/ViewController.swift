//
//  ViewController.swift
//  KITime BT
//
//  Created by Drew Dunne on 5/30/16.
//  Copyright © 2016 Know Innovation. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import AVFoundation
import WatchConnectivity

enum StopType: Int {
    case Hard = 0
    case Soft = 1
}

class ViewController: UIViewController {
    
    @IBOutlet weak var startButton:UIButton!
    @IBOutlet weak var pauseButton:UIButton!
    @IBOutlet weak var cancelButton:UIButton!
    @IBOutlet weak var inviteButton:UIButton!
    @IBOutlet weak var connectedIcon:UIImageView!
    @IBOutlet weak var settingsButton:UIButton!
    @IBOutlet weak var timerPicker: UIPickerView!
    @IBOutlet weak var fullscreenButton:UIButton!
    @IBOutlet weak var buttonContainerView: UIView!
    @IBOutlet weak var stopTypeSelector: UISegmentedControl!
    @IBOutlet weak var fullscreenView: UIView!
    
    @IBOutlet weak var timerLabel: UITimerLabel!
    @IBOutlet weak var fullscreenLabel: UITimerLabel!
    
    var minsLabel: UILabel!
    var secsLabel: UILabel!
    
    var isFullscreen: Bool = false
    var stopType: StopType = .Hard
    
    var elapsedTime: NSTimeInterval = 0
    var startTime: NSTimeInterval = -1
    var pauseTime: NSTimeInterval = -1
    var duration: Double = 300
    
    var timerIsRunning: Bool = false
    var timerFinished: Bool = false
    var timerCancelled: Bool = true
    
    var openFromTerm: Bool = true
    
    let timeService = TimeServiceManager()
    
    var audioPlayer: AVAudioPlayer!
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }
    
    var timerDoneAlert: UIAlertController?
    
    lazy var connectingAlert: UIAlertController = {
        var alert = UIAlertController(title: "Connecting", message: "\n\n\n", preferredStyle: UIAlertControllerStyle.Alert)
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        spinner.center = CGPointMake(130.5, 65.5);
        spinner.color = UIColor.blackColor();
        spinner.startAnimating();
        alert.view.addSubview(spinner)
        return alert
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        timeService.delegate = self
        timerLabel.delegate = self
        fullscreenLabel.delegate = self
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        startButton.layer.cornerRadius = 10;
        pauseButton.layer.cornerRadius = 10;
        cancelButton.layer.cornerRadius = 10;
        
        minsLabel = UILabel(frame: CGRectMake(self.view.frame.size.width/2-40, self.timerPicker.frame.height/2-11, 44, 22))
        minsLabel.font = UIFont.systemFontOfSize(17.0)
        minsLabel.text = "mins"
        timerPicker.addSubview(minsLabel)
        
        secsLabel = UILabel(frame: CGRectMake(self.view.frame.size.width/2+50, self.timerPicker.frame.height/2-11, 44, 22))
        secsLabel.font = UIFont.systemFontOfSize(17.0)
        secsLabel.text = "secs"
        timerPicker.addSubview(secsLabel)
        
        duration = UserSettings.sharedSettings().lastDuration
        if duration == 0 {
            duration = 300
        }
        let (min, sec) = secondsToMinutesSeconds(Int(duration))
        timerPicker.selectRow(min, inComponent: 0, animated: false)
        timerPicker.selectRow(sec, inComponent: 1, animated: false)
        pauseButton.hidden = true
        cancelButton.hidden = true
        
        fullscreenView.hidden = true
        fullscreenLabel.adjustsFontSizeToFitWidth = true
        
        timerLabel.setDate(NSDate(timeIntervalSinceNow: duration-elapsedTime))
        fullscreenLabel.setDate(NSDate(timeIntervalSinceNow: duration-elapsedTime))
        
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
        }
        
        timerCancelled = true
        timerIsRunning = false
        timerFinished = false
        
        //Update the view for rotation and add listener for rotation
        rotated()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.rotated), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        //add observers for when view disappears and reappears
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.appWillTerminate(_:)), name: UIApplicationWillTerminateNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.appEnteredBackground(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.appBecameActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        if UserSettings.sharedSettings().autoFull {
            toggleFullscreen()
        }
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
            
            let data: Dictionary<String, AnyObject> = ["action":"start", "startTime": startTime, "duration": duration, "elapsedTime": elapsedTime]
            timeService.sendTimeData(data)
            session?.sendMessage(data, replyHandler: nil, errorHandler: nil)
            start()
        } else if !timerCancelled && !timerIsRunning {
            // Paused, should resume
            startTime = NSDate.timeIntervalSinceReferenceDate()
            
            let data: Dictionary<String, AnyObject> = ["action":"start", "startTime": startTime, "duration": duration, "elapsedTime": elapsedTime]
            timeService.sendTimeData(data)
            session?.sendMessage(data, replyHandler: nil, errorHandler: nil)
            start()
        }
    }
    
    @IBAction func pausePressed() {
        // Only pause if running
        if timerIsRunning {
            pauseTime = NSDate.timeIntervalSinceReferenceDate()
            pause()
            timeService.sendTimeData(["action":"pause", "pauseTime": pauseTime])
            session?.sendMessage(["action":"pause", "pauseTime": pauseTime], replyHandler: nil, errorHandler: nil)
        }
    }
    
    @IBAction func cancelPressed() {
        if !timerCancelled && !timerIsRunning {
            cancel()
            timeService.sendTimeData(["action":"cancel"])
            session?.sendMessage(["action":"cancel"], replyHandler: nil, errorHandler: nil)
        }
    }
    
    @IBAction func changedStopType(sender: UISegmentedControl) {
        stopType = StopType(rawValue: sender.selectedSegmentIndex)!
        timeService.sendTimeData(["action":"changeStopType", "stopType": stopType.rawValue])
        
    }
    
    @IBAction func invitePeers(sender: AnyObject) {
        let inviteView = MCBrowserViewController.init(serviceType: timeService.serviceType, session: timeService.session);
        inviteView.delegate = self
        inviteView.maximumNumberOfPeers = 2
        self.presentViewController(inviteView, animated: true, completion: nil)
    }
    
    @IBAction func toggleFullscreen() {
        if isFullscreen {
            // set back to 162...
            fullscreenView.hidden = true
            isFullscreen = false
        } else {
            fullscreenView.hidden = false
            isFullscreen = true
        }
    }
    
    func start() {
        // Only if the timer is not already running should something happen
        if !timerIsRunning {
            timerIsRunning = true
            timerCancelled = false
            timerFinished = false
            animateState()
            updateButtons()
            
            elapsedTime += NSDate.timeIntervalSinceReferenceDate() - startTime
            startTime = NSDate.timeIntervalSinceReferenceDate()
            
            timerLabel.setDate(NSDate(timeIntervalSinceNow: duration-elapsedTime))
            timerLabel.start()
            fullscreenLabel.setDate(NSDate(timeIntervalSinceNow: duration-elapsedTime))
            fullscreenLabel.start()
            
            // It's possible the delay caused the timer to end, then we need to finish the timer
            if timerFinished { return }
        }
    }
    
    func pause() {
        // Only pause if the timer is running
        if timerIsRunning {
            timerIsRunning = false
            timerCancelled = false
            timerFinished = false
            
            timerLabel.stop()
            fullscreenLabel.stop()
            elapsedTime += pauseTime - startTime
            elapsedTime -= NSDate.timeIntervalSinceReferenceDate() - pauseTime
            timerLabel.setDate(NSDate(timeIntervalSinceNow: duration-elapsedTime))
            fullscreenLabel.setDate(NSDate(timeIntervalSinceNow: duration-elapsedTime))
            
            updateButtons()
        }
    }
    
    func cancel() {
        // Only allow canceled when canceled
        if !timerIsRunning && !timerCancelled {
            timerIsRunning = false
            timerFinished = false
            timerCancelled = true
            
            elapsedTime = 0
            timerLabel.setDate(NSDate(timeIntervalSinceNow: duration))
            fullscreenLabel.setDate(NSDate(timeIntervalSinceNow: duration))
            
            updateButtons()
            animateState()
        }
    }
    
    // Upon timer completion, this runs
    func finishTimer() {
        timerFinished = true
        timerIsRunning = false
        timerCancelled = false
        
        timerLabel.stop()
        timerLabel.setDate(NSDate())
        fullscreenLabel.stop()
        fullscreenLabel.setDate(NSDate())
        
        updateButtons()
        
        let data: Dictionary<String, AnyObject> = ["action":"finish"]
        session?.sendMessage(data, replyHandler: nil, errorHandler: nil)
        
        // Play sound here
        do {
            audioPlayer = try AVAudioPlayer(contentsOfURL: NSURL(string: "/Library/Ringtones/Duck.m4r")!)
            NSLog("Playing Sound")
            audioPlayer.numberOfLoops = -1
            audioPlayer.play()
        } catch {
            debugPrint("\(error)")
        }
        timerDoneAlert = UIAlertController(title: "Timer done", message: nil, preferredStyle:.Alert)
        timerDoneAlert?.addAction(UIAlertAction(title: "Done", style: .Default) {
            UIAlertAction in
            if self.audioPlayer != nil {
                self.audioPlayer.stop()
            }
            self.timeService.sendTimeData(["action":"dismissTimerDone"])
            })
        self.presentViewController(timerDoneAlert!, animated: true, completion: nil)
    }
    
    func updateButtons() {
        if timerIsRunning && !timerCancelled && !timerFinished {
            cancelButton.hidden = true
            startButton.hidden = true
            inviteButton.hidden = true
            settingsButton.hidden = true
            pauseButton.hidden = false
        } else if timerCancelled && !timerIsRunning && !timerFinished {
            cancelButton.hidden = true
            startButton.hidden = false
            inviteButton.hidden = false
            settingsButton.hidden = false
            pauseButton.hidden = true
        } else if timerFinished && !timerCancelled && !timerIsRunning {
            cancelButton.hidden = false
            startButton.hidden = true
            inviteButton.hidden = false
            settingsButton.hidden = false
            pauseButton.hidden = true
        } else if !timerFinished && !timerCancelled && !timerIsRunning {
            cancelButton.hidden = false
            startButton.hidden = false
            inviteButton.hidden = false
            settingsButton.hidden = false
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
//        print("rotated")
//        print("\(self.view.frame.size.width)")
        minsLabel.frame = CGRectMake(self.view.frame.size.width/2-40, self.timerPicker.frame.height/2-11, 44, 22)
        secsLabel.frame = CGRectMake(self.view.frame.size.width/2+50, self.timerPicker.frame.height/2-11, 44, 22)
//        if self.view.frame.size.height <= 320 {
//            var newFrame = startButton.frame
//            newFrame.size.height = 75
//            startButton.frame = newFrame
//            pauseButton.frame = newFrame
//        } else {
//            var newFrame = startButton.frame
//            newFrame.size.height = 90
//            startButton.frame = newFrame
//            pauseButton.frame = newFrame
//        }
//        
//        startButton.layer.cornerRadius = startButton.bounds.size.height/2
    }
    
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
//        print("trans")
//        print("\(self.view.bounds.size.width)")
//        minsLabel.frame = CGRectMake(self.view.frame.size.width/2-42, self.timerLabel.frame.height/2-11, 44, 22)
//        secsLabel.frame = CGRectMake(self.view.frame.size.width/2+48, self.timerLabel.frame.height/2-11, 44, 22)
//    }
    
    //create observers when app reopens
    func appBecameActive(note: NSNotification) {
        print("Became Active")
        // Try to reconnect with last device
        // if repopen
        if !openFromTerm {
            self.timeService.attemptReconnect()
        }
    }
    
    func appEnteredBackground(note: NSNotification) {
        print("Entered Background")
        openFromTerm = false
    }
    
    //remove all observers
    func appWillTerminate(note: NSNotification) {
        print("App Terminated")
//        timerIsRunning = false
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
}

extension ViewController: UITimerLabelDelegate {
    func timerDidReachZero(timer: UITimerLabel) {
        NSLog("Reached Zero")
        if self.stopType == .Hard {
            finishTimer()
        }
    }
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
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
        UserSettings.sharedSettings().lastDuration = duration
        self.timerLabel.setDate(NSDate(timeIntervalSinceNow: self.duration-self.elapsedTime))
        self.fullscreenLabel.setDate(NSDate(timeIntervalSinceNow: self.duration-self.elapsedTime))
        timeService.sendTimeData(["action":"selectDuration", "duration": duration])
        session?.sendMessage(["action":"selectDuration", "duration": duration], replyHandler: nil, errorHandler: nil)
    }
    
    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component == 1 {
            return 120
        }
        return 50
    }
}

extension ViewController: TimeServiceManagerDelegate {
    
    func sendFullData() {
        let data: Dictionary<String, AnyObject> = ["action":"dataDump",
                                                   "elapsedTime":elapsedTime,
                                                   "duration":duration,
                                                   "startTime":startTime,
                                                   "pauseTime":pauseTime,
                                                   "stopType":stopType.rawValue,
                                                   "timerFinished": timerFinished,
                                                   "timerCancelled":timerCancelled,
                                                   "timerIsRunning":timerIsRunning]
        
        timeService.sendTimeData(data)
        session?.sendMessage(data, replyHandler: nil, errorHandler: nil)
    }
    
    func updateConnectionIcon(connected: Bool) {
        if connected {
            connectedIcon.hidden = false
        } else {
            connectedIcon.hidden = true
        }
    }
    
    func showConnecting() {
        self.presentViewController(connectingAlert, animated: true, completion: nil)
    }
    
    func hideConnecting(failed: Bool) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        if failed {
            connectedIcon.hidden = true
            
            let alert = UIAlertController(title: "Failed to Connect", message: "We couldn't establish a connection with the peer. You can go back and try again.", preferredStyle: UIAlertControllerStyle.Alert)
            
            let declineAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            alert.addAction(declineAction)
            
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            connectedIcon.hidden = false
        }
    }
    
    func invitationWasReceived(fromPeer: String) {
        let alert = UIAlertController(title: "", message: "\(fromPeer) wants to share a timer with you.", preferredStyle: UIAlertControllerStyle.Alert)
        
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
                self.elapsedTime = data["elapsedTime"] as! NSTimeInterval
                self.start()
            case "pause":
                self.pauseTime = data["pauseTime"] as! NSTimeInterval
                self.pause()
            case "cancel":
                self.cancel()
                if self.audioPlayer != nil {
                    self.audioPlayer.stop()
                }
                self.timerDoneAlert?.dismissViewControllerAnimated(true, completion: nil)
            case "changeStopType":
                // No change in time or what not, just hard/soft stop
                self.stopType = StopType(rawValue: data["stopType"] as! Int)!
                self.stopTypeSelector.selectedSegmentIndex = self.stopType.rawValue
            case "selectDuration":
                self.duration = data["duration"] as! Double
                self.timerLabel.setDate(NSDate(timeIntervalSinceNow: self.duration-self.elapsedTime))
                self.fullscreenLabel.setDate(NSDate(timeIntervalSinceNow: self.duration-self.elapsedTime))
                let (min, sec) = self.secondsToMinutesSeconds(data["duration"] as! Int)
                self.timerPicker.selectRow(min, inComponent: 0, animated: true)
                self.timerPicker.selectRow(sec, inComponent: 1, animated: true)
            case "dataDump":
                self.startTime = data["startTime"] as! NSTimeInterval
                self.duration = data["duration"] as! Double
                self.elapsedTime = data["elapsedTime"] as! NSTimeInterval
                self.pauseTime = data["pauseTime"] as! NSTimeInterval
                self.stopType = StopType(rawValue: data["stopType"] as! Int)!
                self.timerCancelled = data["timerCancelled"] as! Bool
                self.timerFinished = data["timerFinished"] as! Bool
                self.timerIsRunning = false
                
                self.timerLabel.setDate(NSDate(timeIntervalSinceNow: self.duration-self.elapsedTime))
                self.fullscreenLabel.setDate(NSDate(timeIntervalSinceNow: self.duration-self.elapsedTime))
                
                let running = data["timerIsRunning"] as! Bool
                if running {
                    self.start()
                }
                
                NSLog("running: \(self.timerIsRunning), canceled: \(self.timerCancelled), finished: \(self.timerFinished)")
                
                let (min, sec) = self.secondsToMinutesSeconds(data["duration"] as! Int)
                self.timerPicker.selectRow(min, inComponent: 0, animated: true)
                self.timerPicker.selectRow(sec, inComponent: 1, animated: true)
                
                self.animateState()
                self.updateButtons()
                
                self.session?.sendMessage(data, replyHandler: nil, errorHandler: nil)
            case "dismissTimerDone":
                if self.audioPlayer != nil {
                    self.audioPlayer.stop()
                }
                self.timerDoneAlert?.dismissViewControllerAnimated(true, completion: nil)
            default:
                break
            }
        }
    }
    
}

extension ViewController: WCSessionDelegate {
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            NSLog("Changes received")
            self.timeService.sendTimeData(message)
            switch message["action"] as! String {
            case "start":
                self.startTime = message["startTime"] as! NSTimeInterval
                self.duration = message["duration"] as! Double
                self.elapsedTime = message["elapsedTime"] as! NSTimeInterval
                self.start()
            case "pause":
                self.pauseTime = message["pauseTime"] as! NSTimeInterval
                self.pause()
            case "cancel":
                self.cancel()
                if self.audioPlayer != nil {
                    self.audioPlayer.stop()
                }
                self.timerDoneAlert?.dismissViewControllerAnimated(true, completion: nil)
            case "initialData":
                let data: Dictionary<String, AnyObject> = ["action":"dataDump",
                    "pauseTime":self.pauseTime,
                    "elapsedTime":self.elapsedTime,
                    "duration":self.duration,
                    "startTime":self.startTime,
                    "stopType":self.stopType.rawValue,
                    "timerFinished": self.timerFinished,
                    "timerCancelled":self.timerCancelled,
                    "timerIsRunning":self.timerIsRunning]
                replyHandler(data)
            default:
                break
            }
        }
    }
    
}

extension ViewController: MCBrowserViewControllerDelegate {
    
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}