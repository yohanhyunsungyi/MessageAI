//
//  OnboardingView.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @State private var displayName: String = ""
    @State private var showSuccessPopup = false
    @State private var isProcessing = false

    var body: some View {
        ZStack {
            // Background
            Color.white
                .edgesIgnoringSafeArea(.all)

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 50)

                    // Onboarding form
                    VStack(spacing: 32) {
                        Text("Welcome to MessageAI")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)

                        // Profile photo (static)
                        Circle()
                            .fill(Color(hex: "CCFF00").opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(displayName.prefix(1).uppercased())
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundColor(.black)
                            )

                        // Display name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black)

                            TextField("John Doe", text: $displayName)
                                .font(.system(size: 15))
                                .padding(16)
                                .background(Color(hex: "F5F5F7"))
                                .cornerRadius(12)
                        }

                        // Get Started
                        Button {
                            // Show popup first
                            showSuccessPopup = true
                        } label: {
                            Text("Get Started")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(!displayName.isEmpty ? Color(hex: "CCFF00") : Color(hex: "D3D3D3"))
                                .cornerRadius(28)
                        }
                        .disabled(displayName.isEmpty || isProcessing)
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 100)
                }
            }

            // Success Popup Overlay
            if showSuccessPopup {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // Prevent dismiss on background tap
                    }

                VStack(spacing: 0) {
                    // Top decoration
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .offset(x: 10, y: -20)

                            Text("%")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.orange)
                                .offset(x: 10, y: -20)
                        }
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, -30)

                    VStack(spacing: 24) {
                        Spacer()
                            .frame(height: 20)

                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 120, height: 120)

                            Image(systemName: "checkmark")
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(Color(hex: "5DB99E"))
                        }

                        Text("Congratulations!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("Success is the result of hard work\nand perseverance.")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 8)

                        Button {
                            // Complete onboarding when OK button is tapped
                            isProcessing = true
                            Task {
                                do {
                                    try await authService.completeOnboarding(
                                        displayName: displayName,
                                        photoURL: nil
                                    )
                                    // needsOnboarding becomes false, automatically transitions to next screen
                                } catch {
                                    // Handle error
                                    showSuccessPopup = false
                                    isProcessing = false
                                }
                            }
                        } label: {
                            if isProcessing {
                                ProgressView()
                                    .tint(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "CCFF00"))
                                    .cornerRadius(28)
                            } else {
                                Text("OK")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "CCFF00"))
                                    .cornerRadius(28)
                            }
                        }
                        .disabled(isProcessing)
                        .padding(.horizontal, 30)

                        Spacer()
                            .frame(height: 20)
                    }
                }
                .frame(width: 320, height: 450)
                .background(Color(hex: "5DB99E"))
                .cornerRadius(32)
                .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthService())
}
