//
//  WorthSwiftApp.swift
//  Shared
//
//  Created by Jason Farnsworth on 6/13/21.
//

import SwiftUI
import Sentry
import Foundation
import KeychainAccess

// Althought not needed for SwiftUI apps, create a AppDelegate here that will be imported into the main app via an adapter.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        /*SentrySDK.start { options in
            options.dsn = "https://76c777eb58ad41ae851250a46330149e@o218740.ingest.sentry.io/5948174"
            options.debug = true // Enabled debug when first installing is always helpful
        }*/
        return true
    }
}

@main
struct WorthSwiftApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// My App Stuff

struct Constants {
    static let httpScheme = "http"
    static let httpHost = "127.0.0.1"
    static let httpPort = 8081
    
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


/// Attempt to conver the string representation of money into cents. Treat empty strings as 0.
/// - Parameter str: String representation of money, for example "1.25" or "0.50".
/// - Throws: <#description#>
/// - Returns: UInt representating total amount of cents in the money value.
func currencyStrToUInt(_ str: String) throws -> UInt {
    let s = (str == "") ? "0" : str
    // This should take any reasonable USD string value and convert it into a decimal.
    let amount: Decimal = try Decimal(s, format: .currency(code: "USD"))
    // To prevent rounding errors, our backend treats all money as cents. Do that conversion here.
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
