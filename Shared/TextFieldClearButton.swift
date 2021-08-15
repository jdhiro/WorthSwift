//
//  TextFieldClearButton.swift
//  TextFieldClearButton
//
//  Created by Jason Farnsworth on 8/7/21.
//

import SwiftUI

// https://sanzaru84.medium.com/swiftui-how-to-add-a-clear-button-to-a-textfield-9323c48ba61c
struct TextFieldClearButton: ViewModifier {
    @Binding var text: String
    
    func body(content: Content) -> some View {
        HStack {
            content
            
            if !text.isEmpty {
                Button(
                    action: { self.text = "" },
                    label: {
                        Image(systemName: "delete.left")
                            .foregroundColor(Color(UIColor.opaqueSeparator))
                    }
                )
            }
        }
    }
}
