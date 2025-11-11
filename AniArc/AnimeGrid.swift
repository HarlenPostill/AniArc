//
//  AnimeGrid.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct AnimeGrid: View {
    let animeItems: [AnimeItem]
    let isLoading: Bool
    let onLoadMore: (() -> Void)?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    init(animeItems: [AnimeItem], isLoading: Bool = false, onLoadMore: (() -> Void)? = nil) {
        self.animeItems = animeItems
        self.isLoading = isLoading
        self.onLoadMore = onLoadMore
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(animeItems) { item in
                AnimeCard(anime: item)
                    .onAppear {
                        // Load more items when reaching the end
                        if item.id == animeItems.last?.id {
                            onLoadMore?()
                        }
                    }
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .gridCellColumns(2)
                    .padding()
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
}

#Preview {
    ScrollView {
        AnimeGrid(
            animeItems: [
                AnimeItem(
                    title: "Preview Anime",
                    imageURL: "preview_image",
                    synopsis: "A preview anime item",
                    rating: 8.5,
                    genres: ["Action", "Adventure"],
                    episodeCount: 24,
                    status: "Ongoing"
                )
            ],
            isLoading: false
        )
    }
}