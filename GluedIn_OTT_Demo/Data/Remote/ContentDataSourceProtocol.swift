//
//  ContentDataSourceProtocol.swift
//  GluedIn_OTT_Demo
//
//  Contract for the raw data source. Replace MockContentDataSource with a URLSession
//  implementation here — nothing above this layer needs to change.
//

import Foundation

/// Abstracts where the raw API response comes from (mock JSON, URLSession, cache, etc.).
protocol ContentDataSourceProtocol {
    func fetchHomeContent() async throws -> HomeResponseDTO
    /// Returns additional rails for the given page number (1-indexed, page 1 = initial load).
    /// Returns empty array when no more pages are available.
    func fetchMoreRails(page: Int) async throws -> [ContentRailDTO]
}
