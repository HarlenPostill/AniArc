//
//  AniArcApp.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

@main
struct AniArcApp: App {
    @State private var userDataManager = UserDataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(userDataManager)
        }
    }
}
