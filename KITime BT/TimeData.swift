//
//  TimeData.swift
//  KITime BT
//
//  Created by Drew Dunne on 6/2/16.
//  Copyright © 2016 Know Innovation. All rights reserved.
//

import UIKit

class TimeData: NSObject, NSCoding {
    
    var timeState: TimerState = .Stopped
    var timer: Int = 300
    var startTime: NSTimeInterval = -1
    var stopType: StopType = .Hard
    var timeChange: Bool = false
    
    required convenience init(coder decoder: NSCoder) {
        self.init()
        timeState = TimerState(rawValue: decoder.decodeObjectForKey("timeState") as! String)!
        timer = decoder.decodeObjectForKey("timer") as! Int
        startTime = decoder.decodeObjectForKey("startTime") as! NSTimeInterval
        stopType = StopType(rawValue: decoder.decodeObjectForKey("stopType") as! Int)!
        timeChange = decoder.decodeObjectForKey("timeChange") as! Bool
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(timeState.rawValue, forKey: "timeState")
        coder.encodeObject(timer, forKey: "timer")
        coder.encodeObject(startTime, forKey: "startTime")
        coder.encodeObject(stopType.rawValue, forKey: "stopType")
        coder.encodeObject(timeChange, forKey: "timeChange")
    }
}
