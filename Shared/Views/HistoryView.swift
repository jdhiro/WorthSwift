//
//  HistoryView.swift
//  HistoryView
//
//  Created by Jason Farnsworth on 7/21/21.
//

import SwiftUI


struct PointTransaction: Codable, Hashable {
    var id: UInt
    var amount: Int
    var description: String?
    var createdby: String?
    var customerid: UInt
    var created_at: Date
    
    func getNiceDate() -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd,yyyy"
        return dateFormatterPrint.string(from: created_at)
    }
}

struct CreditTransaction: Codable, Hashable {
    var id: UInt
    var amount: Int
    var description: String?
    var createdby: String?
    var customerid: UInt
    var created_at: Date
        
    var formattedDate: String {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .medium
            return dateFormatter.string(from: created_at)
        }
    }
    
    var formattedAmount: String {
        get {
            let formatter = NumberFormatter()
            formatter.usesGroupingSeparator = true
            formatter.numberStyle = .currencyAccounting
            formatter.locale = Locale.current
            return formatter.string(from: NSNumber(value: Double(amount) / 10))!
        }
    }
}

struct CustomerHistory: Codable, Hashable {
    var creditTransactions: [CreditTransaction]
    var rewardTransactions: [PointTransaction]
}

struct HistoryView: View {
    var customer: CustomerDetail
    
    @State var pointTransactions: [PointTransaction] = []
    @State var creditTransactions: [CreditTransaction] = []
    @State var currentSegment = 0
    
    var body: some View {
        
        
        VStack {
            Picker(selection: $currentSegment, label: Text("")) {
                Text("Transactions").tag(0)
                Text("Points").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            List {
                ForEach(creditTransactions, id: \.self) { item in
                    Text("\(item.formattedAmount) \(item.formattedDate)")
                }
            }
        }
        .task {
            do {
                let history: CustomerHistory = try await fetch("/customer/\(customer.id)/history")
                pointTransactions = history.rewardTransactions
                creditTransactions = history.creditTransactions
            } catch {
                print("there was an error: \(error)")
            }
            print("ok")
        }
        
        

    }

}
/*
struct HistoryView_Previews: PreviewProvider {
    static let mockCustomer = CustomerDetail(
        id: 12345,
        phonenumber: "5555555555",
        firstname: "Sam",
        lastname: "Smith",
        cardnumber: "ABC123",
        email: nil,
        rewardbalance: 100,
        cashbalance: 100
    )
    static var previews: some View {
        HistoryView(customer: mockCustomer)
    }
}
*/
