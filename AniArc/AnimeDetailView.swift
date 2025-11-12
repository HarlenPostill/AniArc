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
    @StateObject private var imdbService = IMDBService()
    @State private var isLoadingStremio = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Large Cover Image with Overlay
                    ZStack(alignment: .bottom) {
                        AsyncImage(url: URL(string: anime.imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.4),
                                            Color.gray.opacity(0.2),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                )
                        }
                        .aspectRatio(4 / 3, contentMode: .fit)
                        // Gradient overlay for text readability
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)

                        // Title overlay on image
                        VStack(alignment: .leading, spacing: 8) {
                            Text(anime.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(radius: 10)

                            HStack(spacing: 12) {
                                RatingBadge(rating: anime.rating)

                                Text("•")
                                    .foregroundColor(.white.opacity(0.8))

                                Text("\(anime.episodeCount) eps")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))

                                Text("•")
                                    .foregroundColor(.white.opacity(0.8))

                                Text(anime.status)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(statusColor.opacity(0.8))
                                    .cornerRadius(6)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: {}) {
                                VStack(spacing: 6) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.title3)
                                    Text("Save")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)

                            Button(action: {}) {
                                VStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                    Text("Watchlist")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.bordered)
                            .tint(.purple)

                            Button(action: {
                                Task {
                                    await openInStremio()
                                }
                            }) {
                                VStack(spacing: 6) {
                                    if isLoadingStremio {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .frame(width: 20, height: 20)
                                    } else {
                                        Image(systemName: "play.fill")
                                            .font(.title3)
                                    }
                                    Text("Watch")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isLoadingStremio)

                            Button(action: {}) {
                                VStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title3)
                                    Text("Share")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)

                        Divider()

                        // Genres
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Genres")
                                .font(.headline)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(anime.genres, id: \.self) { genre in
                                        Text(genre)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Color.accentColor.opacity(0.15)
                                            )
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        Divider()

                        // Synopsis
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Synopsis")
                                .font(.headline)

                            Text(anime.synopsis)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal)

                        Divider()

                        // Stats Grid
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Information")
                                .font(.headline)

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                ],
                                spacing: 16
                            ) {
                                InfoStatItem(
                                    title: "Episodes",
                                    value: "\(anime.episodeCount)"
                                )
                                InfoStatItem(
                                    title: "Status",
                                    value: anime.status
                                )
                                InfoStatItem(
                                    title: "Rating",
                                    value: String(
                                        format: "%.1f/10",
                                        anime.rating
                                    )
                                )
                                InfoStatItem(title: "Type", value: "TV Series")
                            }
                        }
                        .padding(.horizontal)

                        Divider()

                        // Studio & Release Info
                        VStack(alignment: .leading, spacing: 16) {
                            InfoRow(label: "Studio", value: "Studio Example")
                            InfoRow(label: "Premiered", value: "Fall 2023")
                            InfoRow(label: "Source", value: "Manga")
                            InfoRow(
                                label: "Duration",
                                value: "24 min per episode"
                            )
                        }
                        .padding(.horizontal)

                        Divider()

                        // Similar Anime Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Similar Shows")
                                .font(.headline)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<5) { index in
                                        VStack(alignment: .leading, spacing: 8)
                                        {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 120, height: 170)
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.gray)
                                                )

                                            Text("Similar Anime \(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .lineLimit(2)
                                                .frame(width: 120)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Bottom spacing
                        Color.clear.frame(height: 20)
                    }
                    .padding(.top, 20)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Methods

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

// MARK: - Supporting Views for Detail
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

#Preview {
    AnimeDetailView(
        anime: AnimeItem(
            id: 1,
            title: "Demo Anime",
            imageURL: "demo_image",
            synopsis: "This is a demo anime for preview purposes.",
            rating: 8.5,
            genres: ["Action", "Adventure"],
            episodeCount: 24,
            status: "Completed"
        )
    )
}
