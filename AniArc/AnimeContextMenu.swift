//
//  AnimeContextMenu.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct AnimeContextMenu: View {
    let anime: AnimeItem
    @Environment(UserDataManager.self) var userDataManager
    
    var body: some View {
        Button(action: { addToWatchlist() }) {
            Label(userDataManager.isInWatchlist(anime.id) ? "Remove from Watchlist" : "Add to Watchlist", 
                  systemImage: userDataManager.isInWatchlist(anime.id) ? "minus.circle" : "plus.circle")
        }
        
        Button(action: { toggleFavorite() }) {
            Label(userDataManager.isFavorite(anime.id) ? "Remove from Favorites" : "Add to Favorites", 
                  systemImage: userDataManager.isFavorite(anime.id) ? "heart.slash" : "heart")
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
    
    private func toggleFavorite() {
        userDataManager.toggleFavorite(anime.id)
    }
    
    private func addToWatchlist() {
        if userDataManager.isInWatchlist(anime.id) {
            userDataManager.removeFromWatchlist(anime.id)
        } else {
            userDataManager.addToWatchlist(anime)
        }
    }
    
    private func shareAnime() {
        print("Sharing \(anime.title)")
    }
    
    private func markAsWatched() {
        userDataManager.updateWatchStatus(animeID: anime.id, status: .completed)
    }
    
    private func reportContent() {
        print("Reporting \(anime.title)")
    }
}