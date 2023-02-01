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

struct PointTransactionReq: Codable {
    let customerid: UInt
    let amount: UInt
    var description: String = ""
}

fileprivate let rewards: [RewardItem] = [
    RewardItem(name: "Free coffee", points: 50),
    RewardItem(name: "Free blended drink", points: 65)
]

var inputDisabled = false

struct AccountActionsView: View {
    @State var customer: CustomerDetail // Passed in from the calling view
    
    @State var balanceCreditAmount = ""
    @State var balanceDebitAmount = ""
    // This is very hacky, but hold the last value so that we can reference it in onRecieve if needed.
    // https://stackoverflow.com/questions/58733003/swiftui-how-to-create-textfield-that-only-accepts-numbers/58736068#58736068
    @State var balanceCreditAmountLast = ""
    @State var balanceDebitAmountLast = ""
    
    @State var showSuccessAlert = false
    @State var showErrorAlert = false
    
    @State var selectedReward: String?
    @State var selectedRewardPoints: UInt?
    
    func submitBalanceTransaction() {
        Task {
            do {
                inputDisabled = true
                let creditAmt = try currencyStrToUInt(balanceCreditAmount)
                let debitAmt = try currencyStrToUInt(balanceDebitAmount)
                if (creditAmt > 0 || debitAmt > 0) {
                    let req = BalanceTransactionReq(customerid: customer.id, credit: creditAmt, debit: debitAmt )
                    let res: CustomerDetail = try await fetch("/transaction", body: req, method: .post)
                    customer = res
                    showSuccessAlert = true
                }
                inputDisabled = false
            } catch {
                showErrorAlert = true
                inputDisabled = false
            }
        }
    }
    
    func submitPointTransaction() {
        // TODO: Fix this so that the backend is called with a rewardId, not a specific points amount. This is messy right now tracking points and values as two different values.
        Task {
            do {
                inputDisabled = true
                if (selectedReward != nil && selectedRewardPoints != nil) {
                    let amt = selectedRewardPoints!
                    let desc = selectedReward!
                    let req = PointTransactionReq(customerid: customer.id, amount: amt, description: desc )
                    let res: CustomerDetail = try await fetch("/transaction/reward", body: req, method: .post)
                    customer = res
                    showSuccessAlert = true
                }
                inputDisabled = false
            } catch {
                showErrorAlert = true
                inputDisabled = false
            }
        }
    }
    
    func resetForms() {
        balanceCreditAmount = ""
        balanceDebitAmount = ""
        balanceCreditAmountLast = ""
        balanceDebitAmountLast = ""
        showSuccessAlert = false
        showErrorAlert = false
        selectedReward = nil
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
                if(customer.rewardbalance != nil) {
                    pointsBox
                }
                balanceBox
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showSuccessAlert, onDismiss: { resetForms() }) { successSheetView }
        .sheet(isPresented: $showErrorAlert, onDismiss: { resetForms() }) { errorSheetView }
        .navigationBarItems(trailing: NavigationLink(destination: HistoryView(customer: customer)) {
            Label("History", systemImage: "clock").labelStyle(TitleAndIconLabelStyle())
        })
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var pointsBox : some View {
        VStack {
            HStack {
                Text("Points \(customer.rewardbalance!)")
                    .font(.title2).fontWeight(.semibold)
                Spacer()
            }
            ForEach(rewards, id: \.self) { item in
                SelectionCell(reward: item, selectedReward: self.$selectedReward, selectedRewardPoints: self.$selectedRewardPoints)
            }
            Button("Claim Reward") { submitPointTransaction() }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(inputDisabled)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 5).stroke(.gray))
    }
    
    var balanceBox : some View {
        VStack {
            HStack {
                Text("Balance \(currencyUIntToStr(customer.cashbalance))")
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
                .disabled(inputDisabled)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 5).stroke(.gray))
    }
    
    var successSheetView : some View {
        VStack {
            Image("thumbs-up")
                .resizable()
                .frame(width: 500, height: 500)
            Button(action: { showSuccessAlert.toggle() }) {
                Text("Done")
            }.buttonStyle(.borderedProminent).controlSize(.large)
        }
    }
    
    var errorSheetView: some View {
        Text("There was an error submitting the transaction.")
    }

        
}

struct SelectionCell: View {
    let reward: RewardItem
    @Binding var selectedReward: String?
    @Binding var selectedRewardPoints: UInt?

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
            if (self.selectedReward == self.reward.name) {
                self.selectedReward = nil
                self.selectedRewardPoints = nil
            } else {
                self.selectedReward = self.reward.name
                self.selectedRewardPoints = self.reward.points
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
