//
//  HomeResponseDTO.swift
//  GluedIn_OTT_Demo
//
//  Codable DTOs mirroring the mock API JSON response structure.
//

import Foundation

/// Top-level API response for the home screen.
struct HomeResponseDTO: Codable {
    let heroBanner: ContentDTO
    let rails: [ContentRailDTO]
}

/// DTO for a single category/rail returned by the API.
struct ContentRailDTO: Codable {
    let id: String
    let title: String
    let items: [ContentDTO]
}

/// DTO for a single content item returned by the API.
struct ContentDTO: Codable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String
    let bannerURL: String
    let videoURL: String

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case thumbnailURL = "thumbnail_url"
        case bannerURL    = "banner_url"
        case videoURL     = "video_url"
    }
}
