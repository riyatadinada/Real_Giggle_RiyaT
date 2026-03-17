//
//  ContentView.swift
//  Giggle_RiyaTad
//
//  Created by Riya Tadinada on 3/10/26.
//

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
                    Button {
                        showProviderAlert = true
                    } label: {
                        Text("I AM A SERVICE PROVIDER")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                    }
                    .background(Color.orange.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.horizontal, 40)
                    .alert("Provider selected", isPresented: $showProviderAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("This will navigate to the provider flow.")
                    }

                    // NavigationLink to ExploreView for receivers
                    NavigationLink(destination: ExploreView()) {
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
                // Bottom toolbar visible on landing for both roles
                BottomToolbar(role: .both)
             }
             .navigationTitle("")
             .navigationBarHidden(true)
             .padding()
         }
     }
 }

#Preview {
    ContentView()
}
