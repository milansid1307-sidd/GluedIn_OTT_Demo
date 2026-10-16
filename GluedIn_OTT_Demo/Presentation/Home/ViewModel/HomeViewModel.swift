//
//  HomeViewModel.swift
//  GluedIn_OTT_Demo
//
//  Drives the Home screen UI state. Fetches via GetHomeContentUseCase and
//  publishes ViewState changes for the ViewController to react to.
//

import Foundation

// MARK: - ViewState

/// Generic screen state enum used across all ViewModels.
enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case empty
    case error(String)
}

// MARK: - HomeViewModel

@MainActor
final class HomeViewModel {

    // MARK: - Dependencies

    private let useCase: GetHomeContentUseCaseProtocol
    private let moreRailsUseCase: GetMoreRailsUseCaseProtocol

    // MARK: - Bindings

    /// Called on full state transitions (loading, error, initial success, retry).
    /// NOT called during pagination — use onRailsAppended for that.
    var onStateChange: ((ViewState<HomeContent>) -> Void)?
    /// Called only when new rails are appended via pagination. VC uses insertRows.
    var onRailsAppended: ((_ newCount: Int) -> Void)?

    // MARK: - State

    private(set) var state: ViewState<HomeContent> = .idle {
        didSet { onStateChange?(state) }
    }

    // MARK: - Content Backing Store
    // Separate from state so pagination appends don't re-trigger onStateChange.

    private var homeContent: HomeContent?

    // MARK: - Pagination State

    private var currentPage = 1
    private(set) var isLoadingNextPage = false
    private(set) var hasMorePages = true

    // MARK: - Derived Data

    var heroBanner: Content? { homeContent?.heroBanner }

    var rails: [ContentRail] { homeContent?.rails ?? [] }

    // MARK: - Init

    init(useCase: GetHomeContentUseCaseProtocol, moreRailsUseCase: GetMoreRailsUseCaseProtocol) {
        self.useCase = useCase
        self.moreRailsUseCase = moreRailsUseCase
    }

    // MARK: - Actions

    func loadContent() {
        guard case .idle = state else { return }
        state = .loading

        Task {
            do {
                let content = try await useCase.execute()
                if content.rails.isEmpty && content.heroBanner.id.isEmpty {
                    self.state = .empty
                } else {
                    self.homeContent = content
                    self.state = .success(content)
                }
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }

    /// Loads the next page of rails and appends them without triggering a full reload.
    func loadNextPage() {
        guard !isLoadingNextPage, hasMorePages, homeContent != nil else { return }
        isLoadingNextPage = true
        let nextPage = currentPage + 1

        Task {
            do {
                let newRails = try await moreRailsUseCase.execute(page: nextPage)
                if newRails.isEmpty {
                    self.hasMorePages = false
                } else {
                    self.homeContent?.rails.append(contentsOf: newRails)
                    self.currentPage = nextPage
                    // Notify VC for row insertion — don't update state (avoids reloadData)
                    self.onRailsAppended?(newRails.count)
                }
            } catch {
                // Silent — pagination failure doesn't affect current content
            }
            self.isLoadingNextPage = false
        }
    }

    /// Allows manual retry after an error.
    func retry() {
        homeContent = nil
        currentPage = 1
        hasMorePages = true
        state = .idle
        loadContent()
    }
}
