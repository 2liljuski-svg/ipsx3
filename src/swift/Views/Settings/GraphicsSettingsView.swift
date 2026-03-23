// GraphicsSettingsView.swift — Renderer and upscale settings
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI

struct GraphicsSettingsView: View {
    @State private var settings = SettingsStore.shared

    var body: some View {
        Form {
            Section("Renderer") {
                Text("Metal (Hardware)")
                    .foregroundStyle(.primary)
                Text("Renderer is currently fixed to Metal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Upscaling") {
                Picker("Internal Resolution", selection: $settings.upscaleMultiplier) {
                    Text("1x (Native PS2)").tag(Float(1.0))
                    Text("2x").tag(Float(2.0))
                    Text("3x").tag(Float(3.0))
                }
            }

            Section("VSync") {
                Stepper("Queue Size: \(settings.vsyncQueueSize)", value: $settings.vsyncQueueSize, in: 2...16)
                Text("Higher values reduce frame drops but increase latency.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Graphics")
        .navigationBarTitleDisplayMode(.inline)
    }
}
