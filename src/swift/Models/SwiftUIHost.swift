// SwiftUIHost.swift — ObjC-callable helper to create SwiftUI hosting controllers
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI
import UIKit

@objc public class SwiftUIHost: NSObject {
    // [P44] Menu screen (TabView with Games/BIOS/Help/Settings)
    @MainActor
    @objc public static func createMenuController() -> UIViewController {
        let hostingController = UIHostingController(rootView: RootView())
        hostingController.view.backgroundColor = .clear
        hostingController.view.isOpaque = false
        return hostingController
    }

}
