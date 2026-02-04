//
//  AppTheme.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import SwiftUI

protocol AppTheme {
    // MARK: - Colors

    var primaryColor: Color { get }
    var secondaryColor: Color { get }
    var accentColor: Color { get }
    var backgroundColor: Color { get }
    var cardBackground: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var errorColor: Color { get }

    // MARK: - Typography

    var titleFont: Font { get }
    var headlineFont: Font { get }
    var bodyFont: Font { get }
    var captionFont: Font { get }

    // MARK: - Layout

    var cornerRadius: CGFloat { get }
    var spacing: CGFloat { get }
    var padding: CGFloat { get }
}
