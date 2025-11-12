//
//  AnimeDetailView.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI
import UIKit

struct AnimeDetailView: View {
    let anime: AnimeItem
    @Environment(\.dismiss) var dismiss
    @Environment(UserDataManager.self) var userDataManager
    @StateObject private var imdbService = IMDBService()
    @State private var isLoadingStremio = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isDescriptionExpanded = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showingFullImage = false
    @State private var recommendations: [AnimeItem] = []
    @State private var isLoadingRecommendations = false
    @State private var selectedGenreForExplore: String?
    @State private var showingExploreWithGenre = false
    @State private var selectedRecommendation: AnimeItem?

    var body: some View {
        NavigationStack {
            ZStack {
                // Main Content
                GeometryReader { geometry in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            // Hero Section with Parallax Effect
                            heroSection
                                .offset(y: scrollOffset * 0.3)
                            
                            // Content Section with overlapping card design
                            VStack(alignment: .leading, spacing: 0) {
                                // Main Info Card
                                mainInfoCard
                                    .padding(.top, -50) // Overlap with hero
                                    .zIndex(1)
                                
                                // Quick Actions Floating Bar
                                quickActionsBar
                                    .padding(.horizontal, 20)
                                    .padding(.top, 24)
                                
                                // Description Section
                                descriptionSection
                                    .padding(.horizontal, 20)
                                    .padding(.top, 32)
                                
                                // Genres Section
                                genresSection
                                    .padding(.horizontal, 20)
                                    .padding(.top, 32)
                                
                                // Information Grid
                                informationGrid
                                    .padding(.horizontal, 20)
                                    .padding(.top, 32)
                                
                                // Similar Shows
                                similarShowsSection
                                    .padding(.top, 32)
                                
                                // Bottom spacing for floating action button
                                Color.clear.frame(height: 100)
                            }
                        }
                        .background(
                            GeometryReader { scrollGeometry in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: scrollGeometry.frame(in: .global).minY
                                )
                            }
                        )
                    }
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                    }
                    .ignoresSafeArea(edges: .top)
                }
                
                // Floating Watch Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingWatchButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showingFullImage) {
            fullImageView
        }
        .sheet(isPresented: $showingExploreWithGenre) {
            NavigationStack {
                if let genre = selectedGenreForExplore {
                    ExploreView(initialGenres: [genre])
                        .environment(userDataManager)
                }
            }
        }
        .sheet(item: $selectedRecommendation) { recommendation in
            AnimeDetailView(anime: recommendation)
                .environment(userDataManager)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .task {
            await loadRecommendations()
        }
    }

    
    // MARK: - View Components
    
    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            // Background Image with Tap Gesture
            AsyncImage(url: URL(string: anime.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 400)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.2),
                                Color.gray.opacity(0.05),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 400)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.6))
                            Text("Tap to view full image")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    )
            }
            .onTapGesture {
                showingFullImage = true
            }
            
            // Gradient Overlays for depth
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.black.opacity(0.4), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                
                Spacer()
                
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
            }
            
            // Back Button Overlay
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
            }
        }
        .frame(height: 400)
    }
    
    private var mainInfoCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            Text(anime.title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
            
            // Rating and basic info in a more organized layout
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    // Rating
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 16, weight: .semibold))
                        Text(String(format: "%.1f", anime.rating))
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.orange.opacity(0.1))
                            .stroke(.orange.opacity(0.3), lineWidth: 1)
                    )
                    
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    // Episode count
                    HStack(spacing: 6) {
                        Image(systemName: "tv")
                            .foregroundColor(.blue)
                            .font(.system(size: 14, weight: .medium))
                        Text("\(anime.episodeCount) episodes")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Status
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(anime.status)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }
    
    private var quickActionsBar: some View {
        HStack(spacing: 12) {
            // Save Button
            Button(action: { 
                userDataManager.toggleFavorite(anime.id) 
            }) {
                HStack(spacing: 10) {
                    Image(systemName: userDataManager.isFavorite(anime.id) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .semibold))
                    Text(userDataManager.isFavorite(anime.id) ? "Saved" : "Save")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(userDataManager.isFavorite(anime.id) ? .white : .blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(userDataManager.isFavorite(anime.id) ? .blue : .blue.opacity(0.08))
                        .stroke(userDataManager.isFavorite(anime.id) ? .clear : .blue.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: true)
            
            // Watchlist Button
            Button(action: { 
                if userDataManager.isInWatchlist(anime.id) {
                    userDataManager.removeFromWatchlist(anime.id)
                } else {
                    userDataManager.addToWatchlist(anime, status: .planToWatch)
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: userDataManager.isInWatchlist(anime.id) ? "checkmark.circle.fill" : "plus.circle")
                        .font(.system(size: 16, weight: .semibold))
                    Text(userDataManager.isInWatchlist(anime.id) ? "In Watchlist" : "Watchlist")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(userDataManager.isInWatchlist(anime.id) ? .white : .purple)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(userDataManager.isInWatchlist(anime.id) ? .purple : .purple.opacity(0.08))
                        .stroke(userDataManager.isInWatchlist(anime.id) ? .clear : .purple.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: true)
            
            Spacer()
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Synopsis")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 16) {
                Text(anime.synopsis)
                    .font(.system(.body, design: .default))
                    .foregroundStyle(.secondary)
                    .lineSpacing(8)
                    .lineLimit(isDescriptionExpanded ? nil : 4)
                    .animation(.easeInOut(duration: 0.3), value: isDescriptionExpanded)
                
                if anime.synopsis.count > 200 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isDescriptionExpanded.toggle()
                        }
                    }) {
                        Text(isDescriptionExpanded ? "Show Less" : "Read More")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: isDescriptionExpanded)
                }
            }
        }
    }
    
    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Genres")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            
            if anime.genres.isEmpty {
                Text("No genres available")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.8))
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 90), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(anime.genres, id: \.self) { genre in
                        Button(action: {
                            selectedGenreForExplore = genre
                            showingExploreWithGenre = true
                        }) {
                            Text(genre)
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.thinMaterial)
                                        .stroke(.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var informationGrid: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Information")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ModernInfoCard(
                        title: "Episodes",
                        value: "\(anime.episodeCount)",
                        icon: "tv",
                        color: .blue
                    )
                    
                    ModernInfoCard(
                        title: "Rating",
                        value: String(format: "%.1f", anime.rating),
                        icon: "star.fill",
                        color: .orange
                    )
                }
                
                HStack(spacing: 16) {
                    ModernInfoCard(
                        title: "Status",
                        value: anime.status,
                        icon: "circle.fill",
                        color: statusColor
                    )
                    
                    ModernInfoCard(
                        title: "Type",
                        value: "TV Series",
                        icon: "tv.badge.wifi",
                        color: .purple
                    )
                }
            }
        }
    }
    
    private var similarShowsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("You Might Also Like")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
            
            if isLoadingRecommendations {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.secondary)
                        .scaleEffect(1.2)
                    Spacer()
                }
                .frame(height: 200)
                .padding(.horizontal, 20)
            } else if recommendations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tv.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary.opacity(0.6))
                    Text("No recommendations available")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(recommendations.prefix(6)), id: \.id) { recommendation in
                            Button(action: {
                                selectedRecommendation = recommendation
                            }) {
                                RecommendationCard(anime: recommendation)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private var floatingWatchButton: some View {
        Button(action: {
            Task {
                await openInStremio()
            }
        }) {
            HStack(spacing: 12) {
                if isLoadingStremio {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.white)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                }
                Text("Watch Now")
                    .font(.system(.headline, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .accentColor.opacity(0.3), radius: 15, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoadingStremio)
        .sensoryFeedback(.impact(intensity: 0.8), trigger: !isLoadingStremio)
        .scaleEffect(isLoadingStremio ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoadingStremio)
    }
    
    private var fullImageView: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                AsyncImage(url: URL(string: anime.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                } placeholder: {
                    ProgressView()
                        .tint(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFullImage = false
                    }
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Methods
    
    private func loadRecommendations() async {
        isLoadingRecommendations = true
        
        do {
            let jikanService = JikanAnimeService()
            let recommendationsResponse = try await jikanService.getAnimeRecommendations(animeId: anime.id)
            
            await MainActor.run {
                // Convert recommendations to AnimeItem and take first 6
                self.recommendations = recommendationsResponse.data.prefix(6).compactMap { recommendation in
                    let entry = recommendation.entry
                    return AnimeItem(
                        id: entry.malId,
                        title: entry.title,
                        imageURL: entry.images.jpg.largeImageURL,
                        synopsis: "", // Recommendations don't include synopsis
                        rating: 0.0, // Recommendations don't include rating
                        genres: [], // Recommendations don't include genres
                        episodeCount: 0, // Recommendations don't include episode count
                        status: "Unknown"
                    )
                }
            }
        } catch {
            print("Failed to load recommendations: \(error)")
            await MainActor.run {
                self.recommendations = []
            }
        }
        
        isLoadingRecommendations = false
    }

    private func openInStremio() async {
        isLoadingStremio = true

        do {
            // Search for the anime on IMDB
            guard
                let searchResponse = try await imdbService.searchTitles(
                    query: anime.title,
                    limit: 5
                ),
                let firstResult = searchResponse.titles.first
            else {
                throw IMDBError.noResultsFound
            }

            // Build the Stremio URL
            guard
                let stremioURL = imdbService.buildStremioURL(from: firstResult)
            else {
                throw IMDBError.invalidURL
            }

            // Debug: Print the URL being opened
            print("Attempting to open Stremio URL: \(stremioURL)")

            // Open the URL
            await MainActor.run {
                // Check if we can query the URL scheme
                let canQuery = UIApplication.shared.canOpenURL(stremioURL)
                print("Can open URL: \(canQuery)")

                if canQuery {
                    UIApplication.shared.open(stremioURL) { success in
                        print("URL opened successfully: \(success)")
                        if !success {
                            DispatchQueue.main.async {
                                self.errorMessage =
                                    "Failed to open Stremio. URL: \(stremioURL)"
                                self.showingError = true
                            }
                        }
                    }
                } else {
                    // Try to determine why it failed
                    let stremioSchemeURL = URL(string: "stremio://")!
                    let canOpenStremioScheme = UIApplication.shared.canOpenURL(
                        stremioSchemeURL
                    )

                    if !canOpenStremioScheme {
                        errorMessage =
                            "Stremio app is not installed or URL scheme not whitelisted in Info.plist. Add 'stremio' to LSApplicationQueriesSchemes."
                    } else {
                        errorMessage =
                            "Cannot open this specific Stremio URL: \(stremioURL)"
                    }
                    showingError = true
                }
            }

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }

        isLoadingStremio = false
    }

    private var statusColor: Color {
        switch anime.status {
        case "Ongoing":
            return .green
        case "Completed":
            return .blue
        default:
            return .gray
        }
    }
}

// MARK: - Supporting Views

struct ModernInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 20, height: 20)
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 90)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.thinMaterial)
                .stroke(.separator.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Legacy support for existing components
struct InfoStatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct RecommendationCard: View {
    let anime: AnimeItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            AsyncImage(url: URL(string: anime.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 130, height: 180)
                    .clipped()
                    .background(Color.gray.opacity(0.2))
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.15),
                                Color.gray.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 130, height: 180)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary.opacity(0.6))
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.separator.opacity(0.3), lineWidth: 1)
            )
            
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text(anime.title)
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text("Recommended")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 130, alignment: .leading)
        }
    }
}

#Preview {
    AnimeDetailView(
        anime: AnimeItem(
            id: 1,
            title: "Attack on Titan: Final Season",
            imageURL: "demo_image",
            synopsis: "Several hundred years ago, humans were nearly exterminated by Titans. Titans are typically several stories tall, seem to have no intelligence, devour human beings and, worst of all, seem to do it for the pleasure rather than as a food source. A small percentage of humanity survived by walling themselves in a city protected by extremely high walls, even taller than the biggest Titans. Flash forward to the present and the city has not seen a Titan in over 100 years. Teenage boy Eren and his foster sister Mikasa witness something horrific as the city walls are destroyed by a Colossal Titan that appears out of thin air.",
            rating: 9.2,
            genres: ["Action", "Drama", "Fantasy", "Military", "Shounen", "Super Power"],
            episodeCount: 75,
            status: "Completed"
        )
    )
}
