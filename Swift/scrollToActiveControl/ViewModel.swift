//
//  ViewModel.swift
//  scrollToActiveControl
//
//  Created by Anton Halenda on 04.10.17.
//  Copyright © 2017 Anton Halenda. All rights reserved.
//
import RxSwift

class ViewModel {
    private let model: Model = Model()
    private let disposeBag = DisposeBag()
    
    var accountName          : Variable<String> = Variable<String>("")
    var socialSecurityNumber : Variable<String> = Variable<String>("")
    var zipCode              : Variable<String> = Variable<String>("")
    
    init() {
        (model.accName <-> accountName).disposed(by: disposeBag)
        (model.ssn <-> socialSecurityNumber).disposed(by: disposeBag)
        (model.zCode <-> zipCode).disposed(by: disposeBag)
    }
}
