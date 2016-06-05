//
//  TimerButton.swift
//  KITime BT
//
//  Created by Drew Dunne on 6/2/16.
//  Copyright © 2016 Know Innovation. All rights reserved.
//

import UIKit

class TimerButton: UIButton {

    override var highlighted: Bool {
        didSet {
            if highlighted {
                self.backgroundColor = UIColor(white: 0.60, alpha: 1.0)
            } else {
                self.backgroundColor = UIColor.whiteColor()
            }
            
        }
    }
    
    override var enabled: Bool {
        didSet {
            if enabled {
                //self.backgroundColor = UIColor.whiteColor()
                self.alpha = 1.0
            } else {
                //self.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
                self.alpha = 0.0
            }
            
        }
    }

}
