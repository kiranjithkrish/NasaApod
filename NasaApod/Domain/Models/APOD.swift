//
//  APOD.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// Astronomy Picture of the Day model
struct APOD: Codable, Sendable, Identifiable, Hashable {
    /// Date of the APOD (YYYY-MM-DD format)
    let date: String

    /// Title of the APOD
    let title: String

    /// Detailed explanation of the image/video
    let explanation: String

    /// URL to the media (image or video)
    let url: String

    /// Type of media (image or video)
    let mediaType: MediaType

    /// Optional high-resolution image URL
    let hdurl: String?

    /// Optional copyright information
    let copyright: String?

    /// Unique identifier for Identifiable conformance
    var id: String { date }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case date
        case title
        case explanation
        case url
        case mediaType = "media_type"
        case hdurl
        case copyright
    }

    // MARK: - Computed Properties

    /// Parsed date from string
    nonisolated var parsedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: date)
    }

    /// Check if high-resolution version is available
    var hasHDVersion: Bool {
        hdurl != nil && !hdurl!.isEmpty
    }

    /// Get best quality URL (HD if available, otherwise standard)
    var bestQualityURL: String {
        hdurl ?? url
    }

    /// Check if media is an image
    var isImage: Bool {
        mediaType == .image
    }

    /// Check if media is a video
    var isVideo: Bool {
        mediaType == .video
    }
}

// MARK: - Codable

/// Codable conformance moved to extension to preserve the memberwise initialiser
/// Methods marked nonisolated for Swift 6 actor isolation compatibility
extension APOD {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            date: try container.decode(String.self, forKey: .date),
            title: try container.decode(String.self, forKey: .title),
            explanation: try container.decode(String.self, forKey: .explanation),
            url: try container.decode(String.self, forKey: .url),
            mediaType: try container.decode(MediaType.self, forKey: .mediaType),
            hdurl: try container.decodeIfPresent(String.self, forKey: .hdurl),
            copyright: try container.decodeIfPresent(String.self, forKey: .copyright)
        )
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(title, forKey: .title)
        try container.encode(explanation, forKey: .explanation)
        try container.encode(url, forKey: .url)
        try container.encode(mediaType, forKey: .mediaType)
        try container.encodeIfPresent(hdurl, forKey: .hdurl)
        try container.encodeIfPresent(copyright, forKey: .copyright)
    }
}

// MARK: - Validation

extension APOD {
    /// Validate the APOD model
    /// - Throws: APODError if validation fails
    nonisolated func validate() throws {
        guard !date.isEmpty else {
            throw APODError.invalidData(reason: "Date is empty")
        }

        guard !title.isEmpty else {
            throw APODError.invalidData(reason: "Title is empty")
        }

        guard !url.isEmpty, URL(string: url) != nil else {
            throw APODError.invalidData(reason: "Invalid URL")
        }

        guard parsedDate != nil else {
            throw APODError.invalidData(reason: "Invalid date format")
        }

        let earliestDate = Constants.API.earliestDate
        let latestDate = Constants.API.latestDate

        guard let date = parsedDate, date >= earliestDate && date <= latestDate else {
            throw APODError.invalidDateRange(
                earliest: earliestDate,
                latest: latestDate
            )
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension APOD {
    /// Sample APOD for previews and testing
    static let sample = APOD(
        date: "2024-01-15",
        title: "The Orion Nebula",
        explanation: "The Orion Nebula is a diffuse nebula situated in the Milky Way, being south of Orion's Belt in the constellation of Orion.",
        url: "https://apod.nasa.gov/apod/image/2401/orion_nebula.jpg",
        mediaType: .image,
        hdurl: "https://apod.nasa.gov/apod/image/2401/orion_nebula_hd.jpg",
        copyright: "NASA/ESA"
    )

    /// Sample video APOD for testing
    static let sampleVideo = APOD(
        date: "2024-01-16",
        title: "Solar Eclipse Time-lapse",
        explanation: "A time-lapse video of a solar eclipse captured from Earth.",
        url: "https://www.youtube.com/embed/abcd123",
        mediaType: .video,
        hdurl: nil,
        copyright: nil
    )
}
#endif
