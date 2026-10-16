//
//  ContentMapper.swift
//  GluedIn_OTT_Demo
//
//  Transforms Data-layer DTOs into Domain-layer models. Keeps mapping logic in one place.
//

import Foundation

/// Pure mapping namespace — no state, no dependencies.
enum ContentMapper {

    // MARK: - Content

    static func map(_ dto: ContentDTO) -> Content {
        return Content(
            id: dto.id,
            title: dto.title,
            description: dto.description,
            thumbnailURL: dto.thumbnailURL,
            bannerURL: dto.bannerURL,
            videoURL: dto.videoURL
        )
    }

    // MARK: - ContentRail

    static func map(_ dto: ContentRailDTO) -> ContentRail {
        return ContentRail(
            id: dto.id,
            title: dto.title,
            items: dto.items.map { map($0) }
        )
    }

    // MARK: - HomeContent

    static func map(_ dto: HomeResponseDTO) -> HomeContent {
        return HomeContent(
            heroBanner: map(dto.heroBanner),
            rails: dto.rails.map { map($0) }
        )
    }
}
