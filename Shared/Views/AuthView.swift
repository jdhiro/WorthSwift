//
//  AuthView.swift
//  WorthSwift
//
//  Created by Jason Farnsworth on 6/13/21.
//

import SwiftUI
import KeychainAccess

/// Username and password, to be convert to JSON object for authenticating the user.
struct SignInRequest: Codable {
    var username: String = ""
    var password: String = ""
}

/// Authentication response, containing only a JWT.
struct SignInResponse: Codable {
    let token: String
}

@available(macOS 12.0, *)
struct AuthView: View {
    
    @State private var formData = SignInRequest()
    @State private var showError = false
    @State private var nextScreen = false
    
    private let keychain = Keychain(service: "io.hiro.worth")
    //
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.46, green: 0.50, blue: 0.60), Color(red: 0.84, green: 0.87, blue: 0.91)]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                  )).ignoresSafeArea()
            
            VStack() {
                NavigationLink("Work Folder", destination: SearchView(), isActive: $nextScreen).hidden()
                Text("Worth")
                    .font(.headline)
                TextField("username", text: $formData.username)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
                SecureField("password", text: $formData.password)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {
                    Task {
                        do {
                            let signInResponse: SignInResponse = try await fetch("/auth", body: formData, method: .post)
                            AppVars.token = signInResponse.token
                            nextScreen = true
                        } catch {
                            showError = true
                        }
                    }
                }) {
                    Spacer()
                    Text("Sign In")
                    Spacer()
                }.buttonStyle(.borderedProminent).controlSize(.large)
                
                Button(action: {
                    formData.username = "jason"
                    formData.password = "DyzRvqZcYrq2BqJa"
                }) {
                    Spacer()
                    Text("Do Magic")
                    Spacer()
                }.buttonStyle(.bordered).controlSize(.large).tint(.accentColor)
                
                if (showError) {
                    Text("Information not correct. Try again.")
                        .offset(y: -10)
                        .padding(10)
                        .foregroundColor(.red)
                }
            }
            .frame(width: 400)
            .padding(.all)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 1, green: 1, blue: 1, opacity: 0.4)))
        }.onAppear() {
            if (AppVars.token != nil) {
                nextScreen = true
            }
        }
        

    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(macOS 12.0, *) {
            AuthView()
                .background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color.orange/*@END_MENU_TOKEN@*/)
        } else {
            // Fallback on earlier versions
        }
    }
}


