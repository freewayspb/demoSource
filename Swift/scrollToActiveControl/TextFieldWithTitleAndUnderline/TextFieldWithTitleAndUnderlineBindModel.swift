//
//  TextFieldWithTitleAndUnderlineBindModel.swift
//  scrollToActiveControl
//
//  Created by Anton Halenda on 04.10.17.
//  Copyright © 2017 Anton Halenda. All rights reserved.
//

import RxSwift
typealias StringConvertionType = (String) -> String

open class TextFieldWithTitleAndUnderlineBindModel {
    open var inputString: Variable<String>
    open var inputStringBehaviorSubject: BehaviorSubject<String>?
    open var titleString: Observable<String>?
    open var errorString: Observable<String>?
    open var disposeBag: DisposeBag
    open var inputRule: ((String) -> String)?
    open var outputRule: ((String) -> String)?
    
    init(inputBind: Variable<String>, titleBind: Observable<String>? = nil, errorBind: Observable<String>? = nil, disposeBind: DisposeBag? = nil, inputRule: StringConvertionType? = nil, outputRule: StringConvertionType? = nil) {

        inputString = inputBind
        titleString = titleBind
        errorString = errorBind
        self.inputRule = inputRule
        self.outputRule = outputRule
        disposeBag = disposeBind ?? DisposeBag()
    }
    
    open func getTransformingVariable() -> TransformingVariable<String> {
        let currentInputRule = inputRule ?? {$0}
        let currentOutputRule = outputRule ?? {$0}
        return TransformingVariable(variable: inputString, inputRule: currentInputRule, outputRule: currentOutputRule)
    }
}
