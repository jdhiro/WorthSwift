//
//  PhoneTextField.swift
//  PhoneTextField
//
//  Created by Jason Farnsworth on 8/1/21.
//

import SwiftUI
import PhoneNumberKit

struct PhoneTextField: UIViewRepresentable {
    @Binding var phoneNumber: String
    private let textField = PhoneNumberTextField()
    
    func makeUIView(context: Context) -> PhoneNumberTextField {
        textField.addTarget(context.coordinator, action: #selector(Coordinator.onTextChange), for: .editingChanged)
        textField.placeholder = "Phone number"
        textField.font = UIFont.systemFont(ofSize: 20)
        return textField
    }
    
    func updateUIView(_ uiView: PhoneNumberTextField, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    typealias UIViewType = PhoneNumberTextField
    
    class Coordinator:  NSObject, UITextFieldDelegate {
        var delegate: PhoneTextField
        
        init(_ delegate: PhoneTextField) {
            self.delegate = delegate
        }
        
        @objc func onTextChange(textField: UITextField) {
            self.delegate.phoneNumber = textField.text!
        }
    }
}
