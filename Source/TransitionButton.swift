//
//  TransitionButton.swift
//  TransitionButton
//
//  Created by Alaeddine M. on 11/1/15.
//  Copyright (c) 2015 Alaeddine M. All rights reserved.
//

import Foundation
import UIKit

/**
Stop animation style of the `TransitionButton`.
 
 - normal: just revert the button to the original state.
 - expand: expand the button and cover all the screen, useful to do transit animation.
 - shake: revert the button to original state and make a shaoe animation, useful to reflect that something went wrong
 */
public enum StopAnimationStyle {
    case normal
    case expand
    case shake
}

/// UIButton sublass for loading and transition animation. Useful for network based application or where you need to animate an action button while doing background tasks.
 
@IBDesignable open class TransitionButton : UIButton, UIViewControllerTransitioningDelegate, CAAnimationDelegate {
    
    /// the color of the spinner while animating the button
    /// Open có nghĩa là có thể kế thừa và override ở module khác.
    @IBInspectable open var spinnerColor: UIColor = UIColor.white {
        didSet {
            spiner.spinnerColor = spinnerColor
        }
    }
    
    /// the background of the button in disabled state
    @IBInspectable open var disabledBackgroundColor: UIColor = UIColor.lightGray {
        didSet {
            self.setBackgroundImage(UIImage(color: disabledBackgroundColor), for: .disabled)
        }
    }
    
    /// the corner radius value to have a button with rounded corners.
    @IBInspectable open var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    /// spiner là 1 layer Layer, khi nào được gọi sẽ init và add vào self ~ TransitionButton
    private lazy var spiner: SpinerLayer = {
        let spiner = SpinerLayer(frame: self.frame)
        self.layer.addSublayer(spiner)
        return spiner
    }()
    
    private var cachedTitle: String?
    private var cachedImage: UIImage?
    
    private let springGoEase:CAMediaTimingFunction  = CAMediaTimingFunction(controlPoints: 0.45, -0.36, 0.44, 0.92)
    private let shrinkCurve:CAMediaTimingFunction   = CAMediaTimingFunction(name: .linear)
    private let expandCurve:CAMediaTimingFunction   = CAMediaTimingFunction(controlPoints: 0.95, 0.02, 1, 0.05)
    private let shrinkDuration: CFTimeInterval      = 0.1

    public override init(frame: CGRect) {
        super.init(frame: frame)
         self.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
         self.setup()
    }

    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
         self.setup()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.spiner.setToFrame(self.frame)
    }
    
    private func setup() {
        self.clipsToBounds  = true
        spiner.spinnerColor = spinnerColor
    }

    // MARK: Public
    
    open func startAnimation() {
        /// Cache lại TITLE + IMAGE
        self.isUserInteractionEnabled = false
        self.cachedTitle = title(for: .normal)
        self.cachedImage = image(for: .normal)
        
        /// Set nil TITLE + IMAGE
        self.setTitle("",  for: .normal)
        self.setImage(nil, for: .normal)
        
        /// ANIMATION
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            /// Chưa thấy được animation chỗ này
            self.layer.cornerRadius = self.frame.height/2
        }, completion: { completed -> Void in
            self.startShrinkAnimation()
            self.spiner.startAnimation()
        })
    }
    
    open func stopAnimation(animationStyle:StopAnimationStyle = .normal, revertAfterDelay delay: TimeInterval = 1.0, completion:(()->Void)? = nil) {

        let delayToRevert = max(delay, 0.2)

        switch animationStyle {
        case .normal:
            // We return to original state after a delay to give opportunity to custom transition
            DispatchQueue.main.asyncAfter(deadline: .now() + delayToRevert) {
                self.setOriginalState(completion: completion)
            }
        case .shake:
            // We return to original state after a delay to give opportunity to custom transition
            DispatchQueue.main.asyncAfter(deadline: .now() + delayToRevert) {
                self.setOriginalState(completion: nil)
                self.shakeAnimation(completion: completion)
            }
        case .expand:
            self.spiner.stopAnimation() // before animate the expand animation we need to hide the spiner first
            self.expand(completion: completion, revertDelay: delayToRevert) // scale the round button to fill the screen
        }
    }

    // MARK: Private
    
    private func shakeAnimation(completion:(()->Void)?) {
        /// Shake khi stop animation
        /// Không dùng BasicAnimation mà dùng KeyFrameAnimation
        /// KeyPath là position nghĩa là tao muốn animation position của Button
        let keyFrame = CAKeyframeAnimation(keyPath: "position")
        let curPoint = self.layer.position
        keyFrame.values = [NSValue(cgPoint: CGPoint(x: CGFloat(curPoint.x), y: CGFloat(curPoint.y))),
                           NSValue(cgPoint: CGPoint(x: CGFloat(curPoint.x - 10), y: CGFloat(curPoint.y))),
                           NSValue(cgPoint: CGPoint(x: CGFloat(curPoint.x + 10), y: CGFloat(curPoint.y))),
                           NSValue(cgPoint: CGPoint(x: CGFloat(curPoint.x - 10), y: CGFloat(curPoint.y))),
                           NSValue(cgPoint: CGPoint(x: CGFloat(curPoint.x + 10), y: CGFloat(curPoint.y))),
                           NSValue(cgPoint: CGPoint(x: CGFloat(curPoint.x - 10), y: CGFloat(curPoint.y))),
                           NSValue(cgPoint: CGPoint(x: CGFloat(curPoint.x + 10), y: CGFloat(curPoint.y))),
                           NSValue(cgPoint: curPoint)]
        
        keyFrame.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        keyFrame.duration = 3.0
        self.layer.position = curPoint
        /// Add keyframe animation
        self.layer.add(keyFrame, forKey: keyFrame.keyPath)

        /// Gọi completion sau khi animation xong
        CATransaction.setCompletionBlock {
            completion?()
        }
        CATransaction.commit()
    }
    
    private func setOriginalState(completion:(()->Void)?) {
        /// Set về trạng thái original của Button
        self.animateToOriginalWidth(completion: completion)
        self.spiner.stopAnimation()
        self.setTitle(self.cachedTitle, for: .normal)
        self.setImage(self.cachedImage, for: .normal)
        self.isUserInteractionEnabled = true // enable again the user interaction
        self.layer.cornerRadius = self.cornerRadius
    }
 
    private func animateToOriginalWidth(completion:(()->Void)?) {
        /// Animation về trạng thái original
        let shrinkAnim = CABasicAnimation(keyPath: "bounds.size.width")
        shrinkAnim.fromValue = (self.bounds.height)
        shrinkAnim.toValue = (self.bounds.width)
        shrinkAnim.duration = shrinkDuration
        shrinkAnim.timingFunction = shrinkCurve
        shrinkAnim.fillMode = .forwards
        shrinkAnim.isRemovedOnCompletion = false
        self.layer.add(shrinkAnim, forKey: shrinkAnim.keyPath)

        /// Set completionBlock sau khi transition xong
        CATransaction.setCompletionBlock {
            completion?()
        }
        CATransaction.commit()
    }
    
    private func startShrinkAnimation() {
        /// Tạo CABasicAnimation cho self.width
        /// Co width lại bằng height
        let shrinkAnim = CABasicAnimation(keyPath: "bounds.size.width")
        shrinkAnim.fromValue = frame.width
        shrinkAnim.toValue = frame.height
        shrinkAnim.duration = shrinkDuration /// duration của animation
        shrinkAnim.timingFunction = shrinkCurve /// chưa biết timingFunction là gì?
        shrinkAnim.fillMode = .forwards /// chưa biết luôn?
        shrinkAnim.isRemovedOnCompletion = false    /// remove sau khi completion animation?
        
        /// Add animation vào layer
        layer.add(shrinkAnim, forKey: shrinkAnim.keyPath)
    }
    
    private func expand(completion:(()->Void)?, revertDelay: TimeInterval) {
        /// Expand animation Button
        /// Create animation and setup
        let expandAnim = CABasicAnimation(keyPath: "transform.scale")
        let expandScale = (UIScreen.main.bounds.size.height/self.frame.size.height)*2
        expandAnim.fromValue = 1.0
        expandAnim.toValue = max(expandScale,26.0)
        expandAnim.timingFunction = expandCurve
        expandAnim.duration = 1.0 /// duration expand
        expandAnim.fillMode = .forwards
        expandAnim.isRemovedOnCompletion = false
        layer.add(expandAnim, forKey: expandAnim.keyPath)

        /// Set completion block sau khi animation xong:
        /// Commit all changes made during the current transaction. Raises an exception if no current transaction exists
        /// Q: Chưa biết commit để làm gì?
        /// Nếu ko commit thì vẫn chạy được mà?
        CATransaction.setCompletionBlock {
            completion?()
            
            /// DispatchAfter để reset button về trạng thái original
            DispatchQueue.main.asyncAfter(deadline: .now() + revertDelay) {
                self.setOriginalState(completion: nil)
                self.layer.removeAllAnimations()
            }
        }
        CATransaction.commit()
    }
    
}

/// Chưa  sử dụng trong project này
public extension UIImage {
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image!.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
