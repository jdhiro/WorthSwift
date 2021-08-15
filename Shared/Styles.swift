//
//  Styles.swift
//  Styles
//
//  Created by Jason Farnsworth on 7/15/21.
//

import Foundation
import SwiftUI

/*struct PrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      Spacer()
      configuration.label
      Spacer()
    }
    .padding()
    .foregroundColor(.white)
    .background(Color.accentColor)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .scaleEffect(configuration.isPressed ? 0.95 : 1)
  }
}
    
struct SecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      Spacer()
      configuration.label
      Spacer()
    }
    .padding()
    .foregroundColor(Color.accentColor)
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.accentColor)
    )
    .scaleEffect(configuration.isPressed ? 0.95 : 1)
  }
}
*/


public struct CustomTextFieldStyle : TextFieldStyle {
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .dynamicTypeSize(.xLarge)
            .padding()
            .background(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.primary.opacity(0.5), lineWidth: 1))
    }
}
