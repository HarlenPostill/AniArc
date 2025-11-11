//
//  ContentView.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView{
            Tab ("Home", systemImage: "house") {
                HomeView()
            }
            Tab (role: .search) {
                ExploreView()
            }
            Tab ("Saved", systemImage: "popcorn.fill") {
                SavedView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
}
