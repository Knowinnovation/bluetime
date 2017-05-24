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
    func pickerDidSelectTime(_ seconds: Int)
}

class TimeScrollPicker: UIView {
    
    fileprivate var rightScrollView: UIScrollView!
    fileprivate var leftScrollView: UIScrollView!
    fileprivate var timeLabel: UILabel!
    
    fileprivate var timerSlider2: UIView!
    
    fileprivate var selectedTime: Int = 0
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
    
    fileprivate func commonInit() {
        timeLabel = UILabel(frame: CGRect(x: 0,y: 0, width: self.frame.size.width, height: self.frame.size.height))
        timeLabel.textAlignment = .center
//        timeLabel.font = UIFont.systemFontOfSize(26, weight: UIFontWeightUltraLight)
        let size = self.frame.size.width/320 * 50
        timeLabel.font = UIFont(name: "Audimat Mono", size: size)
        timeLabel.textColor = UIColor.darkText
        self.addSubview(timeLabel)
        
        leftScrollView = UIScrollView(frame: CGRect(x: 0,y: 0, width: self.frame.size.width/2, height: self.frame.size.height))
        leftScrollView.bounces = false
        leftScrollView.contentSize = CGSize(width: leftScrollView.frame.width/2, height: 59*mult+leftScrollView.frame.height)
        leftScrollView.scrollsToTop = false
        leftScrollView.maximumZoomScale = 1
        leftScrollView.minimumZoomScale = 1
        leftScrollView.delegate = self
        leftScrollView.showsVerticalScrollIndicator = false
        let timerSlider = UIView(frame: CGRect(x: 0,y: 0,width: 70, height: leftScrollView.contentSize.height))
        timerSlider.backgroundColor = UIColor(patternImage: UIImage(named: "timeslider.png")!)
        leftScrollView.addSubview(timerSlider)
        self.addSubview(leftScrollView)
        
        rightScrollView = UIScrollView(frame: CGRect(x: self.frame.size.width/2,y: 0, width: self.frame.size.width/2, height: self.frame.size.height))
        rightScrollView.bounces = false
        rightScrollView.contentSize = CGSize(width: rightScrollView.frame.width, height: 59*mult+rightScrollView.frame.height)
        rightScrollView.scrollsToTop = false
        rightScrollView.maximumZoomScale = 1
        rightScrollView.minimumZoomScale = 1
        rightScrollView.delegate = self
        rightScrollView.showsVerticalScrollIndicator = false
        timerSlider2 = UIView(frame: CGRect(x: rightScrollView.frame.width-70,y: 0,width: 70, height: leftScrollView.contentSize.height))
        let scrollImage = UIImage(named: "timeslider.png")!
        timerSlider2.backgroundColor = UIColor(patternImage: UIImage(cgImage: scrollImage.cgImage!, scale: scrollImage.scale, orientation: .upMirrored))
        rightScrollView.addSubview(timerSlider2)
        self.addSubview(rightScrollView)
        
        updateLabel()
    }
    
    func updateFrame(_ frame: CGRect) {
        self.frame = frame
        timeLabel.frame = CGRect(x: 0,y: 0, width: self.frame.size.width, height: self.frame.size.height)
        let size = self.frame.size.width/320 * 50
        timeLabel.font = UIFont(name: "Audimat Mono", size: size)
        
        leftScrollView.frame = CGRect(x: 0,y: 0, width: self.frame.size.width, height: self.frame.size.height)
        leftScrollView.contentSize = CGSize(width: leftScrollView.frame.width/2, height: 59*mult+leftScrollView.frame.height)
        
        rightScrollView.frame = CGRect(x: self.frame.size.width/2,y: 0, width: self.frame.size.width/2, height: self.frame.size.height)
        rightScrollView.contentSize = CGSize(width: rightScrollView.frame.width, height: 59*mult+rightScrollView.frame.height)
        timerSlider2.frame = CGRect(x: rightScrollView.frame.width-70,y: 0,width: 70, height: leftScrollView.contentSize.height)
    }
    
    func setSelectedTime(_ seconds: Int) {
        let (min, secs) = secondsToMinutesSeconds(seconds)
        selectedTime = seconds
        updateLabel()
        leftScrollView.contentOffset = CGPoint(x: 0, y: CGFloat(min)*mult)
        rightScrollView.contentOffset = CGPoint(x: 0, y: CGFloat(secs)*mult)
    }
    
    fileprivate func updateLabel() {
        let (min, secs) = secondsToMinutesSeconds(selectedTime)
        timeLabel.text = String(format: "%02dm %02ds", min, secs)
    }
    
    fileprivate func secondsToMinutesSeconds (_ seconds : Int) -> (Int, Int) {
        return ( (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

}

extension TimeScrollPicker: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        selectedTime = Int(round(leftScrollView.contentOffset.y/mult))*60 + Int(round(rightScrollView.contentOffset.y/mult))
        updateLabel()
        delegate?.pickerDidSelectTime(selectedTime)
    }
}
