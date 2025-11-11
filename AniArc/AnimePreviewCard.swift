//
//  AnimePreviewCard.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct AnimePreviewCard: View {
    let anime: AnimeItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Image
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 120)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
                    .overlay(
                        // Rating badge
                        VStack {
                            HStack {
                                Spacer()
                                RatingBadge(rating: anime.rating)
                                    .scaleEffect(0.8)
                                    .padding(4)
                            }
                            Spacer()
                        }
                    )
                
                // Info section
                VStack(alignment: .leading, spacing: 8) {
                    Text(anime.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    
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
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: 300, maxHeight: 250)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "ongoing", "airing":
            return .green
        case "completed", "finished":
            return .blue
        case "upcoming", "not yet aired":
            return .orange
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    AnimePreviewCard(
        anime: AnimeItem(
            title: "Attack on Titan",
            imageURL: "preview_image",
            synopsis: "Humanity fights for survival against giant humanoid Titans. Eren Yeager joins the fight to reclaim the world for humanity.",
            rating: 9.0,
            genres: ["Action", "Drama", "Fantasy", "Military"],
            episodeCount: 75,
            status: "Completed"
        )
    )
    .padding()
}