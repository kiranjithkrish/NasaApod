//
//  MediaType.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// Type of media content
enum MediaType: String, Codable, Sendable {
    case image
    case video

    /// Display name for UI
    var displayName: String {
        switch self {
        case .image:
            return "Image"
        case .video:
            return "Video"
        }
    }
}
