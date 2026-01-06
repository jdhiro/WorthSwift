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
                    gradient: Gradient(colors: [Color(red: 0.16, green: 0.20, blue: 0.40), Color(red: 0.54, green: 0.57, blue: 0.61)]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                  )).ignoresSafeArea()
            
            VStack() {
                NavigationLink("Work Folder", destination: SearchView(), isActive: $nextScreen).hidden()
                Image("logo").resizable().aspectRatio(contentMode: .fit)
                TextField("username", text: $formData.username)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .textContentType(.username)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.white))
                SecureField("password", text: $formData.password)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.white))
                Button(action: {
                    Task {
                        do {
                            let tokens = try await signIn(username: formData.username, password: formData.password)
                            AppVars.token = tokens.accessToken
                            AppVars.refreshToken = tokens.refreshToken
                            nextScreen = true
                        } catch {
                            showError = true
                        }
                    }
                }) {
                    Spacer()
                    Text("Sign In")
                    Spacer()
                }.buttonStyle(.borderedProminent).controlSize(.large).tint(.gray)
                
                if (showError) {
                    Text("Information not correct. Try again.")
                        .offset(y: -10)
                        .padding(10)
                        .foregroundColor(.red)
                }
            }
            .frame(width: 400)
            .padding(.all)
            //.background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 1, green: 1, blue: 1, opacity: 0.4)))
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
