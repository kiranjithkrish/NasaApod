//
//  FavoritesView.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import SwiftUI

struct FavoritesView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Favorites", systemImage: "heart.fill")
            } description: {
                Text("Save your favorite APODs here")
            } actions: {
                Text("This feature is coming soon")
                    .font(theme.captionFont)
                    .foregroundColor(theme.textSecondary)
            }
            .navigationTitle("Favorites")
        }
    }
}

// MARK: - Preview

#Preview {
    FavoritesView()
        .theme(DefaultTheme())
}
