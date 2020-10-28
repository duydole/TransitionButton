//
//  SpinerLayer.swift
//  TransitionButton
//
//  Created by Alaeddine M. on 11/1/15.
//  Copyright (c) 2015 Alaeddine M. All rights reserved.
//

import UIKit

/// CAShapeLayer: CALayer
/// CAShapeLayer là: A layer that draws a cubic Bezier spline in its coordinate space.
class SpinerLayer: CAShapeLayer {
    
    var spinnerColor = UIColor.white {
        didSet {
            strokeColor = spinnerColor.cgColor
        }
    }
    
    init(frame: CGRect) {
        super.init() 
        
        self.setToFrame(frame)
        
        /// FillColor: The color to fill the path, or nil for no fill. Defaults to opaque black. Animatable
        /// FillColor là backgroundColor của CAShapeLayer
        self.fillColor = nil
        self.strokeColor = spinnerColor.cgColor
        self.lineWidth = 1      /// width của stroke
        self.strokeEnd = 0.4    /// Stroke line chiếm 40%
        self.isHidden = true    /// default là hidden, khi nào start aniamtion mới show
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Public
    
    public func setToFrame(_ frame: CGRect) {
        self.frame = CGRect(x: 0, y: 0, width: frame.height, height: frame.height)
        
        /// Radius là bán kính vẽ stroke
        let radius:CGFloat = (frame.height/2) * 0.5
        let center = CGPoint(x: frame.height / 2, y: bounds.center.y)
        let startAngle = 0 - Double.pi/2
        let endAngle = Double.pi * 2 - Double.pi/2
        let clockwise: Bool = true
        
        /// Cách vẽ nửa hình tròn trắng trên layer:
        ///The path defining the shape to be rendered. Animatable.
        /// self là CAShapLayer kết hợp UIBezierPath để vẽ hình
        self.path = UIBezierPath(arcCenter: center,                     /// center của layer
                                 radius: radius,                        /// bán kính
                                 startAngle: CGFloat(startAngle),
                                 endAngle: CGFloat(endAngle),
                                 clockwise: clockwise).cgPath
    }
    
    public func startAnimation() {
        self.isHidden = false
        
        /// Tạo CABasicAnimation ROTATION theo trục Z
        let rotateBasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateBasicAnimation.fromValue = 0
        rotateBasicAnimation.toValue = 2*Double.pi
        rotateBasicAnimation.duration = 0.4
        rotateBasicAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        rotateBasicAnimation.repeatCount = HUGE /// Rotate forever
        rotateBasicAnimation.fillMode = .forwards
        rotateBasicAnimation.isRemovedOnCompletion = false
        
        /// Add CABasicAnimation vào CALayer
        self.add(rotateBasicAnimation, forKey: rotateBasicAnimation.keyPath)
    }
    
    public func stopAnimation() {
        self.isHidden = true
        self.removeAllAnimations()
    }
    
    // MARK: Private
    
}
