//
//  ContentDetailViewModel.swift
//  GluedIn_OTT_Demo
//
//  Drives the Content Detail screen. Accepts a pre-resolved Content model (passed from Home)
//  or fetches by ID when arriving from a deep link.
//
//  Business logic responsibility: ContentPresentationData is resolved here, not in the VC.
//  The VC only binds to `presentationData` for rendering.
//

import Foundation

// MARK: - ContentPresentationData

/// Presentation metadata for a piece of content — resolved from domain Content in the ViewModel.
/// Kept in the ViewModel layer so the VC has zero data-mapping logic.
struct ContentPresentationData {
    let year: String
    let rating: String
    let seasons: String
    let quality: String
    let genres: [String]
    let cast: String    
    let creator: String
    let adjectives: [String]

    // swiftlint:disable:next function_body_length
    static func resolve(for content: Content) -> ContentPresentationData {
        switch content.id {
        case "hero_001":
            return .init(year: "2016", rating: "TV-14", seasons: "4 Seasons", quality: "4K",
                         genres: ["Sci-Fi", "Horror", "Drama"],
                         cast: "Millie Bobby Brown, Finn Wolfhard, David Harbour, Winona Ryder",
                         creator: "The Duffer Brothers",
                         adjectives: ["Suspenseful", "Scary", "Exciting"])
        case "c_001":
            return .init(year: "2008", rating: "TV-MA", seasons: "5 Seasons", quality: "HD",
                         genres: ["Drama", "Crime", "Thriller"],
                         cast: "Bryan Cranston, Aaron Paul, Anna Gunn, Jonathan Banks",
                         creator: "Vince Gilligan",
                         adjectives: ["Dark", "Suspenseful", "Critically acclaimed"])
        case "c_002":
            return .init(year: "2016", rating: "TV-MA", seasons: "6 Seasons", quality: "4K",
                         genres: ["Drama", "History", "Biography"],
                         cast: "Claire Foy, Olivia Colman, Imelda Staunton, Matt Smith",
                         creator: "Peter Morgan",
                         adjectives: ["Regal", "Dramatic", "Critically acclaimed"])
        case "c_003":
            return .init(year: "2021", rating: "TV-MA", seasons: "2 Seasons", quality: "4K",
                         genres: ["Thriller", "Drama", "Action"],
                         cast: "Lee Jung-jae, Park Hae-soo, Oh Yeong-su, HoYeon Jung",
                         creator: "Hwang Dong-hyuk",
                         adjectives: ["Intense", "Dark", "Thought-provoking"])
        case "c_004":
            return .init(year: "2019", rating: "TV-MA", seasons: "3 Seasons", quality: "HD",
                         genres: ["Fantasy", "Action", "Drama"],
                         cast: "Henry Cavill, Anya Chalotra, Freya Allan, Joey Batey",
                         creator: "Lauren Schmidt Hissrich",
                         adjectives: ["Epic", "Fantasy", "Action-packed"])
        case "c_005":
            return .init(year: "2017", rating: "TV-MA", seasons: "3 Seasons", quality: "HD",
                         genres: ["Sci-Fi", "Thriller", "Mystery"],
                         cast: "Louis Hofmann, Lisa Vicari, Oliver Masucci, Karoline Eichhorn",
                         creator: "Baran bo Odar, Jantje Friese",
                         adjectives: ["Mind-bending", "Dark", "Complex"])
        case "c_006":
            return .init(year: "2017", rating: "TV-MA", seasons: "4 Seasons", quality: "HD",
                         genres: ["Crime", "Drama", "Thriller"],
                         cast: "Jason Bateman, Laura Linney, Julia Garner, Sofia Hublitz",
                         creator: "Bill Dubuque, Mark Williams",
                         adjectives: ["Tense", "Dark", "Gripping"])
        case "c_007":
            return .init(year: "2017", rating: "TV-MA", seasons: "2 Seasons", quality: "HD",
                         genres: ["Crime", "Drama", "Biography"],
                         cast: "Jonathan Groff, Holt McCallany, Anna Torv, Hannah Gross",
                         creator: "Joe Penhall",
                         adjectives: ["Chilling", "Psychological", "Slow-burn"])
        case "c_008":
            return .init(year: "2022", rating: "TV-14", seasons: "2 Seasons", quality: "4K",
                         genres: ["Horror", "Comedy", "Mystery"],
                         cast: "Jenna Ortega, Gwendoline Christie, Christina Ricci, Hunter Doohan",
                         creator: "Alfred Gough, Miles Millar",
                         adjectives: ["Witty", "Dark", "Fun"])
        case "c_009":
            return .init(year: "2023", rating: "TV-MA", seasons: "2 Seasons", quality: "4K",
                         genres: ["Drama", "Action", "Sci-Fi"],
                         cast: "Pedro Pascal, Bella Ramsey, Anna Torv, Gabriel Luna",
                         creator: "Craig Mazin, Neil Druckmann",
                         adjectives: ["Emotional", "Intense", "Critically acclaimed"])
        case "c_010":
            return .init(year: "2022", rating: "TV-MA", seasons: "2 Seasons", quality: "4K",
                         genres: ["Fantasy", "Drama", "Action"],
                         cast: "Paddy Considine, Matt Smith, Olivia Cooke, Emma D'Arcy",
                         creator: "Ryan J. Condal, George R.R. Martin",
                         adjectives: ["Epic", "Political", "Dramatic"])
        case "c_011":
            return .init(year: "2023", rating: "TV-MA", seasons: "1 Season", quality: "HD",
                         genres: ["Dark Comedy", "Drama", "Thriller"],
                         cast: "Steven Yeun, Ali Wong, Joseph Lee, Young Mazino",
                         creator: "Lee Sung Jin",
                         adjectives: ["Sharp", "Funny", "Intense"])
        case "c_012":
            return .init(year: "2022", rating: "TV-MA", seasons: "3 Seasons", quality: "4K",
                         genres: ["Drama", "Comedy", "Culinary"],
                         cast: "Jeremy Allen White, Ayo Edebiri, Ebon Moss-Bachrach, Lionel Boyce",
                         creator: "Christopher Storer",
                         adjectives: ["Frenetic", "Emotional", "Award-winning"])
        case "c_013":
            return .init(year: "2018", rating: "TV-MA", seasons: "4 Seasons", quality: "HD",
                         genres: ["Drama", "Satire", "Dark Comedy"],
                         cast: "Brian Cox, Jeremy Strong, Sarah Snook, Kieran Culkin",
                         creator: "Jesse Armstrong",
                         adjectives: ["Savage", "Witty", "Critically acclaimed"])
        default:
            return .init(year: "2023", rating: "TV-MA", seasons: "1 Season", quality: "HD",
                         genres: ["Drama", "Thriller"],
                         cast: "Ensemble Cast",
                         creator: "Original Creator",
                         adjectives: ["Critically acclaimed", "Emotional"])
        }
    }
}

// MARK: - ContentDetailViewModel

@MainActor
final class ContentDetailViewModel {

    // MARK: - Dependencies

    private let useCase: GetContentDetailUseCaseProtocol

    // MARK: - Bindings

    var onStateChange: ((ViewState<Content>) -> Void)?

    // MARK: - State

    private(set) var state: ViewState<Content> = .idle {
        didSet { onStateChange?(state) }
    }

    /// Convenience accessor for the loaded content.
    var content: Content? {
        guard case .success(let c) = state else { return nil }
        return c
    }

    /// Resolved presentation metadata — nil until content is available.
    /// VC reads this instead of computing metadata itself.
    var presentationData: ContentPresentationData? {
        guard let c = content else { return nil }
        return ContentPresentationData.resolve(for: c)
    }

    // MARK: - Init

    init(useCase: GetContentDetailUseCaseProtocol) {
        self.useCase = useCase
    }

    // MARK: - Actions

    /// Loads detail by fetching from the use case (supports deep link entry point).
    func loadDetail(id: String) {
        state = .loading

        Task {
            do {
                let content = try await useCase.execute(id: id)
                self.state = .success(content)
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }

    /// Skips the network call when the full Content model is already available (Home → Detail flow).
    func setContent(_ content: Content) {
        state = .success(content)
    }
}
