//
//  ViewControllerWithHeaderAndScrollView.swift
//  scrollToActiveControl
//
//  Created by Anton Halenda on 04.10.17.
//  Copyright © 2017 Anton Halenda. All rights reserved.
//

import UIKit

class ViewControllerWithHeaderAndScrollView: UIViewController {
    
    @IBOutlet weak var heightRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightOffsetConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if heightOffsetConstraint != nil && heightRatioConstraint != nil {
            heightOffsetConstraint.constant = getOffsetByHeaderAspectRatio(ratio: heightRatioConstraint.multiplier)
        }
    }
}
