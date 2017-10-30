//
//  UIViewLoadFromNibExtension.swift
//  scrollToActiveControl
//
//  Created by Anton Halenda on 04.10.17.
//  Copyright © 2017 Anton Halenda. All rights reserved.
//

import UIKit
extension UIView {
    internal func loadViewFromNib(viewClass: Swift.AnyClass) -> UIView! {
        let bundle = Bundle(for: viewClass.self)
        let nib = UINib(nibName: String(describing: viewClass.self), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }
}
