//
//  TimerEnums.swift
//  KITime BT
//
//  Created by Drew Dunne on 6/5/16.
//  Copyright © 2016 Know Innovation. All rights reserved.
//

import Foundation

enum TimerState: String {
    case Stopped = "stopped"
    case Paused = "paused"
    case Running = "running"
    case Finished = "finished"
    case None = "none"
}

enum StopType: Int {
    case Hard = 0
    case Soft = 1
}
