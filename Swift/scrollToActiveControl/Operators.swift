//
//  Operators.swift
//  RxExample
//
//  Created by Krunoslav Zaher on 12/6/15.
//  Modified by Anton Halenda
//
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//
#if !RX_NO_MODULE
    import RxSwift
    import RxCocoa
#endif

import UIKit

// Two way binding operator between control property and variable, that's all it takes {
infix operator <-> : DefaultPrecedence

func nonMarkedText(_ textInput: UITextInput) -> String? {
    let start = textInput.beginningOfDocument
    let end = textInput.endOfDocument
    
    guard let rangeAll = textInput.textRange(from: start, to: end),
        let text = textInput.text(in: rangeAll) else {
            return nil
    }
    
    guard let markedTextRange = textInput.markedTextRange else {
        return text
    }
    
    guard let startRange = textInput.textRange(from: start, to: markedTextRange.start),
        let endRange = textInput.textRange(from: markedTextRange.end, to: end) else {
            return text
    }
    
    return (textInput.text(in: startRange) ?? "") + (textInput.text(in: endRange) ?? "")
}

func <-> <Base: UITextInput>(textInput: TextInput<Base>, variable: Variable<String>) -> Disposable {
    let bindToUIDisposable = variable.asObservable().observeOn(MainScheduler.instance)
        .bindTo(textInput.text)
    let bindToVariable = textInput.text.observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak base = textInput.base] n in
            guard let base = base else {
                return
            }
            
            let nonMarkedTextValue = nonMarkedText(base)
            
            /**
             In some cases `textInput.textRangeFromPosition(start, toPosition: end)` will return nil even though the underlying
             value is not nil. This appears to be an Apple bug. If it's not, and we are doing something wrong, please let us know.
             The can be reproed easily if replace bottom code with
             
             if nonMarkedTextValue != variable.value {
             variable.value = nonMarkedTextValue ?? ""
             }
             and you hit "Done" button on keyboard.
             */
            if let nonMarkedTextValue = nonMarkedTextValue, nonMarkedTextValue != variable.value {
                variable.value = nonMarkedTextValue
            }
            }, onCompleted:  {
                bindToUIDisposable.dispose()
        })
    return CompositeDisposable(bindToUIDisposable, bindToVariable)
}

func <-> <Base: UITextInput, T>(textInput: TextInput<Base>, transformingVariable: TransformingVariable<T>) -> Disposable {
    
    let bindToUIDisposable = transformingVariable.variable.asObservable().observeOn(MainScheduler.instance).map{transformingVariable.inputRule($0)
        }.bindTo(textInput.text)
    
    let bindToVariable = textInput.text
        .subscribe(onNext: { [weak base = textInput.base] n in
            guard let base = base else {
                return
            }
            if base is UITextField {
                transformingVariable.variable.value = transformingVariable.outputRule(n ?? "")
            } else {
                let nonMarkedTextValue = nonMarkedText(base)
                let value = transformingVariable.inputRule(transformingVariable.variable.value)
                if let nonMarkedTextValue = nonMarkedTextValue, nonMarkedTextValue != value {
                    transformingVariable.variable.value = transformingVariable.outputRule(nonMarkedTextValue)
                } else if let val = n {
                    transformingVariable.variable.value = transformingVariable.outputRule(val)
                }
            }
            
            }, onCompleted:  {
                bindToUIDisposable.dispose()
        })
    return CompositeDisposable(bindToUIDisposable, bindToVariable)
}

func <-> <T>(property: ControlProperty<T>, variable: Variable<T>) -> Disposable {
    var updating = false
    
    let bindToUIDisposable = variable.asObservable().filter({ _ in
        print("filter1")
        updating = !updating
        return updating
    }).bindTo(property)
    let bindToVariable = property.filter({ _ in
        print("filter2")
        updating = !updating
        return updating
    }).subscribe(onNext: { n in
        print(n)
        variable.value = n
    }, onCompleted:  {
        bindToUIDisposable.dispose()
    })
    
    return CompositeDisposable(bindToUIDisposable, bindToVariable)
}

func <-> <T: Equatable>(left: Variable<T>, right: Variable<T>) -> Disposable {
    
    var updating = false
    
    let leftToRight = left.asObservable()
        .filter{value in
            updating = !updating
            return updating
        }
        .bindTo(right)
    
    let rightToLeft = right.asObservable()
        .filter{value in
            updating = !updating
            return updating
        }
        .bindTo(left)
    
    return CompositeDisposable(leftToRight, rightToLeft)
}
