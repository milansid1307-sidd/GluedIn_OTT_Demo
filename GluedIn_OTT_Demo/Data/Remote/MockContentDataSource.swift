//
//  MockContentDataSource.swift
//  GluedIn_OTT_Demo
//
//  Returns a static JSON response simulating a real API — swap this for a URLSession
//  implementation once a real backend is available.
//

import Foundation

/// Reads MockHomeResponse.json from the app bundle and decodes it as a HomeResponseDTO.
final class MockContentDataSource: ContentDataSourceProtocol {

    // MARK: - Errors

    enum DataSourceError: LocalizedError {
        case fileNotFound(String)
        case decodingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let name):  return "Mock JSON file '\(name)' not found in bundle."
            case .decodingFailed(let err): return "Failed to decode mock JSON: \(err.localizedDescription)"
            }
        }
    }

    // MARK: - Nature Video Pool
    // 5 publicly accessible HLS streams with outdoor/nature content.
    // Sintel and Big Buck Bunny are Blender Foundation open movies with rich nature scenes.

    private static let natureVideos: [String] = [
        "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8",
        "https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny_metadata.m3u8",
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8",
        "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8",
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
    ]

    static func videoURL(for id: String) -> String {
        let index = abs(id.hashValue) % natureVideos.count
        return natureVideos[index]
    }

    // MARK: - ContentDataSourceProtocol

    func fetchMoreRails(page: Int) async throws -> [ContentRailDTO] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)

        switch page {
        case 2:
            return [
                ContentRailDTO(
                    id: "rail_p2_picks",
                    title: "Top Picks for You",
                    items: [
                        ContentDTO(id: "c_p2_001", title: "The Office", description: "A mockumentary on a group of typical office workers.", thumbnailURL: "https://picsum.photos/seed/theoffice/400/600", bannerURL: "https://picsum.photos/seed/theoffice/1200/675", videoURL: "https://cdn.pixabay.com/video/2020/04/24/37088-413229662_large.mp4"),
                        ContentDTO(id: "c_p2_002", title: "Friends", description: "Follows the personal and professional lives of six twenty to thirty-something-year-old friends.", thumbnailURL: "https://picsum.photos/seed/friendstv/400/600", bannerURL: "https://picsum.photos/seed/friendstv/1200/675", videoURL: "https://cdn.pixabay.com/video/2026/05/04/350522_large.mp4"),
                        ContentDTO(id: "c_p2_003", title: "Game of Thrones", description: "Nine noble families fight for control over the mythical lands of Westeros.", thumbnailURL: "https://picsum.photos/seed/gameofthrones/400/600", bannerURL: "https://picsum.photos/seed/gameofthrones/1200/675", videoURL: "https://cdn.pixabay.com/video/2023/04/28/160767-822213540_large.mp4"),
                        ContentDTO(id: "c_p2_004", title: "Peaky Blinders", description: "A gangster family epic set in 1900s England.", thumbnailURL: "https://picsum.photos/seed/peakyblinders/400/600", bannerURL: "https://picsum.photos/seed/peakyblinders/1200/675", videoURL: "https://cdn.pixabay.com/video/2022/03/18/111101-689925384_large.mp4"),
                        ContentDTO(id: "c_p2_005", title: "Black Mirror", description: "An anthology series that taps into our collective unease with the modern world.", thumbnailURL: "https://picsum.photos/seed/blackmirror/400/600", bannerURL: "https://picsum.photos/seed/blackmirror/1200/675", videoURL: "https://cdn.pixabay.com/video/2023/01/15/146606-789534239_large.mp4")
                    ]
                ),
                ContentRailDTO(
                    id: "rail_p2_awards",
                    title: "Award Winners",
                    items: [
                        ContentDTO(id: "c_p2_006", title: "Chernobyl", description: "In April 1986, an explosion at the Chernobyl nuclear power plant becomes one of the world's worst man-made catastrophes.", thumbnailURL: "https://picsum.photos/seed/chernobyl/400/600", bannerURL: "https://picsum.photos/seed/chernobyl/1200/675", videoURL: "https://cdn.pixabay.com/video/2021/08/04/83880-585600454_large.mp4"),
                        ContentDTO(id: "c_p2_007", title: "Fleabag", description: "A comedy series adapted from the award-winning, one-woman show about a dry-witted woman.", thumbnailURL: "https://picsum.photos/seed/fleabag/400/600", bannerURL: "https://picsum.photos/seed/fleabag/1200/675", videoURL: "https://cdn.pixabay.com/video/2021/01/18/62249-503297067_large.mp4"),
                        ContentDTO(id: "c_p2_008", title: "Severance", description: "Mark leads a team of office workers whose memories have been surgically divided between work and personal lives.", thumbnailURL: "https://picsum.photos/seed/severance/400/600", bannerURL: "https://picsum.photos/seed/severance/1200/675", videoURL: "https://cdn.pixabay.com/video/2020/04/24/37088-413229662_large.mp4"),
                        ContentDTO(id: "c_p2_009", title: "The White Lotus", description: "Follows various guests and employees of the White Lotus chain of hotels.", thumbnailURL: "https://picsum.photos/seed/whitelotus/400/600", bannerURL: "https://picsum.photos/seed/whitelotus/1200/675", videoURL: "https://cdn.pixabay.com/video/2026/05/04/350522_large.mp4")
                    ]
                )
            ]
        case 3:
            return [
                ContentRailDTO(
                    id: "rail_p3_intl",
                    title: "International",
                    items: [
                        ContentDTO(id: "c_p3_001", title: "Money Heist", description: "Eight thieves take hostages and lock themselves in the Royal Mint of Spain.", thumbnailURL: "https://picsum.photos/seed/moneyheist/400/600", bannerURL: "https://picsum.photos/seed/moneyheist/1200/675", videoURL: "https://cdn.pixabay.com/video/2023/04/28/160767-822213540_large.mp4"),
                        ContentDTO(id: "c_p3_002", title: "Lupin", description: "Inspired by the adventures of Arsène Lupin, gentleman thief Assane Diop sets out to avenge his father.", thumbnailURL: "https://picsum.photos/seed/lupintv/400/600", bannerURL: "https://picsum.photos/seed/lupintv/1200/675", videoURL: "https://cdn.pixabay.com/video/2022/03/18/111101-689925384_large.mp4"),
                        ContentDTO(id: "c_p3_003", title: "Sacred Games", description: "A link in the chain of past events connects a police officer with a gang lord.", thumbnailURL: "https://picsum.photos/seed/sacredgames/400/600", bannerURL: "https://picsum.photos/seed/sacredgames/1200/675", videoURL: "https://cdn.pixabay.com/video/2023/01/15/146606-789534239_large.mp4"),
                        ContentDTO(id: "c_p3_004", title: "Babylon Berlin", description: "Set in 1929 Berlin, a police inspector investigates a sinister conspiracy.", thumbnailURL: "https://picsum.photos/seed/babylonberlin/400/600", bannerURL: "https://picsum.photos/seed/babylonberlin/1200/675", videoURL: "https://cdn.pixabay.com/video/2021/08/04/83880-585600454_large.mp4")
                    ]
                ),
                ContentRailDTO(
                    id: "rail_p3_docs",
                    title: "Documentaries",
                    items: [
                        ContentDTO(id: "c_p3_005", title: "Our Planet", description: "Experience Earth's natural beauty and examine how climate change impacts all living creatures.", thumbnailURL: "https://picsum.photos/seed/ourplanet/400/600", bannerURL: "https://picsum.photos/seed/ourplanet/1200/675", videoURL: "https://cdn.pixabay.com/video/2021/01/18/62249-503297067_large.mp4"),
                        ContentDTO(id: "c_p3_006", title: "Making a Murderer", description: "Filmed over 10 years, this documentary follows Steven Avery and Brendan Dassey's trials.", thumbnailURL: "https://picsum.photos/seed/makingamurderer/400/600", bannerURL: "https://picsum.photos/seed/makingamurderer/1200/675", videoURL: "https://cdn.pixabay.com/video/2020/04/24/37088-413229662_large.mp4"),
                        ContentDTO(id: "c_p3_007", title: "Tiger King", description: "A zoo owner spirals out of control amid a cast of eccentric characters.", thumbnailURL: "https://picsum.photos/seed/tigerking/400/600", bannerURL: "https://picsum.photos/seed/tigerking/1200/675", videoURL: "https://cdn.pixabay.com/video/2026/05/04/350522_large.mp4")
                    ]
                )
            ]
        default:
            // No more pages
            return []
        }
    }

    func fetchHomeContent() async throws -> HomeResponseDTO {
        // Simulate a small network delay to exercise loading states in the UI.
        try await Task.sleep(nanoseconds: 500_000_000)

        let fileName = "MockHomeResponse"
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw DataSourceError.fileNotFound(fileName)
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(HomeResponseDTO.self, from: data)
        } catch let decodingError as DecodingError {
            throw DataSourceError.decodingFailed(decodingError)
        }
    }
}
