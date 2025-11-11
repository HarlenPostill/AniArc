//
//  AnimeItem.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import Foundation

// MARK: - Models
struct AnimeItem: Identifiable {
    let id = UUID()
    let title: String
    let imageURL: String
    let synopsis: String
    let rating: Double
    let genres: [String]
    let episodeCount: Int
    let status: String
}