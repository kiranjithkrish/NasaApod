//
//  DefaultTheme.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import SwiftUI

/// Default theme using standard iOS styling
struct DefaultTheme: AppTheme {
    // MARK: - Colors

    var primaryColor: Color {
        Color.blue
    }

    var secondaryColor: Color {
        Color.secondary
    }

    var accentColor: Color {
        Color.accentColor
    }

    var backgroundColor: Color {
        Color(uiColor: .systemBackground)
    }

    var cardBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }

    var textPrimary: Color {
        Color.primary
    }

    var textSecondary: Color {
        Color.secondary
    }

    var errorColor: Color {
        Color.red
    }

    // MARK: - Typography

    var titleFont: Font {
        .largeTitle.weight(.bold)
    }

    var headlineFont: Font {
        .headline
    }

    var bodyFont: Font {
        .body
    }

    var captionFont: Font {
        .caption
    }

    // MARK: - Layout

    var cornerRadius: CGFloat {
        Constants.UI.cornerRadius
    }

    var spacing: CGFloat {
        Constants.UI.spacing
    }

    var padding: CGFloat {
        Constants.UI.spacing
    }
}
