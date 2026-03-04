//
//  AppModel.swift
//  Ducky
//
//  Created by Dre Smith on 3/3/26.
//

//import SwiftUI
//import RealityKit
//import ARKit
//
///// Maintains app-wide state
//@MainActor
//@Observable
//final class AppModel {
//    private let modelCount = 8
//    var isLoadingAssets = false
//    var isImmersiveOpen = false
//    let rootEntity = Entity()
//    private var grabbedEntity: Entity?
//    private let handAnchor = Entity()
//    
//    init() {
//        FloatingSystem.registerSystem()
//        // Prepare a hand anchor that follows the user's hand when grabbing
//        handAnchor.name = "HandAnchor"
//        rootEntity.addChild(handAnchor)
//        HandGrabSystem.registerSystem()
//    }
//    
//    func addDucky() async {
//        isLoadingAssets = true
//        for _ in 0..<modelCount {
//            let ducky = try! await createDucky()
//            rootEntity.addChild(ducky)
//        }
//        
//        isLoadingAssets = false
//    }
//}
//
//// MARK: - Helpers
//private extension AppModel {
//    func createDucky() async throws -> ModelEntity {
//        let ducky = try await ModelEntity(named: "ducky")
//        // Appearance
//        ducky.model?.materials = [random()]
//        // Scale randomly
//        ducky.setScale(SIMD3(repeating: 0.2 * .random(in: 0.5...2)), relativeTo: ducky)
//        // Install collision for hit testing and grabbing
//        try? ducky.generateCollisionShapes(recursive: true)
//        ducky.collision = CollisionComponent(shapes: ducky.collision?.shapes ?? [])
//        // Give it physics so it can fall when released
//        ducky.components.set(PhysicsBodyComponent(massProperties: .default, material: .default, mode: .dynamic))
//        ducky.components.set(PhysicsMotionComponent())
//        // Add a subtle floating component so idle ducks drift
//        ducky.components.set(FloatingComponent(axis: [
//            .random(in: -2...2),
//            .random(in: 0...1.5),
//            .random(in: -2...0.5)
//        ]))
//        // Tag for interaction
//        ducky.name = "ducky"
//        
//        return ducky
//    }
//    
//    func random() -> SimpleMaterial {
//        colors
//            .map { SimpleMaterial(color: $0, isMetallic: false) }
//            .randomElement()!
//    }
//}
//
//private let colors: [UIColor] = [.black, .darkGray, .lightGray, .white, .gray, .red, .green, .blue, .orange, .brown, .purple, .yellow]
//
//// MARK: - Grabbing hooks used by HandGrabSystem
//extension AppModel {
//    func beginGrab(entity: Entity) {
//        guard grabbedEntity == nil else { return }
//        // Temporarily disable physics while held
//        if var body = entity.components[PhysicsBodyComponent.self] as? PhysicsBodyComponent {
//            body.mode = .kinematic
//            entity.components.set(body)
//        }
//        entity.components.set(PhysicsMotionComponent())
//        // Attach to hand anchor to follow the hand
//        handAnchor.addChild(entity)
//        entity.setPosition(.zero, relativeTo: handAnchor)
//        grabbedEntity = entity
//    }
//
//    func updateGrabPose(to transform: Transform) {
//        handAnchor.transform = transform
//    }
//
//    func endGrab() {
//        guard let entity = grabbedEntity else { return }
//        // Re-enable dynamics so it can fall
//        if var body = entity.components[PhysicsBodyComponent.self] as? PhysicsBodyComponent {
//            body.mode = .dynamic
//            entity.components.set(body)
//        }
//        // Move back to root to be simulated in world space
//        rootEntity.addChild(entity)
//        grabbedEntity = nil
//    }
//}
//


import SwiftUI
import RealityKit
import ARKit

@MainActor
@Observable
final class AppModel {
    private let modelCount = 40
    var isLoadingAssets = false
    var isImmersiveOpen = false
    let rootEntity = Entity()

    private var grabbedEntity: Entity?
    private let handAnchor = Entity()
    private var duckyTemplate: ModelEntity?

    init() {
        FloatingSystem.registerSystem()
        handAnchor.name = "HandAnchor"
        rootEntity.addChild(handAnchor)
        HandGrabSystem.registerSystem()
        HandGrabSystem.appModel = self
    }

    func addDucky(cameraTransform: Transform = Transform()) async {
        isLoadingAssets = true

        do {
            let template = try await ModelEntity(named: "ducky")
            self.duckyTemplate = template

            for _ in 0..<modelCount {
                let ducky = template.clone(recursive: true)
                setupDucky(ducky, cameraTransform: cameraTransform)
                rootEntity.addChild(ducky)
            }
        } catch {
            print("Failed to load ducky: \(error)")
        }

        isLoadingAssets = false
    }
}

// MARK: - Setup
private extension AppModel {
    func setupDucky(_ ducky: ModelEntity, cameraTransform: Transform) {
        let scale = Float.random(in: 0.0008...0.002)
        ducky.scale = SIMD3(repeating: scale)
        ducky.model?.materials = [randomMaterial()]

        // Collision for hit testing
        ducky.components.set(CollisionComponent(
            shapes: [.generateSphere(radius: 0.06)]
        ))

        // ✅ Required for SpatialTapGesture to fire
        ducky.components.set(InputTargetComponent())

        // ✅ Highlight whatever the player looks at
        ducky.components.set(HoverEffectComponent())

        // Burst spawn from center in front of camera
        let spawnOffset = SIMD4<Float>(0, 0, -1.5, 1)
        let worldPos = cameraTransform.matrix * spawnOffset
        ducky.position = SIMD3<Float>(worldPos.x, worldPos.y, worldPos.z)

        ducky.orientation = simd_quatf(
            angle: .random(in: 0...(2 * .pi)),
            axis: normalize(SIMD3<Float>(
                .random(in: -1...1),
                .random(in: -1...1),
                .random(in: -1...1)
            ))
        )

        ducky.components.set(FloatingComponent(axis: [
            .random(in: 0.3...1.5),
            .random(in: 0.3...1.5),
            .random(in: 0.3...1.5)
        ]))

        ducky.name = "ducky"
    }

    func randomMaterial() -> SimpleMaterial {
        SimpleMaterial(color: colors.randomElement() ?? .yellow, isMetallic: false)
    }
}

// MARK: - Grabbing
extension AppModel {
    func beginGrab(entity: Entity) {
        guard grabbedEntity == nil else { return }
        handAnchor.addChild(entity, preservingWorldTransform: true)
        grabbedEntity = entity
    }

    func updateGrabPose(to transform: Transform) {
        handAnchor.transform = transform
    }

    func endGrab() {
        guard let entity = grabbedEntity else { return }
        rootEntity.addChild(entity, preservingWorldTransform: true)
        grabbedEntity = nil
    }
}

private let colors: [UIColor] = [.black, .darkGray, .lightGray, .white, .gray, .red, .green, .blue, .orange, .brown, .purple, .yellow, .magenta, .cyan]
