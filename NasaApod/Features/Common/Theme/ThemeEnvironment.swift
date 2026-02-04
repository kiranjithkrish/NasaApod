//
//  ThemeEnvironment.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import SwiftUI

/// Environment key for theme
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = DefaultTheme()
}

extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Apply a theme to the view hierarchy
    func theme(_ theme: AppTheme) -> some View {
        environment(\.theme, theme)
    }
}

