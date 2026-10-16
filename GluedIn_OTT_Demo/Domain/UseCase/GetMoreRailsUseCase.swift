//
//  GetMoreRailsUseCase.swift
//  GluedIn_OTT_Demo
//
//  Use case that fetches additional content rails for pagination.
//

import Foundation

/// Contract for fetching paginated rails beyond the initial home content load.
protocol GetMoreRailsUseCaseProtocol {
    func execute(page: Int) async throws -> [ContentRail]
}

/// Delegates to the repository; page 1 is the initial load, pages 2+ are appended on scroll.
final class GetMoreRailsUseCase: GetMoreRailsUseCaseProtocol {

    private let repository: ContentRepositoryProtocol

    init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    func execute(page: Int) async throws -> [ContentRail] {
        try await repository.fetchMoreRails(page: page)
    }
}
