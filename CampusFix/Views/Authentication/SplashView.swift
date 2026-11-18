//
//  SplashView.swift
//  CampusFix
//
//  Shows the official CampusFix logo (Assets: CampusFixLogo) on the logo's
//  own navy colour, so the logo tile blends into the screen.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false   // local UI state for the entrance animation

    var body: some View {
        ZStack {
            AppTheme.logoBackground
                .ignoresSafeArea()

            CampusFixLogo(size: 300)
                .scaleEffect(isAnimating ? 1 : 0.85)
                .opacity(isAnimating ? 1 : 0)
                .padding(.horizontal, 24)

            VStack {
                Spacer()
                ProgressView()
                    .tint(.white)
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}
