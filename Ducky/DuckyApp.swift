//
//  DuckyApp.swift
//  Ducky
//
//  Created by Dre Smith on 3/3/26.
//

import SwiftUI

@main
struct DuckyApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .defaultSize(width: 500, height: 500)

        ImmersiveSpace(id: "ImmersiveScene") {
            ImmersiveSpaceView()
                .environment(appModel)
        }
     }
}
