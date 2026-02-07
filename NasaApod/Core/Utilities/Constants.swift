//
//  Constants.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

enum Constants {
    // MARK: - NASA API Configuration

    enum API {
        nonisolated static let baseURL = "https://api.nasa.gov/planetary/apod"

        /// API key for NASA APOD service (free public API, not sensitive)
        /// Note: Hardcoded for demo. Production apps should avoid client secrets entirely:
        /// - Backend proxy: API key stays server-side, client never sees it
        /// - On-device secrets are always extractable via reverse-engineering
        nonisolated static let apiKey = "xrtPISSNCl9x1kk8ucrVIVKOAxKCdukvZSQNnNgy"

        /// Request timeout in seconds
        nonisolated static let timeoutInterval: TimeInterval = 30.0

        /// Date range limits for APOD
        nonisolated static let earliestDate = Calendar.current.date(from: DateComponents(year: 1995, month: 6, day: 16))!
        nonisolated static var latestDate: Date { Date() }
    }

    // MARK: - Cache Configuration

    enum Cache {
        /// Maximum age for cached images (30 days)
        static let maxImageAge: TimeInterval = 30 * 24 * 60 * 60

        /// Cache directory name
        static let directoryName = "APODCache"

        /// Last successful cache key
        static let lastSuccessfulKey = "lastSuccessful"
    }

    // MARK: - UI Configuration

    enum UI {
        /// Default animation duration
        static let animationDuration: TimeInterval = 0.3

        /// Default corner radius
        static let cornerRadius: CGFloat = 12.0

        /// Default spacing
        static let spacing: CGFloat = 16.0
    }

    // MARK: - App Info

    enum AppInfo {
        static let name = "NASA APOD"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let attribution = "Powered by NASA's Astronomy Picture of the Day API"
    }
}
