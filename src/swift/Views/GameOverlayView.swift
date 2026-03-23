// GameOverlayView.swift — In-game overlay (controller + menu button)
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI

struct GameOverlayView: View {
    @State private var appState = AppState.shared
    @State private var settings = SettingsStore.shared
    @State private var padVisible = true

    var body: some View {
        ZStack {
            Color.clear
            if padVisible {
                VirtualControllerView()
            }

            VStack {
                HStack {
                    Spacer()
                    menuButton
                }
                .padding(.top, 4)
                .padding(.trailing, 4)
                Spacer()
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }

    private var menuButton: some View {
        Menu {
            Toggle(isOn: Binding(
                get: { settings.osdPreset != .off },
                set: { newValue in
                    if newValue {
                        settings.osdPreset = .simple
                        iPSX2Bridge.setPerformanceOverlayVisible(true)
                    } else {
                        settings.osdPreset = .off
                        iPSX2Bridge.setPerformanceOverlayVisible(false)
                    }
                }
            )) {
                Label("OSD", systemImage: "speedometer")
            }
            Toggle(isOn: $padVisible) {
                Label("Virtual Pad", systemImage: "gamecontroller")
            }
            Divider()
            Button {
                appState.returnToMenu()
            } label: {
                Label("Back to Menu", systemImage: "list.bullet")
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.5))
                .padding(6)
                .background(.black.opacity(0.15), in: Circle())
        }
    }
}
