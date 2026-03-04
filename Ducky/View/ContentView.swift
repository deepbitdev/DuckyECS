//
//  ContentView.swift
//  Ducky
//
//  Created by Dre Smith on 3/3/26.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @Environment(AppModel.self) var model
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        let buttonText = model.isImmersiveOpen ? "Dismiss Ducky Space" : "Open Ducky Space"
        Button(buttonText) {
            Task {
                if model.isImmersiveOpen {
                    await dismissImmersiveSpace()
                    model.isImmersiveOpen = false
                } else {
                    // ✅ Open the space FIRST so the camera anchor exists in the scene
                    await openImmersiveSpace(id: "ImmersiveScene")
                    model.isImmersiveOpen = true
                    // addDucky is now called from ImmersiveSpaceView once the scene is ready
                }
            }
        }
        .disabled(model.isLoadingAssets)

        if model.isLoadingAssets {
            ProgressView()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
