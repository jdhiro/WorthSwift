//
//  WorthSwiftApp.swift
//  Shared
//
//  Created by Jason Farnsworth on 6/13/21.
//

import SwiftUI
import Foundation
import KeychainAccess

@main
struct WorthSwiftApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// My App Stuff

struct Constants {
    static let baseURL = "http://127.0.0.1:8081"
}


private let keychain = Keychain(service: "io.hiro.worth")

struct AppVars {
    
    static var token: String? {
        get {
            return keychain["app-token"]
        }
        set(str) {
            keychain["app-token"] = str
        }
    }
    
}

func currencyUIntToStr(_ val: UInt) -> String {
    var c = Decimal(val)
    c = c / 100
    
    let nf = NumberFormatter()
    nf.numberStyle = .currency
    
    return nf.string(from: c as NSDecimalNumber)!
}

func currencyStrToUInt(_ str: String) throws -> UInt {
    let amount: Decimal = try Decimal(str, format: .currency(code: "USD"))
    let cents: UInt = (amount * 100 as NSDecimalNumber).uintValue
    return cents
}

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
