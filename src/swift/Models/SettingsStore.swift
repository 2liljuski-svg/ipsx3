// SettingsStore.swift — INI-backed settings for SwiftUI
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI

/// [P51] OSD preset levels
enum OsdPreset: Int, CaseIterable {
    case off = 0
    case simple = 1    // FPS + CPU usage
    case detail = 2    // All except frame times graph
    case full = 3      // Everything

    var label: String {
        switch self {
        case .off: return "OFF"
        case .simple: return "Simple"
        case .detail: return "Detail"
        case .full: return "Full"
        }
    }
}

@Observable
final class SettingsStore: @unchecked Sendable {
    static let shared = SettingsStore()

    // Emulator
    var eeCoreType: Int {
        didSet { iPSX2Bridge.setINIInt("EmuCore/CPU", key: "CoreType", value: Int32(eeCoreType)) }
    }
    var iopRecompiler: Bool {
        didSet { iPSX2Bridge.setINIBool("EmuCore/CPU/Recompiler", key: "EnableIOP", value: iopRecompiler) }
    }
    var vu0Recompiler: Bool {
        didSet { iPSX2Bridge.setINIBool("EmuCore/CPU/Recompiler", key: "EnableVU0", value: vu0Recompiler) }
    }
    var vu1Recompiler: Bool {
        didSet { iPSX2Bridge.setINIBool("EmuCore/CPU/Recompiler", key: "EnableVU1", value: vu1Recompiler) }
    }
    var fastBoot: Bool {
        didSet { iPSX2Bridge.setINIBool("GameISO", key: "FastBoot", value: fastBoot) }
    }
    var fastmem: Bool {
        didSet { iPSX2Bridge.setINIBool("EmuCore/CPU/Recompiler", key: "EnableFastmem", value: fastmem) }
    }
    var mtvu: Bool {
        didSet { iPSX2Bridge.setINIBool("EmuCore/Speedhacks", key: "MTVU", value: mtvu) }
    }

    // Graphics
    var upscaleMultiplier: Float {
        didSet { iPSX2Bridge.setINIFloat("EmuCore/GS", key: "UpscaleMultiplier", value: upscaleMultiplier) }
    }
    var vsyncQueueSize: Int {
        didSet { iPSX2Bridge.setINIInt("EmuCore/GS", key: "VsyncQueueSize", value: Int32(vsyncQueueSize)) }
    }

    // OSD Overlay
    var osdPreset: OsdPreset {
        didSet {
            iPSX2Bridge.setINIInt("iPSX2/UI", key: "OsdPreset", value: Int32(osdPreset.rawValue))
            applyOsdPreset(osdPreset)
        }
    }
    var osdShowFPS: Bool {
        didSet { iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowFPS", value: osdShowFPS) }
    }
    var osdShowSpeed: Bool {
        didSet { iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowSpeed", value: osdShowSpeed) }
    }
    var osdShowCPU: Bool {
        didSet { iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowCPU", value: osdShowCPU) }
    }
    var osdShowResolution: Bool {
        didSet { iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowResolution", value: osdShowResolution) }
    }
    var osdShowFrameTimes: Bool {
        didSet { iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowFrameTimes", value: osdShowFrameTimes) }
    }

    // Gamepad
    var padOpacity: Float {
        didSet { iPSX2Bridge.setINIFloat("iPSX2/UI", key: "PadOpacity", value: padOpacity) }
    }
    var hapticFeedback: Bool {
        didSet { iPSX2Bridge.setINIBool("iPSX2/UI", key: "HapticFeedback", value: hapticFeedback) }
    }

    private init() {
        eeCoreType = Int(iPSX2Bridge.getINIInt("EmuCore/CPU", key: "CoreType", defaultValue: 0))
        iopRecompiler = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableIOP", defaultValue: true)
        vu0Recompiler = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableVU0", defaultValue: false)
        vu1Recompiler = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableVU1", defaultValue: false)
        fastBoot = iPSX2Bridge.getINIBool("GameISO", key: "FastBoot", defaultValue: false)
        fastmem = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableFastmem", defaultValue: true)
        mtvu = iPSX2Bridge.getINIBool("EmuCore/Speedhacks", key: "MTVU", defaultValue: false)
        upscaleMultiplier = iPSX2Bridge.getINIFloat("EmuCore/GS", key: "UpscaleMultiplier", defaultValue: 1.0)
        vsyncQueueSize = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "VsyncQueueSize", defaultValue: 8))
        osdPreset = OsdPreset(rawValue: Int(iPSX2Bridge.getINIInt("iPSX2/UI", key: "OsdPreset", defaultValue: 0))) ?? .off
        osdShowFPS = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowFPS", defaultValue: false)
        osdShowSpeed = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowSpeed", defaultValue: false)
        osdShowCPU = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowCPU", defaultValue: false)
        osdShowResolution = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowResolution", defaultValue: false)
        osdShowFrameTimes = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowFrameTimes", defaultValue: false)
        padOpacity = iPSX2Bridge.getINIFloat("iPSX2/UI", key: "PadOpacity", defaultValue: 0.6)
        hapticFeedback = iPSX2Bridge.getINIBool("iPSX2/UI", key: "HapticFeedback", defaultValue: true)
        // [P51] Apply OSD preset to GSConfig on init
        iPSX2Bridge.applyOsdPreset(Int32(osdPreset.rawValue))
    }

    /// [P51] Reload ALL settings from INI (call on VM start/stop)
    func reload() {
        eeCoreType = Int(iPSX2Bridge.getINIInt("EmuCore/CPU", key: "CoreType", defaultValue: 0))
        iopRecompiler = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableIOP", defaultValue: true)
        vu0Recompiler = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableVU0", defaultValue: false)
        vu1Recompiler = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableVU1", defaultValue: false)
        fastBoot = iPSX2Bridge.getINIBool("GameISO", key: "FastBoot", defaultValue: false)
        fastmem = iPSX2Bridge.getINIBool("EmuCore/CPU/Recompiler", key: "EnableFastmem", defaultValue: true)
        mtvu = iPSX2Bridge.getINIBool("EmuCore/Speedhacks", key: "MTVU", defaultValue: false)
        upscaleMultiplier = iPSX2Bridge.getINIFloat("EmuCore/GS", key: "UpscaleMultiplier", defaultValue: 1.0)
        vsyncQueueSize = Int(iPSX2Bridge.getINIInt("EmuCore/GS", key: "VsyncQueueSize", defaultValue: 8))
        osdPreset = OsdPreset(rawValue: Int(iPSX2Bridge.getINIInt("iPSX2/UI", key: "OsdPreset", defaultValue: 0))) ?? .off
        osdShowFPS = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowFPS", defaultValue: false)
        osdShowSpeed = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowSpeed", defaultValue: false)
        osdShowCPU = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowCPU", defaultValue: false)
        osdShowResolution = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowResolution", defaultValue: false)
        osdShowFrameTimes = iPSX2Bridge.getINIBool("EmuCore/GS", key: "OsdShowFrameTimes", defaultValue: false)
        padOpacity = iPSX2Bridge.getINIFloat("iPSX2/UI", key: "PadOpacity", defaultValue: 0.6)
        hapticFeedback = iPSX2Bridge.getINIBool("iPSX2/UI", key: "HapticFeedback", defaultValue: true)
    }

    /// [P51] Apply OSD preset — writes ALL OSD flags to INI + GSConfig
    /// VM boot loads OSD flags from INI into GSConfig, so INI must have correct values.
    private func applyOsdPreset(_ preset: OsdPreset) {
        // Apply to GSConfig immediately (for running VM)
        iPSX2Bridge.applyOsdPreset(Int32(preset.rawValue))

        let isSimple = preset == .simple
        let isDetail = preset == .detail
        let isFull = preset == .full

        // 5 flags managed by SettingsStore properties (triggers didSet → INI write)
        osdShowFPS = isSimple || isDetail || isFull
        osdShowSpeed = isDetail || isFull
        osdShowCPU = isSimple || isDetail || isFull
        osdShowResolution = isDetail || isFull
        osdShowFrameTimes = isFull

        // Remaining flags — write directly to INI so VM boot picks them up correctly
        iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowVPS", value: false)
        iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowVersion", value: false)
        iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowHardwareInfo", value: false)
        iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowGPU", value: false)
        iPSX2Bridge.setINIBool("EmuCore/GS", key: "OsdShowGSStats", value: false)
    }
}
