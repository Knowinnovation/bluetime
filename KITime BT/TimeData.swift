//
//  TimeData.swift
//  KITime BT
//
//  Created by Drew Dunne on 6/2/16.
//  Copyright © 2016 Know Innovation. All rights reserved.
//

import UIKit

class TimeData: NSObject {
    
    var timeState: TimerState = .Stopped
    var timer: NSInteger = 300
    var startTime: NSTimeInterval!
    var stopType: StopType = .Hard

}
