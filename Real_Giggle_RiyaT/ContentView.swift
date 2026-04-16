//
//  ContentView.swift
//  Giggle_RiyaTad
//
//  Created by Riya Tadinada on 3/10/26.
// content view will be especially useful for me later when I have to code the navigation through the provider's perspecitve

import SwiftUI

struct ContentView: View {
    @State private var showProviderAlert = false
    // remove the receiver alert in favor of navigation
    @State private var showReceiverAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Logo circle: light gray background with your branded image (if added to assets as "GiggleLogo")
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 200, height: 200)

                    // If you add an asset named "GiggleLogo" it will appear here. Otherwise the gray circle remains.
                    Image("GiggleLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                }
                
                .padding(.top, 40)

                Spacer()

                VStack(spacing: 20) {
                    NavigationLink(destination: AuthChoiceView(role: .provider)) {
                        Text("I AM A SERVICE PROVIDER")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                    }
                    .background(Color.orange.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.horizontal, 40)

                    // NavigationLink to AuthChoiceView for receivers
                    NavigationLink(destination: AuthChoiceView()) {
                        Text("I AM A SERVICE RECEIVER")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                    }
                    .background(Color.orange.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.horizontal, 40)
                }

                Spacer()
             }
             .navigationTitle("")
             .navigationBarHidden(true)
             .padding()
         }
     }
 }

#Preview {
    ContentView()
        .environmentObject(Session())
        .environment(\.session, Session())
}
