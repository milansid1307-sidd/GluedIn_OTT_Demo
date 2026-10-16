//
//  GetHomeContentUseCase.swift
//  GluedIn_OTT_Demo
//
//  Use case that fetches the full home screen content (hero + rails).
//

import Foundation

/// Contract for the home content fetching use case.
protocol GetHomeContentUseCaseProtocol {
    func execute() async throws -> HomeContent
}

/// Concrete use case — delegates to the repository, applies no extra business logic here.
final class GetHomeContentUseCase: GetHomeContentUseCaseProtocol {

    // MARK: - Dependencies
    private let repository: ContentRepositoryProtocol

    // MARK: - Init
    init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Execution
    func execute() async throws -> HomeContent {
        return try await repository.fetchHomeContent()
    }
}
