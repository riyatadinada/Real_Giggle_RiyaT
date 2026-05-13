//
//  ContentView.swift
//  Giggle_RiyaTad
//
//  Created by Riya Tadinada on 3/10/26.
// content view will be especially useful for me later when I have to code the navigation through the provider's perspecitve

import SwiftUI

struct ContentView: View {
    @Environment(\.session) private var session: Session?
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

                // (Removed BubbleCloud preview to avoid showing bubbles on the welcome/login landing page)

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

struct PostRow: View {
    @Environment(\.session) private var session: Session?
    let post: ServicePost

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(post.text)
                .font(.body)
                .foregroundStyle(.primary)
            HStack(spacing: 8) {
                let canShowName = session?.messagedUserIDs.contains(post.author.id) == true
                Text(canShowName ? "\(post.author.firstName) \(post.author.lastName)" : "Anonymous")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(post.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture {
            // Consider this as "clicked message xxx person" to reveal the name thereafter
            if let id = session?.currentUser?.id, id != post.author.id {
                session?.markMessaged(with: post.author.id)
            }
        }
    }
}
