//
//  UIViewControllerExtension.swift
//  byte
//
//  Created by Xiao Ling on 5/27/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit



extension UIViewController {
    
    func rightSwipeable( with fn: Selector ) -> UIViewController{
        let swipeRight = UISwipeGestureRecognizer(target: self, action: fn)
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        return self
    }
    
    func leftSwipeable( with fn: Selector ) -> UIViewController {
        let swipe = UISwipeGestureRecognizer(target: self, action: fn)
        swipe.direction = .left
        self.view.addGestureRecognizer(swipe)
        return self
    }

    func downSwipeable( with fn: Selector ) -> UIViewController {
        let swipe = UISwipeGestureRecognizer(target: self, action: fn)
        swipe.direction = .down
        self.view.addGestureRecognizer(swipe)
        return self
    }
    
    func upSwipeable( with fn: Selector ) -> UIViewController {
        let swipe = UISwipeGestureRecognizer(target: self, action: fn)
        swipe.direction = .up
        self.view.addGestureRecognizer(swipe)
        return self
    }

    func tappable( with fn: Selector ) -> UIViewController {
        let singleTap = UITapGestureRecognizer(target: self, action: fn)
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(singleTap)
        return self
    }

    
    /*
     @use: get header height
    */
    func computeHeaderHeight() -> CGFloat {
        if self.navigationController != nil && !self.navigationController!.navigationBar.isTranslucent {
             return 0
         } else {
            let barHeight = self.navigationController?.navigationBar.frame.height ?? 0
            // let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            let statusBarHeight = UIApplication.shared.statusBarFrame.height
            return barHeight + statusBarHeight
         }
    }

    
    /*
     @use: get the tabbar height for layout
    */
    func computeTabBarHeight() -> CGFloat {
        if let ht = self.tabBarController?.tabBar.frame.height {
            return ht
        } else {
            return 50
        }
    }
    
    func observeAppForegroundState(
        appMovedToForeground: Selector,
        appMovedToBackground: Selector
    ){
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
              self
            , selector: appMovedToForeground
            , name: UIApplication.willEnterForegroundNotification
            , object: nil
        )

        notificationCenter.addObserver(
              self
            , selector: appMovedToBackground
            , name: UIApplication.didEnterBackgroundNotification
            , object: nil
        )
    }
    
    //Keyboard listener
    func observeKeyboard(
        didShow: Selector,
        didHide: Selector
    ){
    
        NotificationCenter.default.addObserver(
              self
            , selector: didShow
            , name: UIResponder.keyboardWillShowNotification
            , object: nil
        )

        NotificationCenter.default.addObserver(
              self
            , selector: didHide
            , name: UIResponder.keyboardWillHideNotification
            , object: nil
        )
    }

    


}


func doSwipeLeft( on gesture: UIGestureRecognizer, _ complete: @escaping () -> Void){

    if let swipeGesture = gesture as? UISwipeGestureRecognizer {

        switch swipeGesture.direction {
            case .left:
                complete()
            default:
                break
        }
    }
    
}


func doSwipeRight( on gesture: UIGestureRecognizer, _ complete: @escaping () -> Void){

    if let swipeGesture = gesture as? UISwipeGestureRecognizer {

        switch swipeGesture.direction {
            case .right:
                complete()
            default:
                break
        }
    }
    
}
