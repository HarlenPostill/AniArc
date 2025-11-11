//
//  ProfileView.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack{
                Image(systemName: "house.fill")
                    .imageScale(.large)
                Text("This is the profile page")
                    .font(.title2)
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}
