//
//  PlayerViewModel.swift
//  GluedIn_OTT_Demo
//
//  Receives player events from PlayerEventHandler and forwards them to the
//  analytics repository. Also owns UI-facing playback state for the PlayerViewController.
//

import Foundation
import AVFoundation

// MARK: - PlayerViewModelDelegate

/// Notifies the PlayerViewController of UI state changes driven by player events.
protocol PlayerViewModelDelegate: AnyObject {
    func playerViewModel(_ vm: PlayerViewModel, didUpdatePlaybackState isPlaying: Bool)
    func playerViewModel(_ vm: PlayerViewModel, didUpdateProgress progress: Float, duration: Float)
    func playerViewModelDidComplete(_ vm: PlayerViewModel)
    func playerViewModel(_ vm: PlayerViewModel, didEncounterError message: String)
}

// MARK: - PlayerViewModel

@MainActor
final class PlayerViewModel {

    // MARK: - Dependencies

    private let analyticsRepository: AnalyticsEventRepositoryProtocol

    // MARK: - Public State

    let content: Content
    private(set) var isPlaying: Bool = false
    private(set) var currentTime: Float = 0
    private(set) var duration: Float = 0

    // MARK: - Delegate

    weak var delegate: PlayerViewModelDelegate?

    // MARK: - Init

    init(content: Content, analyticsRepository: AnalyticsEventRepositoryProtocol) {
        self.content = content
        self.analyticsRepository = analyticsRepository
    }

    // MARK: - Player Event Handling

    /// Entry point for all events forwarded by PlayerEventHandler.
    func handle(event: PlayerEvent) {
        // Always log to analytics
        analyticsRepository.track(event: event)

        // Update UI state based on event
        switch event {
        case .playerReady:
            break

        case .playbackStarted:
            isPlaying = true
            delegate?.playerViewModel(self, didUpdatePlaybackState: true)

        case .playbackPaused:
            isPlaying = false
            delegate?.playerViewModel(self, didUpdatePlaybackState: false)

        case .seekPerformed:
            // Progress UI update comes from the periodic time observer
            break

        case .bufferingStarted:
            break   // buffering ≠ paused; do not flip isPlaying

        case .bufferingEnded:
            break

        case .playbackCompleted:
            isPlaying = false
            delegate?.playerViewModelDidComplete(self)

        case .playbackError(let error):
            isPlaying = false
            delegate?.playerViewModel(self, didEncounterError: error.localizedDescription)
        }
    }

    // MARK: - Progress Update

    /// Called by PlayerViewController on each periodic time observer tick.
    func updateProgress(current: Float, duration: Float) {
        self.currentTime = current
        self.duration = duration
        delegate?.playerViewModel(self, didUpdateProgress: current, duration: duration)
    }
}
