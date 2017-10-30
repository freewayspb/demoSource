//
//  ViewController.swift
//  scrollToActiveControl
//
//  Created by Anton Halenda on 04.10.17.
//  Copyright © 2017 Anton Halenda. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: ViewControllerWithHeaderAndScrollView, TextFieldWithTitleAndUnderlineDelegate {
    
    internal var disposeBag: DisposeBag? = DisposeBag()
    fileprivate let viewModel = ViewModel()
    
    //MARK: TextFieldWithTitleAndUnderlineDelegate
    var activeControl: TextFieldWithTitleAndUnderline?
    var textFieldWithTitleAndUnderlineDelegate: TextFieldWithTitleAndUnderlineDelegate?
    var showKeyboardObserver: Any?
    var hideKeyboardObserver: Any?
    
    //MARK: Outlets
    @IBOutlet fileprivate weak var accountName  : TextFieldWithTitleAndUnderline!
    @IBOutlet fileprivate weak var socialNumber : TextFieldWithTitleAndUnderline!
    @IBOutlet fileprivate weak var zipCode      : TextFieldWithTitleAndUnderline!
    
    //MARK: Error fields
    fileprivate var accountError       : Variable<String> = Variable<String>("")
    fileprivate var socialError        : Variable<String> = Variable<String>("")
    fileprivate var zcodeError         : Variable<String> = Variable<String>("")
    fileprivate var generalErrorString : Variable<String> = Variable<String>("")
    
    //MARK: Fields length
    fileprivate let ssnMaxLength         : Int = 4
    fileprivate let zipCodeMaxLength     : Int = 5
    fileprivate let accountNameMaxLength : Int = 12
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        textFieldWithTitleAndUnderlineDelegate = self
        bindDataToUi()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
    }
    
    //MARK: Private functions
    fileprivate func bindDataToUi() {
        let accountBindModel = TextFieldWithTitleAndUnderlineBindModel(inputBind: viewModel.accountName, errorBind: accountError.asObservable(), disposeBind: disposeBag!)
        let ssnBindModel = TextFieldWithTitleAndUnderlineBindModel(inputBind: viewModel.socialSecurityNumber, errorBind: socialError.asObservable(), disposeBind: disposeBag!)
        let zcodeBindModel = TextFieldWithTitleAndUnderlineBindModel(inputBind: viewModel.zipCode, errorBind: zcodeError.asObservable(), disposeBind: disposeBag!)
        
        accountName.setupControl(bindModel: accountBindModel, delegate: textFieldWithTitleAndUnderlineDelegate, maxLength: accountNameMaxLength)
        socialNumber.setupControl(bindModel: ssnBindModel, delegate: textFieldWithTitleAndUnderlineDelegate, maxLength: ssnMaxLength)
        zipCode.setupControl(bindModel: zcodeBindModel, delegate: textFieldWithTitleAndUnderlineDelegate, maxLength: zipCodeMaxLength)
    }
}
