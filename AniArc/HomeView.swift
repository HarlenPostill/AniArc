//
//  HomeView.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var dataService = AnimeDataService()
    @Environment(UserDataManager.self) var userDataManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Featured Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Featured Today")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(Array(dataService.animeItems.prefix(5))) { anime in
                                    FeaturedAnimeCard(anime: anime)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Popular Anime Grid
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Popular Anime")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            NavigationLink("View All", destination: ExploreView())
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.horizontal)
                        
                        AnimeGrid(
                            animeItems: Array(dataService.animeItems.prefix(6)),
                            isLoading: dataService.isLoading
                        )
                    }
                }
                .padding(.top)
            }
            .navigationTitle("AniArc")
        }
        .task {
            if dataService.animeItems.isEmpty {
                await dataService.loadInitialItems()
            }
        }
    }
}

// MARK: - Featured Anime Card
struct FeaturedAnimeCard: View {
    let anime: AnimeItem
    @Environment(UserDataManager.self) var userDataManager
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Large Image
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 160)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                )
                .overlay(
                    // Featured Badge
                    VStack {
                        HStack {
                            Text("FEATURED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red)
                                .cornerRadius(4)
                            Spacer()
                            RatingBadge(rating: anime.rating)
                        }
                        Spacer()
                    }
                    .padding(12)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(anime.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text(anime.genres.prefix(2).joined(separator: " • "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(anime.synopsis)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(.top, 8)
            .frame(width: 280, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetail = true
        }
        .fullScreenCover(isPresented: $showingDetail) {
            AnimeDetailView(anime: anime)
                .environment(userDataManager)
        }
    }
}
