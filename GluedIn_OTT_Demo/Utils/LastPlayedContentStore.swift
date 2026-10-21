//
//  LastPlayedContentStore.swift
//  GluedIn_OTT_Demo
//

import Foundation

final class LastPlayedContentStore {

    private static let key = "last_played_content"

    static func save(_ content: Content) {
        guard let data = try? JSONEncoder().encode(content) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> Content? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Content.self, from: data)
    }
}
