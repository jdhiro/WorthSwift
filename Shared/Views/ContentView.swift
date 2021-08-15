//
//  ContentView.swift
//  Shared
//
//  Created by Jason Farnsworth on 6/13/21.
//

import SwiftUI

struct NavigationConfigurator: UIViewControllerRepresentable {
    var configure: (UINavigationController) -> Void = { _ in }

    func makeUIViewController(context: UIViewControllerRepresentableContext<NavigationConfigurator>) -> UIViewController {
        UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<NavigationConfigurator>) {
        if let nc = uiViewController.navigationController {
            self.configure(nc)
        }
    }

}

struct ContentView: View {
    var body: some View {
        if #available(macOS 12.0, *) {
            NavigationView {
                AuthView()
                    
            }
            .navigationViewStyle(StackNavigationViewStyle())
        } else {
            Text("macOS 12.0+ required.")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPad Air (4th generation)")
    }
}
