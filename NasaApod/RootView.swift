//
//  RootView.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab = .today
    @State private var container = DependencyContainer()

    var body: some View {
        TabView(selection: $selectedTab) {
            // Today Tab
            TodayView(
                viewModel: container.makeTodayViewModel(),
                imageCache: container.imageCache
            )
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }
                .tag(AppTab.today)

            // Explore Tab
            ExploreView(
                viewModel: container.makeExploreViewModel(),
                imageCache: container.imageCache
            )
                .tabItem {
                    Label("Explore", systemImage: "safari.fill")
                }
                .tag(AppTab.explore)

            // Favorites Tab
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
                .tag(AppTab.favorites)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(AppTab.settings)
        }
        .theme(DefaultTheme())
    }
}

#Preview {
    RootView()
}
