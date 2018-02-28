//
//  AMGifProgress.swift
//  AMGiphyPicker
//
//  Created by Alexander Momotiuk on 01.25.18.
//  Copyright © 2018 Alexander Momotiuk. All rights reserved.
//

import UIKit

class AMGifProgress: UIView {
    
    private let progressShape = CAShapeLayer()
    private let backgroundShape = CAShapeLayer()
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundShape.frame = bounds
        progressShape.frame = bounds
        progressShape.lineWidth = bounds.width/8
    }
    
    private func setup() {
        backgroundShape.fillColor = UIColor(red: 20.0/255.0, green: 20.0/255.0, blue: 20.0/255.0, alpha: 1.0).cgColor
        
        progressShape.strokeColor = UIColor.white.cgColor
        progressShape.fillColor = UIColor.clear.cgColor
        progressShape.lineCap = kCALineCapRound
        
        setupLayout()
    }
    
    private func setupLayout() {
        layer.addSublayer(backgroundShape)
        layer.addSublayer(progressShape)
    }
    
    func updateIndicator(with percent: CGFloat, isAnimated: Bool = false) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = progressShape.strokeEnd
        animation.toValue = percent
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut);
        
        backgroundShape.path = UIBezierPath(ovalIn: self.bounds).cgPath
        
        let lineWidth = bounds.width/8
        let frame = CGRect(x: lineWidth*1.5, y: lineWidth*1.5, width: self.frame.width - lineWidth*3, height: self.frame.height - lineWidth*3)
        progressShape.path = UIBezierPath(ovalIn: frame).cgPath
        progressShape.strokeEnd = percent
        
        if isAnimated {
            progressShape.add(animation, forKey: nil)
        }
    }
}
