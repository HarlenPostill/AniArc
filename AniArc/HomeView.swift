//
//  HomeView.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack{
                Image(systemName: "house.fill")
                    .imageScale(.large)
                Text("This is the home page")
                    .font(.title2)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}
