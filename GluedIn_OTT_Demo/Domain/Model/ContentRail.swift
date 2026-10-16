//
//  ContentRail.swift
//  GluedIn_OTT_Demo
//
//  Domain model representing a horizontally scrollable content category/rail.
//

import Foundation

/// A named category that groups multiple content items in a horizontal rail.
struct ContentRail {
    let id: String
    let title: String
    let items: [Content]
}
