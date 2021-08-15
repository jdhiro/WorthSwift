//
//  AppVars.swift
//  WorthSwift
//
//  Created by Jason Farnsworth on 6/16/21.
//

import Foundation
import KeychainAccess

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
