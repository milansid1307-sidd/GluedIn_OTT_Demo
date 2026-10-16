//
//  HomeContent.swift
//  GluedIn_OTT_Demo
//
//  Aggregate domain model for the Home screen — hero banner + category rails.
//

import Foundation

/// Top-level model powering the Home screen layout.
struct HomeContent {
    let heroBanner: Content
    var rails: [ContentRail]
}
