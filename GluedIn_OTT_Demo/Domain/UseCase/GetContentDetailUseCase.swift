//
//  GetContentDetailUseCase.swift
//  GluedIn_OTT_Demo
//
//  Use case that fetches detail for a single content item by ID.
//

import Foundation

/// Contract for the content detail fetching use case.
protocol GetContentDetailUseCaseProtocol {
    func execute(id: String) async throws -> Content
}

/// Concrete use case — fetches detail via the repository.
final class GetContentDetailUseCase: GetContentDetailUseCaseProtocol {

    // MARK: - Dependencies
    private let repository: ContentRepositoryProtocol

    // MARK: - Init
    init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Execution
    func execute(id: String) async throws -> Content {
        return try await repository.fetchContentDetail(id: id)
    }
}
