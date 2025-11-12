//
//  AnimeCard.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct AnimeCard: View {
    let anime: AnimeItem
    @Environment(UserDataManager.self) var userDataManager

    var body: some View {
        NavigationLink(destination: AnimeDetailView(anime: anime).environment(userDataManager)) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            AnimeContextMenu(anime: anime)
                .environment(userDataManager)
        } preview: {
            AnimePreviewCard(anime: anime)
                .environment(userDataManager)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(0.7, contentMode: .fit)
                .overlay(
                    // Placeholder for actual image
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )
                .overlay(
                    // Rating badge
                    VStack {
                        HStack {
                            Spacer()
                            RatingBadge(rating: anime.rating)
                                .padding(8)
                        }
                        Spacer()
                    }
                )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(anime.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                Text(anime.genres.prefix(2).joined(separator: " • "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
        .contentShape(Rectangle())
    }
}
