//
//  NewCustomerView.swift
//  NewCustomerView
//
//  Created by Jason Farnsworth on 7/25/21.
//

import SwiftUI

struct NewCustomerView: View {
    @State var firstName = ""
    @State var lastName = ""
    @State var phoneNumber = ""
    
    
    var body: some View {
        TextField("First Name", text: $firstName)
        TextField("Last Name", text: $lastName)
        TextField("Phone Number", text: $phoneNumber)
    }
}

struct NewCustomerView_Previews: PreviewProvider {
    static var previews: some View {
        NewCustomerView()
    }
}
