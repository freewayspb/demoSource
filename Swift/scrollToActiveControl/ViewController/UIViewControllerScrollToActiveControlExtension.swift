//
//  UIViewControllerScrollToActiveControlExtension.swift
//  scrollToActiveControl
//
//  Created by Anton Halenda on 04.10.17.
//  Copyright © 2017 Anton Halenda. All rights reserved.
//

import UIKit
extension TextFieldWithTitleAndUnderlineDelegate where Self: ViewControllerWithHeaderAndScrollView {
    func registerKeyboardNotifications() {
        showKeyboardObserver = NotificationCenter.default.addObserver(forName: .UIKeyboardDidShow, object: nil, queue: nil) { [weak self] notification in
            self?.keyboardDidShow(notification: notification)
        }
        hideKeyboardObserver = NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: nil) { [weak self] notification in
            self?.keyboardWillHide(notification: notification)
        }
    }
    
    func unregisterKeyboardNotifications() {
        if showKeyboardObserver != nil {
            NotificationCenter.default.removeObserver(showKeyboardObserver!)
        }
        if hideKeyboardObserver != nil {
            NotificationCenter.default.removeObserver(hideKeyboardObserver!)
        }
    }
    
    func keyboardDidShow(notification: Notification) {
        let predictionBarHeight: CGFloat = 44
        if let activeControl = self.activeControl, let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height + predictionBarHeight, right: 0.0)
            print(self.scrollView.contentInset)
            self.scrollView.contentInset = contentInsets
            print(self.scrollView.contentInset)
            self.scrollView.scrollIndicatorInsets = contentInsets
            var aRect = self.view.frame
            aRect.size.height -= keyboardSize.size.height
            if (!aRect.contains(activeControl.frame.origin)) {
                self.scrollView.scrollRectToVisible(activeControl.frame, animated: true)
            }
            //            if activeControl.superview?.superview != nil {
            //                if activeControl.superview!.superview! is UITableViewCell {
            //                    if let window = UIApplication.shared.keyWindow {
            //                        let realRectForConntrol = window.convert(activeControl.frame, from: activeControl)
            //                        if aRect.contains(realRectForConntrol) || aRect.intersects(realRectForConntrol) {
            //                            //self.scrollView.setContentOffset(<#T##contentOffset: CGPoint##CGPoint#>, animated: <#T##Bool#>)
            //                        }
            //                    }
            //                }
            //            }
        }
    }
    
    func keyboardWillHide(notification: Notification) {
        let contentInsets = UIEdgeInsets.zero
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
    }
}
