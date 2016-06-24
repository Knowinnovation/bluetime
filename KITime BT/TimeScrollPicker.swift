//
//  TimeScrollPicker.swift
//  TimeScrollPicker
//
//  Created by Drew Dunne on 6/20/16.
//  Copyright © 2016 Drew Dunne. All rights reserved.
//

import UIKit

let mult:CGFloat = 10.0

protocol TimeScrollPickerDelegate {
    func pickerDidSelectTime(seconds: Int)
}

class TimeScrollPicker: UIView {
    
    private var rightScrollView: UIScrollView!
    private var leftScrollView: UIScrollView!
    private var timeLabel: UILabel!
    
    private var timerSlider2: UIView!
    
    private var selectedTime: Int = 0
    var minSelectableTime: Int = 0
    var maxSelectableTime: Int = 3600
    
    var delegate: TimeScrollPickerDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        timeLabel = UILabel(frame: CGRectMake(0,0, self.frame.size.width, self.frame.size.height))
        timeLabel.textAlignment = .Center
//        timeLabel.font = UIFont.systemFontOfSize(26, weight: UIFontWeightUltraLight)
        let size = self.frame.size.width/320 * 50
        timeLabel.font = UIFont(name: "Audimat Mono", size: size)
        timeLabel.textColor = UIColor.darkTextColor()
        self.addSubview(timeLabel)
        
        leftScrollView = UIScrollView(frame: CGRectMake(0,0, self.frame.size.width/2, self.frame.size.height))
        leftScrollView.bounces = false
        leftScrollView.contentSize = CGSizeMake(leftScrollView.frame.width/2, 59*mult+leftScrollView.frame.height)
        leftScrollView.scrollsToTop = false
        leftScrollView.maximumZoomScale = 1
        leftScrollView.minimumZoomScale = 1
        leftScrollView.delegate = self
        leftScrollView.showsVerticalScrollIndicator = false
        let timerSlider = UIView(frame: CGRectMake(0,0,70, leftScrollView.contentSize.height))
        timerSlider.backgroundColor = UIColor(patternImage: UIImage(named: "timeslider.png")!)
        leftScrollView.addSubview(timerSlider)
        self.addSubview(leftScrollView)
        
        rightScrollView = UIScrollView(frame: CGRectMake(self.frame.size.width/2,0, self.frame.size.width/2, self.frame.size.height))
        rightScrollView.bounces = false
        rightScrollView.contentSize = CGSizeMake(rightScrollView.frame.width, 59*mult+rightScrollView.frame.height)
        rightScrollView.scrollsToTop = false
        rightScrollView.maximumZoomScale = 1
        rightScrollView.minimumZoomScale = 1
        rightScrollView.delegate = self
        rightScrollView.showsVerticalScrollIndicator = false
        timerSlider2 = UIView(frame: CGRectMake(rightScrollView.frame.width-70,0,70, leftScrollView.contentSize.height))
        let scrollImage = UIImage(named: "timeslider.png")!
        timerSlider2.backgroundColor = UIColor(patternImage: UIImage(CGImage: scrollImage.CGImage!, scale: scrollImage.scale, orientation: .UpMirrored))
        rightScrollView.addSubview(timerSlider2)
        self.addSubview(rightScrollView)
        
        updateLabel()
    }
    
    func updateFrame(frame: CGRect) {
        self.frame = frame
        timeLabel.frame = CGRectMake(0,0, self.frame.size.width, self.frame.size.height)
        let size = self.frame.size.width/320 * 50
        timeLabel.font = UIFont(name: "Audimat Mono", size: size)
        
        leftScrollView.frame = CGRectMake(0,0, self.frame.size.width, self.frame.size.height)
        leftScrollView.contentSize = CGSizeMake(leftScrollView.frame.width/2, 59*mult+leftScrollView.frame.height)
        
        rightScrollView.frame = CGRectMake(self.frame.size.width/2,0, self.frame.size.width/2, self.frame.size.height)
        rightScrollView.contentSize = CGSizeMake(rightScrollView.frame.width, 59*mult+rightScrollView.frame.height)
        timerSlider2.frame = CGRectMake(rightScrollView.frame.width-70,0,70, leftScrollView.contentSize.height)
    }
    
    func setSelectedTime(seconds: Int) {
        let (min, secs) = secondsToMinutesSeconds(seconds)
        selectedTime = seconds
        updateLabel()
        leftScrollView.contentOffset = CGPointMake(0, CGFloat(min)*mult)
        rightScrollView.contentOffset = CGPointMake(0, CGFloat(secs)*mult)
    }
    
    private func updateLabel() {
        let (min, secs) = secondsToMinutesSeconds(selectedTime)
        timeLabel.text = String(format: "%02dm %02ds", min, secs)
    }
    
    private func secondsToMinutesSeconds (seconds : Int) -> (Int, Int) {
        return ( (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

}

extension TimeScrollPicker: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        selectedTime = Int(round(leftScrollView.contentOffset.y/mult))*60 + Int(round(rightScrollView.contentOffset.y/mult))
        updateLabel()
        delegate?.pickerDidSelectTime(selectedTime)
    }
}
