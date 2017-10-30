//
//  TransformingVariable.swift
//  scrollToActiveControl
//
//  Created by Anton Halenda on 04.10.17.
//  Copyright © 2017 Anton Halenda. All rights reserved.
//

import RxSwift

public struct TransformingVariable<VariableType> {
    var variable: Variable<VariableType>
    var inputRule: (VariableType) -> String
    var outputRule: (String) -> VariableType
}
