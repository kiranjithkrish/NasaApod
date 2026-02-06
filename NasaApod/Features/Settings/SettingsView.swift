//
//  SettingsView.swift
//  NasaApod
//
//  Created by kiranjith k k on 05/02/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Settings", systemImage: "gear")
            } description: {
                Text("App settings and preferences")
            } actions: {
                Text("This feature is coming soon")
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .theme(DefaultTheme())
}
