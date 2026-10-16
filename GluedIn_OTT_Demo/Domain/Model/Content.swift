//
//  Content.swift
//  GluedIn_OTT_Demo
//
//  Domain model representing a single piece of OTT content.
//

import Foundation

/// Core domain model for a watchable content item.
struct Content {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String
    let bannerURL: String
    let videoURL: String
}
