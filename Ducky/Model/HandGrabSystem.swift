//
//  HandGrabSystem.swift
//  Ducky
//
//  Created by Dre Smith on 3/3/26.
//

import SwiftUI
import RealityKit
import ARKit

/// A RealityKit System handling hand-based grab and release using select gestures (pinch).
///
/// This system relies on a shared `AppModel` instance to manage grab state and pose updates.
/// Since some registration and input APIs vary by platform, this system:
/// - Expects the app to set `HandGrabSystem.appModel` externally before using this system.
/// - Uses a best-effort approach to find the main camera anchor entity named "MainCamera" in the scene.
///
/// The grab logic (stubbed for input routing):
/// - Call `beginGrabIfPossible(in:scene)` from your app when a select gesture begins.
/// - Call `updateGrabPoseIfNeeded(in:scene)` while the gesture changes.
/// - Call `endGrab()` when the gesture ends.
///
/// If `appModel` is not set, the system performs no operations.
/// The app must assign `HandGrabSystem.appModel = yourAppModelInstance` during initialization.
struct HandGrabSystem: System {
    /// Weak reference to the shared AppModel instance.
    static weak var appModel: AppModel?

    init(scene: RealityKit.Scene) {}

    /// Called every frame to perform any continuous updates.
    /// Input events are not accessed here because `SceneUpdateContext` doesn't expose them on all platforms.
    func update(context: SceneUpdateContext) {
        // No-op frame update; input handling should call helper methods below.
    }
}

// MARK: - Helpers used by the app to drive grabbing
extension HandGrabSystem {
    /// Call from your input handler when select begins.
    static func beginGrabIfPossible(in scene: RealityKit.Scene) {
        guard let appModel = Self.appModel,
              let cameraTransform = getMainCameraTransform(in: scene),
              let duck = findClosestDucky(in: scene, from: cameraTransform) else { return }
        appModel.beginGrab(entity: duck)
    }

    /// Call from your input handler while select changes.
    static func updateGrabPoseIfNeeded(in scene: RealityKit.Scene) {
        guard let appModel = Self.appModel,
              let cameraTransform = getMainCameraTransform(in: scene) else { return }
        appModel.updateGrabPose(to: cameraTransform)
    }

    /// Call from your input handler when select ends.
    static func endGrab() {
        Self.appModel?.endGrab()
    }
}

// MARK: - Scene utilities
private extension HandGrabSystem {
    /// Finds the closest entity named "ducky" with collision in front of the camera by performing a raycast.
    /// - Parameters:
    ///   - scene: The current RealityKit scene.
    ///   - cameraTransform: The camera's world transform.
    /// - Returns: The closest entity named "ducky" if found; otherwise nil.
    static func findClosestDucky(in scene: RealityKit.Scene, from cameraTransform: Transform) -> Entity? {
        let m = cameraTransform.matrix
        let origin = SIMD3<Float>(m.columns.3.x, m.columns.3.y, m.columns.3.z)
        let forward = normalize(-SIMD3<Float>(m.columns.2.x, m.columns.2.y, m.columns.2.z))
        let maxDistance: Float = 2.0

        // Use raycast on the scene to find nearest hit.
        let results = scene.raycast(origin: origin, direction: forward, length: maxDistance)
        let duck = results.compactMap { $0.entity }.first(where: { $0.name == "ducky" })
        return duck
    }

    /// Retrieves the main camera's transform from the scene by finding an entity named "MainCamera".
    /// - Parameter scene: The current RealityKit scene.
    /// - Returns: The camera's world transform if found; otherwise nil.
    static func getMainCameraTransform(in scene: RealityKit.Scene) -> Transform? {
        guard let cameraEntity = scene.findEntity(named: "MainCamera") else { return nil }
        return Transform(matrix: cameraEntity.transformMatrix(relativeTo: nil))
    }
}

