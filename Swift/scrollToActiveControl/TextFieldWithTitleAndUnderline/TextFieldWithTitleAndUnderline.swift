//
//  TextFieldWithTitleAndUnderline.swift
//  scrollToActiveControl
//
//  Created by Anton Halenda on 04.10.17.
//  Copyright © 2017 Anton Halenda. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

@IBDesignable
open class TextFieldWithTitleAndUnderline: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var underlineView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    open weak var delegate: TextFieldWithTitleAndUnderlineDelegate?
    
    fileprivate static let normalColor = UIColor(colorLiteralRed: 240/255, green: 240/255, blue: 241/255, alpha: 1.0)
    fileprivate var contentView: UIView?
    fileprivate var disposeBag: DisposeBag? = DisposeBag()
    fileprivate var maxLengthCharaters: Int?
    
    var bindModel:TextFieldWithTitleAndUnderlineBindModel? = nil {
        didSet{
            if bindModel != nil{
                clearOptionals()
                self.bindToValues(bindModel: bindModel!)
            }
        }
    }
    
    //MARK: Inspectable properties
    @IBInspectable var titleText: String = "" {
        didSet {
            setupView()
        }
    }
    
    @IBInspectable var placeholderText: String = "" {
        didSet {
            setupView()
        }
    }
    
    @IBInspectable var underlineColor: UIColor = normalColor {
        didSet {
            setupView()
        }
    }
    @IBInspectable var textFieldKeyboardType: String = "default" {
        didSet {
            setupView()
        }
    }
    
    @IBInspectable var errorText: String = "" {
        didSet {
            setupView()
        }
    }
    
    @IBInspectable var isSecuredInput: Bool = false {
        didSet {
            setupView()
        }
    }
    
    @IBInspectable var isEnabled: Bool = true {
        didSet {
            setupView()
        }
    }
    
    //MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        xibSetup()
    }
    
    internal func setupView(){
        self.titleLabel.text = titleText
        self.inputTextField.placeholder = placeholderText
        self.inputTextField.isEnabled = isEnabled
        self.underlineView.backgroundColor = underlineColor
        setTextFieldKeyboardType(type: textFieldKeyboardType)
        self.errorLabel.text = errorText
        self.inputTextField.isSecureTextEntry = isSecuredInput
        validateMaxLength()
        if inputTextField.keyboardType == .numberPad {
            validateNumberInput()
        }
    }
    
    open func setupControl(bindModel: TextFieldWithTitleAndUnderlineBindModel?, delegate: TextFieldWithTitleAndUnderlineDelegate?, maxLength: Int? = nil) {
        self.bindModel = bindModel
        self.delegate = delegate
        self.maxLengthCharaters = maxLength
    }
    
    //MARK: private functions
    internal func xibSetup() {
        self.addSubview(loadViewFromNib(viewClass: self.classForCoder))
        inputTextField.delegate = self
        inputTextField.isSecureTextEntry = isSecuredInput
    }
    
    fileprivate func bindToValues(bindModel: TextFieldWithTitleAndUnderlineBindModel) {
        disposeBag = bindModel.disposeBag
        
        if  let observableTitle = bindModel.titleString {
            observableTitle.observeOn(MainScheduler.instance).subscribe( onNext: {[weak self] value in
                self?.titleText = value
            }).addDisposableTo(disposeBag!)
        }
        
        if  let observableError = bindModel.errorString {
            
            observableError.observeOn(MainScheduler.instance).subscribe( onNext: {[weak self] value in
                self?.errorText = value
            }).addDisposableTo(disposeBag!)
        }
        
        (inputTextField.rx.textInput <-> bindModel.getTransformingVariable()).disposed(by: disposeBag!)
    }
    
    fileprivate func bindInputToObservableValue(rxValue: Variable<String>)  {
        (self.inputTextField.rx.textInput <-> rxValue).disposed(by: disposeBag!)
    }
    
    fileprivate func validateMaxLength() {
        let validText: Observable<String> = inputTextField.rx.text
            .orEmpty.map ({
                if self.maxLengthCharaters != nil && $0.characters.count > self.maxLengthCharaters! {
                    return $0.substring(to: $0.index($0.startIndex, offsetBy: self.maxLengthCharaters!))
                } else {
                    return $0
                }
            })
        validText.bindTo(inputTextField.rx.text).disposed(by: disposeBag!)
    }
    
    fileprivate func validateNumberInput() {
        let validText: Observable<String> = inputTextField.rx.text
            .orEmpty.map ({
                let punctuations = CharacterSet.decimalDigits.inverted
                return $0.components(separatedBy: punctuations).filter{!$0.isEmpty}.first ?? ""
            })
        validText.bindTo(inputTextField.rx.text).disposed(by: disposeBag!)
    }
    
    fileprivate func setTextFieldKeyboardType(type: String) {
        let keyboardType: UIKeyboardType?
        
        switch type {
        case "default":
            keyboardType = .default
        case "asciiCapable":
            keyboardType = .asciiCapable
        case "numbersAndPunctuation":
            keyboardType = .numbersAndPunctuation
        case "URL":
            keyboardType = .URL
        case "numberPad":
            keyboardType = .numberPad
        case "phonePad":
            keyboardType = .phonePad
        case "namePhonePad":
            keyboardType = .namePhonePad
        case "emailAddress":
            keyboardType = .emailAddress
        case "decimalPad":
            keyboardType = .decimalPad
        case "twitter":
            keyboardType = .twitter
        case "webSearch":
            keyboardType = .webSearch
        case "asciiCapableNumberPad":
            keyboardType = .asciiCapableNumberPad
            
        default:
            keyboardType = .default
        }
        self.inputTextField.keyboardType = keyboardType ?? .default
    }
    
    fileprivate func clearOptionals() {
        disposeBag = nil
        delegate = nil
    }
}
