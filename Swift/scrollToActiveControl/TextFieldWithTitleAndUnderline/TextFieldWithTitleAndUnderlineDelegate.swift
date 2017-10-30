//
//  TextFieldWithTitleAndUnderlineDelegate.swift
//  scrollToActiveControl
//
//  Created by Anton Halenda on 04.10.17.
//  Copyright © 2017 Anton Halenda. All rights reserved.
//
import Foundation
@objc public protocol TextFieldWithTitleAndUnderlineDelegate {
    var activeControl: TextFieldWithTitleAndUnderline? {get set}
    var textFieldWithTitleAndUnderlineDelegate: TextFieldWithTitleAndUnderlineDelegate? {get set}
    var showKeyboardObserver: Any? {get set}
    var hideKeyboardObserver: Any? {get set}
}
