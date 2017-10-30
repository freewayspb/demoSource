//
//  TextFieldWithTitleAndUnderlineTextFieldDelegate.swift
//  scrollToActiveControl
//
//  Created by Anton Halenda on 04.10.17.
//  Copyright © 2017 Anton Halenda. All rights reserved.
//

import UIKit

extension TextFieldWithTitleAndUnderline: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return false
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.activeControl = nil
    }
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        delegate?.activeControl = self
        return true
    }
}
