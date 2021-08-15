//
//  AccountActionsView.swift
//  WorthSwift
//
//  Created by Jason Farnsworth on 6/19/21.
//

import SwiftUI
import Combine

struct RewardItem: Hashable {
    let name: String
    let points: UInt
}

struct BalanceTransactionReq: Codable {
    let customerid: UInt
    let credit: UInt
    let debit: UInt
    var description: String?
}

struct AccountActionsView: View {
    
    var customer: CustomerDetail
    
    @State var balanceCreditAmount = ""
    @State var balanceDebitAmount = ""
    // This is very hacky, but hold the last value so that we can reference it in onRecieve if needed.
    // https://stackoverflow.com/questions/58733003/swiftui-how-to-create-textfield-that-only-accepts-numbers/58736068#58736068
    @State var balanceCreditAmountLast = ""
    @State var balanceDebitAmountLast = ""
    
    @State var showSuccessAlert = false
    @State var showErrorAlert = false
    
    let rewards: [RewardItem] = [
        RewardItem(name: "Coffee", points: 500),
        RewardItem(name: "Blended Drink", points: 700)
    ]
    
    @State var selectedReward: String? = nil
    
    func moneyStrToInt(_: String) {
        
    }
    
    func submitBalanceTransaction() {
        Task {
            
            let n: Decimal = try Decimal(balanceCreditAmount, format: .currency(code: "USD"))
            //let i: Int = try Int(n)
            print(n)
            
            print((n * 100 as NSDecimalNumber).intValue)
            
            
            
            /*let req = BalanceTransactionReq(
                customerid: 1234,
                credit: 1234,
                debit: 1234
            )
            let data: CustomerDetail = try await fetch("/transaction", body: req, method: .post)*/
        }
    }
    
    func submitPointTransaction() {
        
    }
        
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(customer.firstname) \(customer.lastname)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    if (customer.cardnumber != nil) {
                        Text("Card #" + customer.cardnumber!)
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                }
                Spacer()
            }
            HStack {
                VStack {
                    HStack {
                        Text("Points \(customer.rewardbalance)")
                            .font(.title2).fontWeight(.semibold)
                        Spacer()
                    }
                    ForEach(rewards, id: \.self) { item in
                        SelectionCell(reward: item, selectedReward: self.$selectedReward)
                    }
                    Button("Claim Reward") {
                        showSuccessAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 5).stroke(.gray))
                VStack {
                    HStack {
                        Text("Balance \(customer.cashbalance)")
                            .font(.title2).fontWeight(.semibold)
                        Spacer()
                    }
                    TextField("Credit", text: $balanceCreditAmount)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(.green))
                        .keyboardType(.numberPad)
                        // This is a very hacky way to enforce money-like values into the input.
                        .onReceive(Just(balanceCreditAmount)) { newValue in
                            let b: Bool = newValue.range(of: #"^\d*\.?\d{0,2}$"#, options: .regularExpression) != nil
                            if b == true {
                                self.balanceCreditAmountLast = self.balanceCreditAmount
                            } else {
                                self.balanceCreditAmount = self.balanceCreditAmountLast
                            }
                        }
                    TextField("Debit", text: $balanceDebitAmount)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(.red))
                        .keyboardType(.numberPad)
                        // This is the same hack used above.
                        .onReceive(Just(balanceDebitAmount)) { newValue in
                            let b: Bool = newValue.range(of: #"^\d*\.?\d{0,2}$"#, options: .regularExpression) != nil
                            if b == true {
                                self.balanceDebitAmountLast = self.balanceDebitAmount
                            } else {
                                self.balanceDebitAmount = self.balanceDebitAmountLast
                            }
                        }
                    Button("Submit Transaction") { submitBalanceTransaction() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 5).stroke(.gray))
            }
            Spacer()
        }
        .padding()
        .alert("✅ Success!", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        }
        .navigationBarItems(trailing: NavigationLink(destination: HistoryView(customer: customer)) {
            Label("History", systemImage: "clock").labelStyle(TitleAndIconLabelStyle())
        })
    }

        
}

struct SelectionCell: View {
    let reward: RewardItem
    @Binding var selectedReward: String?

    var body: some View {
        HStack {
            if reward.name == selectedReward {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
            }
            Text(reward.name)
            Spacer()
            Text(String(reward.points))
        }
        .padding()
        .contentShape(Rectangle())
        .border(reward.name == selectedReward ? Color.accentColor : Color.black)
        .foregroundColor(reward.name == selectedReward ? Color.accentColor : Color.black)
        .onTapGesture {
            print("rewarded!")
            if (self.selectedReward == self.reward.name) {
                self.selectedReward = nil
            } else {
                self.selectedReward = self.reward.name
            }
        }
    }
}

struct AccountActionsView_Previews: PreviewProvider {
    
    static let mockCustomer = CustomerDetail(
        id: 12345,
        phonenumber: "5555555555",
        firstname: "Sam",
        lastname: "Smith",
        cardnumber: "ABC123",
        email: nil,
        rewardbalance: 1000,
        cashbalance: 100
    )
    
    static var previews: some View {
        AccountActionsView(customer: mockCustomer)
            
    }
}
