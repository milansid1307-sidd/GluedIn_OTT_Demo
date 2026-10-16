//
//  ContentRepositoryImpl.swift
//  GluedIn_OTT_Demo
//
//  Concrete repository — bridges the data source to domain models via ContentMapper.
//

import Foundation

/// Fetches raw DTOs from the data source and maps them to domain models.
final class ContentRepositoryImpl: ContentRepositoryProtocol {

    // MARK: - Dependencies
    private let dataSource: ContentDataSourceProtocol

    // MARK: - Init
    init(dataSource: ContentDataSourceProtocol) {
        self.dataSource = dataSource
    }

    // MARK: - ContentRepositoryProtocol

    func fetchHomeContent() async throws -> HomeContent {
        let dto = try await dataSource.fetchHomeContent()
        return ContentMapper.map(dto)
    }

    /// Finds a content item by ID within the full home response.
    /// In a real API this would be a dedicated endpoint: GET /content/:id
    func fetchContentDetail(id: String) async throws -> Content {
        let homeContent = try await fetchHomeContent()

        // Search hero banner first
        if homeContent.heroBanner.id == id {
            return homeContent.heroBanner
        }

        // Search all rails
        for rail in homeContent.rails {
            if let content = rail.items.first(where: { $0.id == id }) {
                return content
            }
        }

        throw ContentRepositoryError.contentNotFound(id: id)
    }

    func fetchMoreRails(page: Int) async throws -> [ContentRail] {
        let dtos = try await dataSource.fetchMoreRails(page: page)
        return dtos.map { ContentMapper.map($0) }
    }
}

// MARK: - Repository Errors

enum ContentRepositoryError: LocalizedError {
    case contentNotFound(id: String)

    var errorDescription: String? {
        switch self {
        case .contentNotFound(let id): return "Content with ID '\(id)' not found."
        }
    }
}
