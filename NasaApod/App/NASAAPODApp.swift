//
//  NASAAPODApp.swift
//  NasaApod
//
//  Created by kiranjith k k on 04/02/2026.
//

import SwiftUI

@main
struct NASAAPODApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - App Tabs

enum AppTab: String, Hashable {
    case today
    case explore
    case favorites
    case settings
}
