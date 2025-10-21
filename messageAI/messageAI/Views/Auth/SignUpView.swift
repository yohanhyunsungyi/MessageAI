//
//  SignUpView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)

                TextField("Email", text: $viewModel.email)
                    .font(.system(size: 14))
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(16)
                    .background(Color(hex: "F1F2F4"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "E7E8EA"), lineWidth: 1)
                    )
            }

            // Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)

                HStack {
                    SecureField("••••••••••", text: $viewModel.password)
                        .font(.system(size: 14))

                    Button {} label: {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.gray)
                    }
                }
                .padding(16)
                .background(Color(hex: "F1F2F4"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "E7E8EA"), lineWidth: 1)
                )
            }

            // Confirm Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)

                HStack {
                    SecureField("••••••••••", text: $viewModel.confirmPassword)
                        .font(.system(size: 14))

                    Button {} label: {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.gray)
                    }
                }
                .padding(16)
                .background(Color(hex: "F1F2F4"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "E7E8EA"), lineWidth: 1)
                )
            }

            // Sign Up 버튼
            Button {
                Task {
                    await viewModel.signUp()
                }
            } label: {
                Text("Sign Up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(viewModel.canSignUp ? Color(hex: "CCFF00") : Color(hex: "D3D3D3"))
                    .cornerRadius(28)
            }
            .disabled(!viewModel.canSignUp)
            .padding(.top, 8)

            // Divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color(hex: "E0E0E0"))
                    .frame(height: 1)

                Text("Or continue with")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)

                Rectangle()
                    .fill(Color(hex: "E0E0E0"))
                    .frame(height: 1)
            }
            .padding(.vertical, 12)

            // Social buttons
            HStack(spacing: 12) {
                Button {
                    Task {
                        await viewModel.signInWithGoogle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                        Text("Google")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color(hex: "E0E0E0"), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview("Sign Up") {
    SignUpView(viewModel: AuthViewModel())
}
