//
//  ImageCache.swift
//  GluedIn_OTT_Demo
//
//  In-memory NSCache for decoded UIImage objects. Prevents redundant network
//  fetches for images already loaded in the current session.
//

import UIKit

/// Shared in-memory image cache backed by NSCache (auto-evicted under memory pressure).
final class ImageCache {

    static let shared = ImageCache()

    private let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 150
        c.totalCostLimit = 50 * 1024 * 1024  // ~50 MB
        return c
    }()

    private init() {}

    func image(for urlString: String) -> UIImage? {
        cache.object(forKey: urlString as NSString)
    }

    func store(_ image: UIImage, for urlString: String) {
        // Cost = approximate byte size of uncompressed RGBA image
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        cache.setObject(image, forKey: urlString as NSString, cost: cost)
    }
}
