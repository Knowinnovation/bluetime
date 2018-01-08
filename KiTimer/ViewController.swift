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
    case hard = 0
    case soft = 1
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
    var stopType: StopType = .hard
    
    var elapsedTime: TimeInterval = 0
    var startTime: TimeInterval = -1
    var pauseTime: TimeInterval = -1
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
                session.activate()
            }
        }
    }
    
    var timerDoneAlert: UIAlertController?
    
    lazy var connectingAlert: UIAlertController = {
        var alert = UIAlertController(title: "Connecting", message: "\n\n\n", preferredStyle: UIAlertControllerStyle.alert)
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.center = CGPoint(x: 130.5, y: 65.5);
        spinner.color = UIColor.black;
        spinner.startAnimating();
        alert.view.addSubview(spinner)
        return alert
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        timeService.delegate = self
        timerLabel.delegate = self
        fullscreenLabel.delegate = self
        UIApplication.shared.isIdleTimerDisabled = true
        
        startButton.layer.cornerRadius = 10;
        pauseButton.layer.cornerRadius = 10;
        cancelButton.layer.cornerRadius = 10;
        
        minsLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2-40, y: self.timerPicker.frame.height/2-11, width: 44, height: 22))
        minsLabel.font = UIFont.systemFont(ofSize: 17.0)
        minsLabel.text = "mins"
        timerPicker.addSubview(minsLabel)
        
        secsLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2+50, y: self.timerPicker.frame.height/2-11, width: 44, height: 22))
        secsLabel.font = UIFont.systemFont(ofSize: 17.0)
        secsLabel.text = "secs"
        timerPicker.addSubview(secsLabel)
        
        duration = UserSettings.sharedSettings().lastDuration
        if duration == 0 {
            duration = 300
        }
        let (min, sec) = secondsToMinutesSeconds(Int(duration))
        timerPicker.selectRow(min, inComponent: 0, animated: false)
        timerPicker.selectRow(sec, inComponent: 1, animated: false)
        pauseButton.isHidden = true
        cancelButton.isHidden = true
        
        fullscreenView.isHidden = true
        fullscreenLabel.adjustsFontSizeToFitWidth = true
        
        timerLabel.setDate(Date(timeIntervalSinceNow: duration-elapsedTime))
        fullscreenLabel.setDate(Date(timeIntervalSinceNow: duration-elapsedTime))
        
        if WCSession.isSupported() {
            session = WCSession.default
        }
        
        timerCancelled = true
        timerIsRunning = false
        timerFinished = false
        
        //Update the view for rotation and add listener for rotation
        rotated()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        //add observers for when view disappears and reappears
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appWillTerminate(_:)), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appEnteredBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appBecameActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
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
            startTime = Date.timeIntervalSinceReferenceDate
            
            let data: Dictionary<String, AnyObject> = ["action":"start" as AnyObject, "startTime": startTime as AnyObject, "duration": duration as AnyObject, "elapsedTime": elapsedTime as AnyObject]
            timeService.sendTimeData(data)
            session?.sendMessage(data, replyHandler: nil, errorHandler: nil)
            start()
        } else if !timerCancelled && !timerIsRunning {
            // Paused, should resume
            startTime = Date.timeIntervalSinceReferenceDate
            
            let data: Dictionary<String, AnyObject> = ["action":"start" as AnyObject, "startTime": startTime as AnyObject, "duration": duration as AnyObject, "elapsedTime": elapsedTime as AnyObject]
            timeService.sendTimeData(data)
            session?.sendMessage(data, replyHandler: nil, errorHandler: nil)
            start()
        }
    }
    
    @IBAction func pausePressed() {
        // Only pause if running
        if timerIsRunning {
            pauseTime = Date.timeIntervalSinceReferenceDate
            pause()
            timeService.sendTimeData(["action":"pause" as AnyObject, "pauseTime": pauseTime as AnyObject])
            session?.sendMessage(["action":"pause", "pauseTime": pauseTime], replyHandler: nil, errorHandler: nil)
        }
    }
    
    @IBAction func cancelPressed() {
        if !timerCancelled && !timerIsRunning {
            cancel()
            timeService.sendTimeData(["action":"cancel" as AnyObject])
            session?.sendMessage(["action":"cancel"], replyHandler: nil, errorHandler: nil)
        }
    }
    
    @IBAction func changedStopType(_ sender: UISegmentedControl) {
        stopType = StopType(rawValue: sender.selectedSegmentIndex)!
        timeService.sendTimeData(["action":"changeStopType" as AnyObject, "stopType": stopType.rawValue as AnyObject])
        
    }
    
    @IBAction func invitePeers(_ sender: AnyObject) {
        let inviteView = MCBrowserViewController.init(serviceType: timeService.serviceType, session: timeService.session);
        inviteView.delegate = self
        inviteView.maximumNumberOfPeers = 2
        self.present(inviteView, animated: true, completion: nil)
    }
    
    @IBAction func toggleFullscreen() {
        if isFullscreen {
            // set back to 162...
            fullscreenView.isHidden = true
            isFullscreen = false
        } else {
            fullscreenView.isHidden = false
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
            
            elapsedTime += Date.timeIntervalSinceReferenceDate - startTime
            startTime = Date.timeIntervalSinceReferenceDate
            
            timerLabel.setDate(Date(timeIntervalSinceNow: duration-elapsedTime))
            timerLabel.start()
            fullscreenLabel.setDate(Date(timeIntervalSinceNow: duration-elapsedTime))
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
            elapsedTime -= Date.timeIntervalSinceReferenceDate - pauseTime
            timerLabel.setDate(Date(timeIntervalSinceNow: duration-elapsedTime))
            fullscreenLabel.setDate(Date(timeIntervalSinceNow: duration-elapsedTime))
            
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
            timerLabel.setDate(Date(timeIntervalSinceNow: duration))
            fullscreenLabel.setDate(Date(timeIntervalSinceNow: duration))
            
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
        timerLabel.setDate(Date())
        fullscreenLabel.stop()
        fullscreenLabel.setDate(Date())
        
        updateButtons()
        
        let data: Dictionary<String, AnyObject> = ["action":"finish" as AnyObject]
        session?.sendMessage(data, replyHandler: nil, errorHandler: nil)
        
        // Play sound here
        do {
            if let url = URL(string: "/Library/Ringtones/Duck.m4r") {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                NSLog("Playing Sound")
                audioPlayer.numberOfLoops = -1
                audioPlayer.play()
            }
        } catch {
            debugPrint("\(error)")
        }
        timerDoneAlert = UIAlertController(title: "Timer done", message: nil, preferredStyle:.alert)
        timerDoneAlert?.addAction(UIAlertAction(title: "Done", style: .default) {
            UIAlertAction in
            if self.audioPlayer != nil {
                self.audioPlayer.stop()
            }
            self.timeService.sendTimeData(["action":"dismissTimerDone" as AnyObject])
            })
        self.present(timerDoneAlert!, animated: true, completion: nil)
    }
    
    func updateButtons() {
        if timerIsRunning && !timerCancelled && !timerFinished {
            cancelButton.isHidden = true
            startButton.isHidden = true
            inviteButton.isHidden = true
            settingsButton.isHidden = true
            pauseButton.isHidden = false
        } else if timerCancelled && !timerIsRunning && !timerFinished {
            cancelButton.isHidden = true
            startButton.isHidden = false
            inviteButton.isHidden = false
            settingsButton.isHidden = false
            pauseButton.isHidden = true
        } else if timerFinished && !timerCancelled && !timerIsRunning {
            cancelButton.isHidden = false
            startButton.isHidden = true
            inviteButton.isHidden = false
            settingsButton.isHidden = false
            pauseButton.isHidden = true
        } else if !timerFinished && !timerCancelled && !timerIsRunning {
            cancelButton.isHidden = false
            startButton.isHidden = false
            inviteButton.isHidden = false
            settingsButton.isHidden = false
            pauseButton.isHidden = true
        }
    }
    
    //Get the total duration (seconds) from the picker
    func getTimeFromPicker() -> Double {
        let minsToSecs = timerPicker.selectedRow(inComponent: 0)*60
        let secs = timerPicker.selectedRow(inComponent: 1)
        let time = Double(minsToSecs + secs)
        return time
    }
    
    //Convert the seconds into the minutes time and seconds time
    func secondsToMinutesSeconds (_ seconds : Int) -> (Int, Int) {
        return ( (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    // Fades picker/timer in and out based on current state
    func animateState() {
        if timerIsRunning {
            UIView.animate(withDuration: 0.5, animations: {
                self.timerPicker.alpha = 0.0
                self.timerLabel.alpha = 1.0
            }) 
        } else if timerCancelled {
            UIView.animate(withDuration: 0.5, animations: {
                self.timerPicker.alpha = 1.0
                self.timerLabel.alpha = 0.0
            }) 
        } else {
            self.timerPicker.alpha = 0.0
            self.timerLabel.alpha = 1.0
        }
    }
    
    // Changes view based on rotation of device
    @objc func rotated() {
//        print("rotated")
//        print("\(self.view.frame.size.width)")
        minsLabel.frame = CGRect(x: self.view.frame.size.width/2-40, y: self.timerPicker.frame.height/2-11, width: 44, height: 22)
        secsLabel.frame = CGRect(x: self.view.frame.size.width/2+50, y: self.timerPicker.frame.height/2-11, width: 44, height: 22)
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
    @objc func appBecameActive(_ note: Notification) {
        print("Became Active")
        // Try to reconnect with last device
        // if repopen
        if !openFromTerm {
            self.timeService.attemptReconnect()
        }
    }
    
    @objc func appEnteredBackground(_ note: Notification) {
        print("Entered Background")
        openFromTerm = false
    }
    
    //remove all observers
    @objc func appWillTerminate(_ note: Notification) {
        print("App Terminated")
//        timerIsRunning = false
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
}

extension ViewController: UITimerLabelDelegate {
    func timerDidReachZero(_ timer: UITimerLabel) {
        print("Reached Zero")
        let data: Dictionary<String, AnyObject> = ["action":"reached0" as AnyObject]
        session?.sendMessage(data, replyHandler: nil, errorHandler: nil)
        if self.stopType == .hard {
            finishTimer()
        }
    }
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 60
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row)
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 1 {
            if row == 0 && pickerView.selectedRow(inComponent: 0) == 0 {
                pickerView.selectRow(1, inComponent: 1, animated: true)
            }
        } else {
            if row == 0 && pickerView.selectedRow(inComponent: 1) == 0 {
                pickerView.selectRow(1, inComponent: 0, animated: true)
            }
        }
        duration = getTimeFromPicker()
        UserSettings.sharedSettings().lastDuration = duration
        self.timerLabel.setDate(Date(timeIntervalSinceNow: self.duration-self.elapsedTime))
        self.fullscreenLabel.setDate(Date(timeIntervalSinceNow: self.duration-self.elapsedTime))
        timeService.sendTimeData(["action":"selectDuration" as AnyObject, "duration": duration as AnyObject])
        session?.sendMessage(["action":"selectDuration", "duration": duration], replyHandler: nil, errorHandler: nil)
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if component == 1 {
            return 120
        }
        return 50
    }
}

extension ViewController: TimeServiceManagerDelegate {
    
    func sendFullData() {
        let data: Dictionary<String, AnyObject> = ["action":"dataDump" as AnyObject,
                                                   "elapsedTime":elapsedTime as AnyObject,
                                                   "duration":duration as AnyObject,
                                                   "startTime":startTime as AnyObject,
                                                   "pauseTime":pauseTime as AnyObject,
                                                   "stopType":stopType.rawValue as AnyObject,
                                                   "timerFinished": timerFinished as AnyObject,
                                                   "timerCancelled":timerCancelled as AnyObject,
                                                   "timerIsRunning":timerIsRunning as AnyObject]
        
        timeService.sendTimeData(data)
        session?.sendMessage(data, replyHandler: nil, errorHandler: nil)
    }
    
    func updateConnectionIcon(_ connected: Bool) {
        if connected {
            connectedIcon.isHidden = false
        } else {
            connectedIcon.isHidden = true
        }
    }
    
    func showConnecting() {
        //self.present(connectingAlert, animated: true, completion: nil)
    }
    
    func hideConnecting(_ failed: Bool) {
        self.dismiss(animated: true, completion: nil)
        
        if failed {
            connectedIcon.isHidden = true
            
            let alert = UIAlertController(title: "Failed to Connect", message: "We couldn't establish a connection with the peer. You can go back and try again.", preferredStyle: UIAlertControllerStyle.alert)
            
            let declineAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(declineAction)
            
            self.present(alert, animated: true, completion: nil)
        } else {
            connectedIcon.isHidden = false
        }
    }
    
    func invitationWasReceived(_ fromPeer: String) {
        let alert = UIAlertController(title: "", message: "\(fromPeer) wants to share a timer with you.", preferredStyle: UIAlertControllerStyle.alert)
        
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.timeService.invitationHandler?(true, self.timeService.session)
        }
        
        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
            self.timeService.invitationHandler?(false, self.timeService.session)
        }
        
        alert.addAction(acceptAction)
        alert.addAction(declineAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func changesReceived(_ data: Dictionary<String, AnyObject>) {
        OperationQueue.main.addOperation {
            NSLog("Changes received")
            switch data["action"] as! String {
            case "start":
                self.startTime = data["startTime"] as! TimeInterval
                self.duration = data["duration"] as! Double
                self.elapsedTime = data["elapsedTime"] as! TimeInterval
                self.start()
            case "pause":
                self.pauseTime = data["pauseTime"] as! TimeInterval
                self.pause()
            case "cancel":
                self.cancel()
                if self.audioPlayer != nil {
                    self.audioPlayer.stop()
                }
                self.timerDoneAlert?.dismiss(animated: true, completion: nil)
            case "changeStopType":
                // No change in time or what not, just hard/soft stop
                self.stopType = StopType(rawValue: data["stopType"] as! Int)!
                self.stopTypeSelector.selectedSegmentIndex = self.stopType.rawValue
            case "selectDuration":
                self.duration = data["duration"] as! Double
                self.timerLabel.setDate(Date(timeIntervalSinceNow: self.duration-self.elapsedTime))
                self.fullscreenLabel.setDate(Date(timeIntervalSinceNow: self.duration-self.elapsedTime))
                let (min, sec) = self.secondsToMinutesSeconds(data["duration"] as! Int)
                self.timerPicker.selectRow(min, inComponent: 0, animated: true)
                self.timerPicker.selectRow(sec, inComponent: 1, animated: true)
            case "dataDump":
                self.startTime = data["startTime"] as! TimeInterval
                self.duration = data["duration"] as! Double
                self.elapsedTime = data["elapsedTime"] as! TimeInterval
                self.pauseTime = data["pauseTime"] as! TimeInterval
                self.stopType = StopType(rawValue: data["stopType"] as! Int)!
                self.timerCancelled = data["timerCancelled"] as! Bool
                self.timerFinished = data["timerFinished"] as! Bool
                self.timerIsRunning = false
                
                self.timerLabel.setDate(Date(timeIntervalSinceNow: self.duration-self.elapsedTime))
                self.fullscreenLabel.setDate(Date(timeIntervalSinceNow: self.duration-self.elapsedTime))
                
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
                self.timerDoneAlert?.dismiss(animated: true, completion: nil)
            default:
                break
            }
        }
    }
    
}

extension ViewController: WCSessionDelegate {
    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {
        
    }

    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        
    }

    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }

    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        OperationQueue.main.addOperation {
            NSLog("Changes received")
            self.timeService.sendTimeData(message as Dictionary<String, AnyObject>)
            switch message["action"] as! String {
            case "start":
                self.startTime = message["startTime"] as! TimeInterval
                self.duration = message["duration"] as! Double
                self.elapsedTime = message["elapsedTime"] as! TimeInterval
                self.start()
            case "pause":
                self.pauseTime = message["pauseTime"] as! TimeInterval
                self.pause()
            case "cancel":
                self.cancel()
                if self.audioPlayer != nil {
                    self.audioPlayer.stop()
                }
                self.timerDoneAlert?.dismiss(animated: true, completion: nil)
            case "initialData":
                let data: Dictionary<String, AnyObject> = ["action":"dataDump" as AnyObject,
                    "pauseTime":self.pauseTime as AnyObject,
                    "elapsedTime":self.elapsedTime as AnyObject,
                    "duration":self.duration as AnyObject,
                    "startTime":self.startTime as AnyObject,
                    "stopType":self.stopType.rawValue as AnyObject,
                    "timerFinished": self.timerFinished as AnyObject,
                    "timerCancelled":self.timerCancelled as AnyObject,
                    "timerIsRunning":self.timerIsRunning as AnyObject]
                replyHandler(data)
            default:
                break
            }
        }
    }
    
}

extension ViewController: MCBrowserViewControllerDelegate {
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}
