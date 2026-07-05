//
//  UIComponents.swift
//  RepDesktopApp
//
//  Created by alex haidar on 7/4/26.
//
import SwiftUI
import Foundation



struct Waveform: View {
    let audioLevel: Double
    let isRecording: Bool
    let isPaused: Bool

    private let phases: [Double] = [0.18, 0.65, 0.75, 1.08, 1.12, 1.08, 0.75, 0.65, 0.18, 0.18, 0.65, 0.75, 1.08, 1.12, 1.08, 0.75, 0.65,
                                    0.18, 0.18, 0.65, 0.75, 1.08, 1.12, 1.08, 0.75, 0.65, 0.18]

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.15, paused: !isRecording || isPaused || audioLevel <= 0.03)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let isActive = isRecording && !isPaused && audioLevel > 0.03
            let curve = isActive ? 0.85 : 0.0

            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<27, id: \.self) { index in
                    let phase = phases[index]
                    let sine = sin((time * 4.8) + (phase * .pi * 2))
                    let normalized = (sine + 1) / 2
                    let idleHeight = 21.0
                    let height = isActive ? idleHeight + normalized * 24.0 * curve : idleHeight

                    Capsule()
                        .frame(width: 5, height: height)
                        .foregroundStyle(Color.kimchilabsReversed)
                }
            }
            .frame(height: 42, alignment: .center)
        }
    }
}


#Preview {
    Waveform(audioLevel: 3.0, isRecording: true, isPaused: false)
}
