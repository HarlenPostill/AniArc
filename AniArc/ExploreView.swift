//
//  ExploreView.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct ExploreView: View {
    @State private var SearchText: String = ""


    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "house.fill")
                    .imageScale(.large)
                Text("This is the Explore page")
                    .font(.title2)
            }
            .padding()
            .navigationTitle("Explore")
        }
        .searchable(text: $SearchText)
    }
}

#Preview {
    ExploreView()
}
