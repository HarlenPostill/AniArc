//
//  AnimeContextMenu.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct AnimeContextMenu: View {
    let anime: AnimeItem
    
    var body: some View {
        Button(action: { saveAnime() }) {
            Label("Save to Library", systemImage: "bookmark")
        }
        
        Button(action: { addToWatchlist() }) {
            Label("Add to Watchlist", systemImage: "plus.circle")
        }
        
        Button(action: { shareAnime() }) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        
        Divider()
        
        Button(action: { markAsWatched() }) {
            Label("Mark as Watched", systemImage: "checkmark.circle")
        }
        
        Button(action: { reportContent() }) {
            Label("Report", systemImage: "exclamationmark.triangle")
        }
    }
    
    private func saveAnime() {
        print("Saving \(anime.title)")
    }
    
    private func addToWatchlist() {
        print("Adding \(anime.title) to watchlist")
    }
    
    private func shareAnime() {
        print("Sharing \(anime.title)")
    }
    
    private func markAsWatched() {
        print("Marking \(anime.title) as watched")
    }
    
    private func reportContent() {
        print("Reporting \(anime.title)")
    }
}