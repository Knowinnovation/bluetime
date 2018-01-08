//
//  InterfaceController.swift
//  KiTimer Watch Extension
//
//  Created by Drew Dunne on 7/11/16.
//  Copyright © 2016 Knowinnovation. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var startStopButton: WKInterfaceButton!
    @IBOutlet weak var cancelButton: WKInterfaceButton!
    @IBOutlet weak var timerLabel: WKInterfaceTimer!
    
    var startTime: TimeInterval = -1
    var pauseTime: TimeInterval = -1
    var duration: Double = 300
    var elapsedTime: TimeInterval = 0
    var timer: Timer?
    var timerIsRunning: Bool = false
    var timerFinished: Bool = false
    var timerCancelled: Bool = true
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activate()
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        NSLog("Loaded")
        // Configure interface objects here.
    }
    
    override func didAppear() {
        super.didAppear()
        NSLog("View appeared")
        timerIsRunning = false
        timerCancelled = true
        timerFinished = false
        updateButtons()
        
        timerLabel.setDate(Date(timeIntervalSinceNow: duration+1))
        
        if WCSession.isSupported() {
            session = WCSession.default
            session!.sendMessage(["action":"initialData"], replyHandler: { (response) -> Void in
                
                self.startTime = response["startTime"] as! TimeInterval
                self.duration = response["duration"] as! Double
                self.elapsedTime = response["elapsedTime"] as! TimeInterval
                self.pauseTime = response["pauseTime"] as! Double
                self.timerCancelled = response["timerCancelled"] as! Bool
                self.timerFinished = response["timerFinished"] as! Bool
                self.timerIsRunning = false
                
                self.timerLabel.setDate(Date(timeIntervalSinceNow: self.duration-self.elapsedTime+1))
                
                let running = response["timerIsRunning"] as! Bool
                if running {
                    self.start()
                }
                
                //print("running: %d, canceled: %d, finished: %d", self.timerIsRunning, self.timerCancelled, self.timerFinished)
                
                self.updateButtons()
                }, errorHandler: { (error) -> Void in
                    print(error)
            })
        }
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func startStopPressed() {
        if timerIsRunning {
            pauseTime = Date.timeIntervalSinceReferenceDate
            pause()
            session!.sendMessage(["action":"pause", "pauseTime":pauseTime], replyHandler: { (response) -> Void in
                
                }, errorHandler: { (error) -> Void in
                    print(error)
            })
        } else {
            startTime = Date.timeIntervalSinceReferenceDate
            session!.sendMessage(["action":"start", "duration":duration, "startTime":startTime, "elapsedTime":elapsedTime], replyHandler: { (response) -> Void in
                
                }, errorHandler: { (error) -> Void in
                    print(error)
            })
            start()
        }
    }
    
    @IBAction func cancelPressed() {
        cancel()
        session!.sendMessage(["action":"cancel"], replyHandler: { (response) -> Void in
            
            }, errorHandler: { (error) -> Void in
                print(error)
        })
    }
    
    func start() {
        if !timerIsRunning {
            timerIsRunning = true
            timerCancelled = false
            timerFinished = false
            updateButtons()
            
            elapsedTime += Date.timeIntervalSinceReferenceDate - startTime
            startTime = Date.timeIntervalSinceReferenceDate
            
            timerLabel.setDate(Date(timeIntervalSinceNow: duration-elapsedTime+1))
            timerLabel.start()
            
            // It's possible the delay caused the timer to end, then we need to finish the timer
            if timerFinished { return }
        }
    }
    
    func pause() {
        if timerIsRunning {
            timerIsRunning = false
            timerCancelled = false
            timerFinished = false
            
            timerLabel.stop()
            elapsedTime += pauseTime - startTime
            elapsedTime -= Date.timeIntervalSinceReferenceDate - pauseTime
            timerLabel.setDate(Date(timeIntervalSinceNow: duration-elapsedTime+1))
            
            updateButtons()
        }
    }
    
    func cancel() {
        timerFinished = false
        timerIsRunning = false
        timerCancelled = true
        
        timerLabel.stop()
        let date = Date(timeIntervalSinceReferenceDate: Date.timeIntervalSinceReferenceDate+duration+1)
        timerLabel.setDate(date)
        
        elapsedTime = 0
        
        updateButtons()
    }
    
    func updateButtons() {
        if timerIsRunning && !timerCancelled && !timerFinished {
            cancelButton.setEnabled(false)
            startStopButton.setEnabled(true)
            startStopButton.setTitle("Pause")
        } else if timerCancelled && !timerIsRunning && !timerFinished {
            cancelButton.setEnabled(false)
            startStopButton.setEnabled(true)
            startStopButton.setTitle("Start")
        } else if timerFinished && !timerCancelled && !timerIsRunning {
            cancelButton.setEnabled(true)
            startStopButton.setEnabled(false)
            startStopButton.setTitle("Start")
        } else if !timerFinished && !timerCancelled && !timerIsRunning {
            cancelButton.setEnabled(true)
            startStopButton.setEnabled(true)
            startStopButton.setTitle("Start")
        }
    }
    
}

extension InterfaceController: WCSessionDelegate {
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
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
        case "selectDuration":
            if timerCancelled {
                duration = message["duration"] as! Double
                timerLabel.setDate(Date(timeIntervalSinceNow: duration-elapsedTime+1))
            }
        case "finish":
            timerLabel.stop()
            self.timerFinished = true
            self.timerIsRunning = false
            self.updateButtons()
        case "reached0":
            print("Reached 0")
            timerLabel.stop()
            pauseTime = Date.timeIntervalSinceReferenceDate
            elapsedTime += pauseTime - startTime
//            elapsedTime -= NSDate.timeIntervalSinceReferenceDate() - pauseTime
            print("\(duration), \(elapsedTime)")
            timerLabel.setDate(Date(timeIntervalSinceNow: duration-elapsedTime+1))
            startTime = Date.timeIntervalSinceReferenceDate
//            elapsedTime += NSDate.timeIntervalSinceReferenceDate() - startTime
//            timerLabel.setDate(NSDate(timeIntervalSinceNow: duration-elapsedTime+1))
            timerLabel.start()
//            self.pause()
//            self.start()
//            timerLabel.stop()
//            timerLabel.start()
        case "dataDump":
            self.startTime = message["startTime"] as! TimeInterval
            self.duration = message["duration"] as! Double
            self.elapsedTime = message["elapsedTime"] as! TimeInterval
            self.pauseTime = message["pauseTime"] as! TimeInterval
            self.timerCancelled = message["timerCancelled"] as! Bool
            self.timerFinished = message["timerFinished"] as! Bool
            self.timerIsRunning = false
            
            let running = message["timerIsRunning"] as! Bool
            if running {
                self.start()
            }
            
            self.updateButtons()
        default:
            break
        }
    }
}
