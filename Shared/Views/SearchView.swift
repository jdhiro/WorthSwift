//
//  SearchView.swift
//  WorthSwift
//
//  Created by Jason Farnsworth on 6/19/21.
//

import SwiftUI
import PhoneNumberKit

struct CustomerDetail: Codable, Hashable {
    let id: UInt
    let phonenumber: String?
    let firstname: String
    let lastname: String
    let cardnumber: String?
    let email: String?
    let rewardbalance: UInt
    let cashbalance: UInt
}

struct NewCustomer: Codable {
    let firstname: String
    let lastname: String
    let phonenumber: String
}

struct NewCard: Codable {
    let cardnumber: String
    let amount: UInt
}

struct CustomerAccount: Codable {
    let id: UInt
}

struct SearchView: View {
    
    @Environment(\.dismiss) var dismiss
    
    enum Field: Hashable {
        case search
    }
    @FocusState var focusedField: Field?
    
    @State var searchText: String = ""
    @State var searchResults: [CustomerDetail] = []
    
    @State var isNewCustomerModalPresented = false
    @State var nameComponents = PersonNameComponents()
    @State var phoneNumber = ""
    
    @State var isNewCardModalPresented = false
    @State var cardNumber = ""
    
    @State var showSheetError = false
    @State var sheetErrorMessage = ""
    
    @State var controlDisabled = false
    
    func dismissDialogs() {
        isNewCustomerModalPresented = false
        isNewCardModalPresented = false
        
        showSheetError = false
        sheetErrorMessage = ""
        
        nameComponents = PersonNameComponents()
    }
    
    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
                .focused($focusedField, equals: .search)
                .modifier(TextFieldClearButton(text: $searchText))
                .autocapitalization(.allCharacters)
                .font(.largeTitle.weight(.semibold))
                .padding()
                //.overlay(RoundedRectangle(cornerRadius: 20).stroke(.black, lineWidth: 2))
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(.systemGray5))
                        )
                )
                .padding()
                .onChange(of: searchText) { str in
                    Task {
                        searchResults = try await fetch("/search", queryItems: [URLQueryItem(name: "q", value: str)])
                    }
                }
            if (searchResults.isEmpty) {
                Button("New Customer") {
                    isNewCustomerModalPresented = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                Button("New Card") {
                    isNewCardModalPresented = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                /*NavigationLink(destination: TestView()){
                    Label("test view", systemImage: "testtube.2")
                }*/
                Spacer()
            } else {
                List {
                    ForEach(searchResults, id: \.self) { result in
                        NavigationLink(destination: AccountActionsView(customer: result)) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(result.lastname + ", " + result.firstname).font(.title2.weight(.semibold))
                                Label(result.phonenumber ?? "No phone", systemImage: "phone.fill")
                                Label(result.cardnumber ?? "No card", systemImage: "creditcard.fill")
                            }
                            .padding()
                        }
                    }
                }
                .listStyle(.plain)
            }

        }
        .navigationBarItems(trailing: Menu {
            Button(action: {
                AppVars.token = nil
                dismiss()
            }) {
                Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
            }
            Button(action: {}){
                Label("Send feedback", systemImage: "doc.text")
            }
        } label: {
            Label("Settings", systemImage: "gearshape")
        })
        .onAppear() { focusedField = .search }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Find Customer")
        .onDisappear() { searchText = "" }
        .fullScreenCover(isPresented: $isNewCustomerModalPresented, onDismiss: { dismissDialogs() }) { newCustomerView }
        .fullScreenCover(isPresented: $isNewCardModalPresented, onDismiss: { dismissDialogs() }) { newCardView }
    }
    
    func addCard() async { //TODO: always getting an error here
        print("something")
        do {
            let post = NewCard(cardnumber: cardNumber, amount: 0)
            print(post)
            let res: CustomerAccount = try await fetch("/card", body: post, method: .post)
            print(res)
            searchText = "@\(res.id)"
            dismissDialogs()
        } catch {
            print("error")
            sheetErrorMessage = "Erorr adding card."
            showSheetError = true
        }
    }
    
    var newCardView : some View {
        NavigationView {
            VStack {
                TextField("Card Number", text: $cardNumber)
                    .textFieldStyle(CustomTextFieldStyle())
                HStack{
                    Spacer()
                    Button("Cancel", action: { dismissDialogs() })
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(controlDisabled)
                    Button("Add Card", action: {
                        Task {
                            await addCard()
                        }
                    })
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(controlDisabled)
                }
                Spacer()
            }
            .padding()
            .navigationBarTitle("New Card")
        }
    }
    
    func addCustomer() async {
        let phoneNumberKit = PhoneNumberKit()
        var pn: String?
        
        do {
            let v = try phoneNumberKit.parse(phoneNumber)
            pn = String(v.nationalNumber)
        }
        catch {
            pn = nil
        }
        
        if (
            nameComponents.familyName != nil &&
            nameComponents.givenName != nil &&
            pn != nil
        ) {
            do {
                let post = NewCustomer(
                    firstname: nameComponents.givenName!,
                    lastname: nameComponents.familyName!,
                    phonenumber: pn!
                )
                let res: CustomerAccount = try await fetch("/customer", body: post, method: .post)
                searchText = "@\(res.id)"
                dismissDialogs()
            } catch {
                sheetErrorMessage = "Erorr adding customer."
                showSheetError = true
            }
        } else {
            sheetErrorMessage = "Missing first name, last name, or phone number."
            showSheetError = true
        }
    }
    
    var newCustomerView: some View {
        NavigationView {
            VStack {
                TextField(
                    "First & last name",
                    value: $nameComponents,
                    format: .name(style: .long)
                )
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocapitalization(.words)
                PhoneTextField(phoneNumber: $phoneNumber)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.primary.opacity(0.5), lineWidth: 1))
                if (showSheetError == true) {
                    HStack {
                        Text(sheetErrorMessage)
                            .padding()
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
                HStack{
                    Spacer()
                    Button("Cancel") {
                        dismissDialogs()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(controlDisabled)
                    Button("Add Customer") {
                        Task {
                            await addCustomer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(controlDisabled)
                }
                Spacer()
            }
            .padding()
            .navigationBarTitle("New Customer")
            
        }
    }
    
    
    
    
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SearchView()
                .previewDevice("iPad Air (4th generation)")
        }
    }
}
