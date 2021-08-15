//
//  TestView.swift
//  TestView
//
//  Created by Jason Farnsworth on 8/7/21.
//

import SwiftUI
import Combine

struct TestView: View {
    
    @State var v = ""
    @State var x = ""

    var body: some View {
        VStack {
            TextField("Number", text: $v)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .onReceive(Just(v)) { newValue in

                    let b: Bool = newValue.range(of: #"^\d*\.?\d{0,2}$"#, options: .regularExpression) != nil
                    print(b)
                    
                    if b == true {

                        self.x = self.v
                    } else {
                        self.v = self.x
                    }
                }
        }
      }
}
