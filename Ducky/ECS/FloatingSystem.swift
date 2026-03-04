//
//  FloatingSystem.swift
//  Ducky
//
//  Created by Dre Smith on 3/3/26.
//

import RealityKit

final class FloatingSystem: System {
    private let query = EntityQuery(where: .has(FloatingComponent.self))
    private let damping: Float = 0.90
    private let burstThreshold: Float = 0.08

    init(scene: Scene) {}

    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)

        for entity in context.entities(matching: query, updatingSystemWhen: .rendering) {
            var component = entity.components[FloatingComponent.self]!

            if component.isBursting {
                // Burst phase — fly outward with damping
                entity.position += component.burstVelocity * dt

                let angle = length(component.burstVelocity) * dt
                if angle > 0 {
                    let rotAxis = normalize(component.burstVelocity)
                    entity.orientation = simd_quatf(angle: angle, axis: rotAxis) * entity.orientation
                }

                component.burstVelocity *= damping

                // Once settled, seed axis to current world position so
                // the original floating logic continues from where the duck landed
                if length(component.burstVelocity) < burstThreshold {
                    component.isBursting = false
                    component.axis = entity.position  // ✅ hand off to original system
                }
            } else {
                // ✅ Original floating logic preserved exactly
                if component.axis.z > 2 {
                    component.axis.z = .random(in: -2...0)
                } else {
                    component.axis.z += component.speed
                }

                entity.setPosition(component.axis, relativeTo: nil)
                entity.setOrientation(simd_quatf(angle: component.speed, axis: component.axis), relativeTo: entity)
            }

            entity.components[FloatingComponent.self] = component
        }
    }
}
