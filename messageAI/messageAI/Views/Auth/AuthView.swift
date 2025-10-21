//
//  AuthView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            // Background
            Color.white
                .edgesIgnoringSafeArea(.all)

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 상단 여백
                    Color.clear
                        .frame(height: 50)

                    // 타이틀
                    VStack(spacing: 6) {
                        Text("Step Into the Future")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.black)

                        Text("of Messaging")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.bottom, 32)

                    // Login/Register 탭
                    HStack(spacing: 0) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showSignUp = false
                            }
                        } label: {
                            Text("Login")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(showSignUp ? Color.white : Color(hex: "CCFF00"))
                                .cornerRadius(25)
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showSignUp = true
                            }
                        } label: {
                            Text("Register")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(showSignUp ? Color(hex: "CCFF00") : Color.white)
                                .cornerRadius(25)
                        }
                    }
                    .padding(4)
                    .background(Color.white)
                    .cornerRadius(29)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)

                    // Form
                    if showSignUp {
                        SignUpView(viewModel: viewModel)
                    } else {
                        SignInView(viewModel: viewModel)
                    }

                    // 하단 여백
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
    }
}

#Preview {
    AuthView()
}
