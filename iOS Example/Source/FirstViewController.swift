//
//  FirstViewController.swift
//  TransitionButton
//
//  Created by Alaeddine M. on 11/1/15.
//  Copyright (c) 2015 Alaeddine M. All rights reserved.
//

import UIKit
import TransitionButton

class FirstViewController: UIViewController {

    /// Did tap TransitionButton
    @IBAction func buttonAction(_ button: TransitionButton) {
        /// Start Animation
        button.startAnimation()
        
        /// Create backgroundQueue và execute 1 block
        let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        backgroundQueue.async(execute: {
            /// Assume do some backgroundtask
            sleep(3)

            DispatchQueue.main.async(execute: { () -> Void in
                /// Stop animation with style
                ///     .expand: useful when the task has been compeletd successfully and you want to expand the button and transit to another view controller in the completion callback
                ///     .shake: when you want to reflect to the user that the task did not complete successfly
                ///     .normal
                button.stopAnimation(animationStyle: .shake, completion: {
                    ///let secondVC = SecondViewController()
                    ///self.present(secondVC, animated: true, completion: nil)
                })
            })
        })
    }
}

