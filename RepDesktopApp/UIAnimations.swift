//
//  UIAnimations.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/17/26.
//
import Foundation
import SwiftUI


struct ShimmerText: View {
    let text: String

    @State private var shineOffset: CGFloat = 0

    var body: some View {
        Text(text)
            .opacity(0.35)
            .fontDesign(.rounded)
            .fontWeight(.medium)
            .overlay {
                GeometryReader { geo in
                    let shimmerWidth = geo.size.width * 0.9

                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.15),
                            .white.opacity(0.95),
                            .white.opacity(0.15),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: shimmerWidth)
                    .offset(x: shineOffset)
                    .mask {
                        Text(text)
                            .fontDesign(.rounded)
                            .fontWeight(.medium)
                    }
                    .onAppear {
                        shineOffset = -shimmerWidth

                        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                            shineOffset = geo.size.width + shimmerWidth
                        }
                    }
                }
            }
    }
}
