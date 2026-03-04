//
//  FloatingComponent.swift
//  Ducky
//
//  Created by Dre Smith on 3/3/26.
//

import RealityKit
import simd

struct FloatingComponent: Component {
    var axis: SIMD3<Float>   // x,y = world position, z = animated
    var speed: Float

    // Burst
    var isBursting: Bool = true
    var burstVelocity: SIMD3<Float>

    init(axis: SIMD3<Float>) {
        self.axis = axis
        self.speed = Float.random(in: 0.001...0.005)
        self.burstVelocity = SIMD3<Float>(
            .random(in: -3.0...3.0),
            .random(in: -1.0...3.5),
            .random(in: -3.0...3.0)
        )
    }
}
