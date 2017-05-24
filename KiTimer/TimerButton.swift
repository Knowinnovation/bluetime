//
//  TimerButton.swift
//  KITime BT
//
//  Created by Drew Dunne on 6/2/16.
//  Copyright © 2016 Know Innovation. All rights reserved.
//

import UIKit

class TimerButton: UIButton {

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.backgroundColor = UIColor(white: 0.60, alpha: 1.0)
            } else {
                self.backgroundColor = UIColor.white
            }
            
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                self.alpha = 1.0
            } else {
                self.alpha = 0.0
            }
            
        }
    }

}
