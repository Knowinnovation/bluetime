//
//  UITimerView.swift
//
//  Created by Drew Dunne on 6/14/16.
//  Copyright © 2016 Drew Dunne. All rights reserved.
//

// This version of UITimerLabel has been modified from the original

import UIKit

@objc protocol UITimerLabelDelegate {
    @objc optional func timerDidReachZero(_ timer: UITimerLabel);
}

class UITimerLabel: UILabel {
    
    private var timer: Timer?
    private var runToDate: Date?
    private var timerRunning: Bool = false
    
    var delegate: UITimerLabelDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.common()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.common()
    }
    
    fileprivate func common() {
        NSLog("Initing")
        self.text = "00:00"
    }
    
    // Sets the date which the timer counts down to (or up to)
    func setDate(_ date: Date) {
        runToDate = date
        self.setTimeDisplay(self.runToDate!.timeIntervalSinceNow + 1)
    }
    
    // Start counting down to the date
    func start() {
        // If the date is not set it won't start
        // Also if already running won't start another timer
        if runToDate != nil && !timerRunning {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(UITimerLabel.updateTime), userInfo: nil, repeats: true)
            
            // Timer needs to run on main loop for obvious reasons
            RunLoop.current.add(timer!, forMode: RunLoopMode.defaultRunLoopMode)
            timerRunning = true
        } else {
            setTimeDisplay(0)
        }
    }
    
    // Stop the timer
    func stop() {
        timer!.invalidate()
        timerRunning = false
    }
    
    // Updates the time
    @objc fileprivate func updateTime() {
        let time = self.runToDate!.timeIntervalSinceNow + 1
        self.setTimeDisplay(time)
        if floor(time) == 0 {
            NSLog("At zero")
            delegate?.timerDidReachZero?(self)
        }
    }
    
    // Formats the time interval for displaying
    fileprivate func setTimeDisplay(_ displayTime: TimeInterval) {
        if displayTime >= 0 {
            if displayTime < 60 {
                self.textColor = UIColor.red
            } else if displayTime < 120 {
                self.textColor = UIColor.orange
            } else {
                self.textColor = UIColor.black
            }
            let (m,s) = secondsToMinutesSeconds(Int(displayTime))
            self.text = String(format: "%02d:%02d",m,s)
        } else {
            self.textColor = UIColor.red
            let (m,s) = secondsToMinutesSeconds(Int(abs(displayTime)))
            self.text = String(format: "+%02d:%02d",m,s)
        }
    }
    
    // Converts the seconds to minutes and seconds
    fileprivate func secondsToMinutesSeconds (_ seconds : Int) -> (Int, Int) {
        return ( (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

}
