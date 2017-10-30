//
//  UIViewContollerScrollOffsetExtension.swift
//  scrollToActiveControl
//
//  Created by Anton Halenda on 04.10.17.
//  Copyright © 2017 Anton Halenda. All rights reserved.
//

import UIKit
extension ViewControllerWithHeaderAndScrollView {
    func getOffsetByHeaderAspectRatio(ratio: CGFloat)-> CGFloat {
        var topLayoutHeight: CGFloat = 0
        var offset: CGFloat = 0
        topLayoutHeight = navigationController?.navigationBar.frame.maxY ?? 44
        offset = UIScreen.main.bounds.width * ratio - topLayoutHeight
        return offset
    }
}
