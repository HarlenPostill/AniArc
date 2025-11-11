//
//  SavedView.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct SavedView: View {
    var body: some View {
        NavigationStack {
            VStack{
                Image(systemName: "house.fill")
                    .imageScale(.large)
                Text("This is the Saved page")
                    .font(.title2)
            }
            .padding()
            .navigationTitle("Saved")
        }
    }
}
