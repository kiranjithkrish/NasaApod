//
//  ShimmerModifier.swift
//  NasaApod
//
//  Created by kiranjith k k on 06/02/2026.
//

import SwiftUI

/// A view modifier that adds a shimmer animation effect for loading states
struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                }
                .clipped()
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    /// Adds a shimmer animation effect, useful for loading placeholders
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
