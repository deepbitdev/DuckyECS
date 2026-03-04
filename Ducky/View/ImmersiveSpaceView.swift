//
//  ImmersiveSpaceView.swift
//  Ducky
//
//  Created by Dre Smith on 3/3/26.
//

import SwiftUI
import RealityKit
import ARKit

struct ImmersiveSpaceView: View {
    @Environment(AppModel.self) var model

    var body: some View {
        RealityView { content in
            content.add(model.rootEntity)
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    var candidate: Entity? = value.entity
                    while let current = candidate, current.name != "ducky" {
                        candidate = current.parent
                    }
                    guard let duck = candidate, duck.name == "ducky" else { return }
                    model.beginGrab(entity: duck)
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        model.endGrab()
                    }
                }
        )
        .task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await model.addDucky(cameraTransform: getCameraTransform())
        }
    }

    private func getCameraTransform() -> Transform {
        var t = Transform()
        t.translation = SIMD3<Float>(0, 1, 0)
        return t
    }
}
