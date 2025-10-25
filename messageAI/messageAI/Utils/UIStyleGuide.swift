//
//  UIStyleGuide.swift
//  messageAI
//
//  Created by Yohan Yi on 10/21/25.
//

import SwiftUI

/// Central design system for consistent UI styling across the app
/// Inspired by modern, clean design with lime accent colors
enum UIStyleGuide {

    // MARK: - Colors

    enum Colors {
        static let primary = Color(hex: "D4FF00")          // Lime yellow
        static let primaryDark = Color(hex: "B8E000")      // Darker lime
        static let secondary = Color(hex: "5EC792")        // Teal/green (from congratulations popup)
        static let background = Color.white
        static let cardBackground = Color(hex: "F8F8F8")
        static let textPrimary = Color.black
        static let textSecondary = Color(hex: "666666")
        static let textTertiary = Color(hex: "999999")
        static let border = Color(hex: "E0E0E0")
        static let success = Color(hex: "5EC792")
        static let error = Color(hex: "FF6B6B")
        static let online = Color(hex: "4CAF50")
        static let offline = Color(hex: "BDBDBD")

        // Tab bar colors
        static let tabBarBackground = Color.white
        static let tabBarSelected = Color.black
        static let tabBarUnselected = Color(hex: "BDBDBD")
    }

    // MARK: - Typography

    enum Typography {
        // Titles
        static let largeTitle = Font.system(size: 28, weight: .bold)
        static let title = Font.system(size: 24, weight: .bold)
        static let title2 = Font.system(size: 20, weight: .semibold)
        static let title3 = Font.system(size: 18, weight: .semibold)

        // Body
        static let body = Font.system(size: 16, weight: .regular)
        static let bodyBold = Font.system(size: 16, weight: .semibold)
        static let bodySmall = Font.system(size: 14, weight: .regular)

        // Caption
        static let caption = Font.system(size: 12, weight: .regular)
        static let captionBold = Font.system(size: 12, weight: .medium)

        // Button
        static let button = Font.system(size: 16, weight: .semibold)
        static let buttonLarge = Font.system(size: 18, weight: .semibold)
    }

    // MARK: - Spacing

    enum Spacing {
        // swiftlint:disable:next identifier_name
        static let xs: CGFloat = 4
        // swiftlint:disable:next identifier_name
        static let sm: CGFloat = 8
        // swiftlint:disable:next identifier_name
        static let md: CGFloat = 16
        // swiftlint:disable:next identifier_name
        static let lg: CGFloat = 24
        // swiftlint:disable:next identifier_name
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
        static let pill: CGFloat = 50
    }

    // MARK: - Shadows

    enum Shadow {
        static let light = (color: Color.black.opacity(0.05), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.1), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(4))
        static let heavy = (color: Color.black.opacity(0.15), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }

    // MARK: - Icon Sizes

    enum IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
    }
}

// MARK: - View Extensions

extension View {
    /// Apply primary button style (lime yellow)
    func primaryButtonStyle() -> some View {
        self
            .font(UIStyleGuide.Typography.button)
            .foregroundColor(UIStyleGuide.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(UIStyleGuide.Colors.primary)
            .cornerRadius(UIStyleGuide.CornerRadius.pill)
    }

    /// Apply secondary button style (outlined)
    func secondaryButtonStyle() -> some View {
        self
            .font(UIStyleGuide.Typography.button)
            .foregroundColor(UIStyleGuide.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(UIStyleGuide.CornerRadius.pill)
            .overlay(
                RoundedRectangle(cornerRadius: UIStyleGuide.CornerRadius.pill)
                    .stroke(UIStyleGuide.Colors.border, lineWidth: 1.5)
            )
    }

    /// Apply card style
    func cardStyle() -> some View {
        self
            .background(Color.white)
            .cornerRadius(UIStyleGuide.CornerRadius.large)
            .shadow(
                color: UIStyleGuide.Shadow.light.color,
                radius: UIStyleGuide.Shadow.light.radius,
                x: UIStyleGuide.Shadow.light.x,
                y: UIStyleGuide.Shadow.light.y
            )
    }

    /// Apply light shadow
    func lightShadow() -> some View {
        self.shadow(
            color: UIStyleGuide.Shadow.light.color,
            radius: UIStyleGuide.Shadow.light.radius,
            x: UIStyleGuide.Shadow.light.x,
            y: UIStyleGuide.Shadow.light.y
        )
    }
}
