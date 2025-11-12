//
//  AnimePreviewCard.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct AnimePreviewCard: View {
    let anime: AnimeItem
    @Environment(UserDataManager.self) var userDataManager
    @State private var showingAddToWatchlist = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Image with loading and user status indicators
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: anime.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // User status indicators
                    VStack(spacing: 4) {
                        if userDataManager.isFavorite(anime.id) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                                .background(Circle().fill(.ultraThinMaterial))
                                .padding(2)
                        }
                        
                        if userDataManager.isInWatchlist(anime.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                                .background(Circle().fill(.ultraThinMaterial))
                                .padding(2)
                        }
                        
                        RatingBadge(rating: anime.rating)
                            .scaleEffect(0.8)
                    }
                    .padding(4)
                }
                
                // Info section
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(anime.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(2)
                        
                        if let year = anime.year, let type = anime.type {
                            Text("\(type) • \(year)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Quick stats
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "tv")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(anime.episodeCount) Episodes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .foregroundColor(statusColor(anime.status))
                            Text(anime.status)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", anime.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let userRating = userDataManager.getUserRating(for: anime.id) {
                                Spacer()
                                Text("You: \(userRating)/10")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 4)
                                    .background(Capsule().fill(.blue.opacity(0.1)))
                            }
                        }
                        
                        // Watch progress if exists
                        if let entry = userDataManager.getWatchlistEntry(for: anime.id),
                           entry.watchProgress > 0 {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("\(entry.watchProgress)/\(anime.episodeCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // Progress bar
                                if anime.episodeCount > 0 {
                                    ProgressView(value: Double(entry.watchProgress), total: Double(anime.episodeCount))
                                        .frame(width: 30)
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            // Genres
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(anime.genres.prefix(4), id: \.self) { genre in
                        Text(genre)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 1)
            }
            
            // Synopsis
            Text(anime.synopsis)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    userDataManager.toggleFavorite(anime.id)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: userDataManager.isFavorite(anime.id) ? "heart.fill" : "heart")
                        Text(userDataManager.isFavorite(anime.id) ? "Favorited" : "Favorite")
                    }
                    .font(.caption)
                    .foregroundColor(userDataManager.isFavorite(anime.id) ? .red : .primary)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: {
                    if userDataManager.isInWatchlist(anime.id) {
                        userDataManager.removeFromWatchlist(anime.id)
                    } else {
                        showingAddToWatchlist = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: userDataManager.isInWatchlist(anime.id) ? "checkmark.circle.fill" : "plus.circle")
                        Text(userDataManager.isInWatchlist(anime.id) ? "In List" : "Add to List")
                    }
                    .font(.caption)
                    .foregroundColor(userDataManager.isInWatchlist(anime.id) ? .green : .primary)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                // Show studios if available
                if !anime.studios.isEmpty {
                    Text(anime.studios.first ?? "")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: 300, maxHeight: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingAddToWatchlist) {
            AddToWatchlistView(anime: anime)
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "currently airing", "airing":
            return .green
        case "finished airing", "completed":
            return .blue
        case "not yet aired", "upcoming":
            return .orange
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Add to Watchlist View
struct AddToWatchlistView: View {
    let anime: AnimeItem
    @Environment(UserDataManager.self) var userDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStatus: WatchStatus = .planToWatch
    @State private var userRating: Int = 0
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Status") {
                    Picker("Watch Status", selection: $selectedStatus) {
                        ForEach(WatchStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Rating") {
                    HStack {
                        Text("Your Rating:")
                        Spacer()
                        HStack {
                            ForEach(1...10, id: \.self) { rating in
                                Button(action: {
                                    userRating = userRating == rating ? 0 : rating
                                }) {
                                    Image(systemName: rating <= userRating ? "star.fill" : "star")
                                        .foregroundColor(rating <= userRating ? .yellow : .gray)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Add notes about this anime...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(anime.title)
                            .font(.headline)
                        Text(anime.synopsis)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
            }
            .navigationTitle("Add to List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        userDataManager.addToWatchlist(anime, status: selectedStatus)
                        if userRating > 0 {
                            userDataManager.setUserRating(animeID: anime.id, rating: userRating)
                        }
                        if !notes.isEmpty {
                            userDataManager.updateNotes(animeID: anime.id, notes: notes)
                        }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    AnimePreviewCard(
        anime: AnimeItem(
            id: 1,
            title: "Attack on Titan",
            imageURL: "https://cdn.myanimelist.net/images/anime/10/47347.jpg",
            synopsis: "Humanity fights for survival against giant humanoid Titans. Eren Yeager joins the fight to reclaim the world for humanity.",
            rating: 9.0,
            genres: ["Action", "Drama", "Fantasy", "Military"],
            episodeCount: 75,
            status: "Finished Airing",
            year: 2013,
            type: "TV",
            studios: ["MAPPA", "Kodansha"]
        )
    )
    .environment(UserDataManager())
    .padding()
}