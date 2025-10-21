//
//  UsersListView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

struct UsersListView: View {
    @StateObject private var viewModel = UsersViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var searchText = ""
    @State private var selectedUser: User?
    @State private var showChat = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                UIStyleGuide.Colors.background
                    .edgesIgnoringSafeArea(.all)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if viewModel.isLoading && viewModel.filteredUsers.isEmpty {
                            ProgressView()
                                .padding(40)
                        } else if viewModel.filteredUsers.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)

                                Text("No Users Found")
                                    .font(.system(size: 18, weight: .semibold))

                                Button {
                                    Task {
                                        await viewModel.refresh()
                                    }
                                } label: {
                                    Text("Refresh")
                                        .secondaryButtonStyle()
                                        .frame(width: 200)
                                }
                            }
                            .padding(40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredUsers) { user in
                                    Button {
                                        selectedUser = user
                                        showChat = true
                                    } label: {
                                        UserRowView(user: user)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                    }
                }
            }
            .navigationTitle("Users")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search users")
            .onChange(of: searchText) { _, newValue in
                viewModel.searchQuery = newValue
            }
            .sheet(isPresented: $showChat) {
                Text("Chat coming in PR #13")
            }
            .onAppear {
                viewModel.loadUsers()
                viewModel.startListening()
            }
        }
    }
}

#Preview {
    UsersListView()
        .environmentObject(AuthService())
}
