//
//  ContentRepositoryProtocol.swift
//  GluedIn_OTT_Demo
//
//  Repository contract for content data. Swap the concrete impl to change data sources.
//

import Foundation

/// Abstracts all content data operations — domain layer depends on this, never on concrete repos.
protocol ContentRepositoryProtocol {
    func fetchHomeContent() async throws -> HomeContent
    func fetchContentDetail(id: String) async throws -> Content
    func fetchMoreRails(page: Int) async throws -> [ContentRail]
}
