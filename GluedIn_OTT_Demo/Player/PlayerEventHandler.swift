//
//  PlayerEventHandler.swift
//  GluedIn_OTT_Demo
//
//  Observes AVPlayer via KVO and NotificationCenter, then forwards typed PlayerEvents
//  to its delegate. Keeps all AVPlayer observation logic out of the ViewController.
//

import AVFoundation
import Foundation

/// Receives forwarded player events from PlayerEventHandler.
protocol PlayerEventHandlerDelegate: AnyObject {
    func playerEventHandler(_ handler: PlayerEventHandler, didReceive event: PlayerEvent)
}

/// Attaches to an AVPlayer and translates raw KVO/notification callbacks into PlayerEvents.
final class PlayerEventHandler {

    // MARK: - Properties

    weak var delegate: PlayerEventHandlerDelegate?

    private weak var player: AVPlayer?

    /// KVO observations — held so they auto-cancel on dealloc.
    private var observations: [NSKeyValueObservation] = []

    // MARK: - Attach / Detach

    /// Call this after setting up AVPlayer. Starts all observations.
    func attach(to player: AVPlayer) {
        self.player = player
        observePlayerStatus(player)
        observeTimeControlStatus(player)
        registerNotifications()
    }

    /// Removes all KVO observations and notification registrations. Call in deinit or on dismissal.
    func detach() {
        observations.forEach { $0.invalidate() }
        observations.removeAll()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - KVO: Player Status (playerReady / playbackError)

    private func observePlayerStatus(_ player: AVPlayer) {
        let statusObs = player.observe(\.status, options: [.new]) { [weak self] player, _ in
            guard let self else { return }
            switch player.status {
            case .readyToPlay:
                self.emit(.playerReady)
            case .failed:
                let error = player.error ?? NSError(domain: "PlayerEventHandler", code: -1)
                self.emit(.playbackError(error))
            default:
                break
            }
        }
        observations.append(statusObs)
    }

    // MARK: - KVO: Time Control (started / paused / buffering)

    private func observeTimeControlStatus(_ player: AVPlayer) {
        let tcObs = player.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] player, change in
            guard let self else { return }
            let old = change.oldValue ?? .paused
            let new = player.timeControlStatus

            switch new {
            case .playing:
                // Distinguish "started" from "resumed after buffering"
                if old == .waitingToPlayAtSpecifiedRate {
                    self.emit(.bufferingEnded)
                }
                self.emit(.playbackStarted)

            case .paused:
                // Only fire paused if we were actually playing (not initial state)
                if old == .playing {
                    self.emit(.playbackPaused)
                }

            case .waitingToPlayAtSpecifiedRate:
                self.emit(.bufferingStarted)

            @unknown default:
                break
            }
        }
        observations.append(tcObs)
    }

    // MARK: - Notifications

    private func registerNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidPlayToEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailedToPlayToEnd),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: nil
        )
    }

    @objc private func playerItemDidPlayToEnd() {
        emit(.playbackCompleted)
    }

    @objc private func playerItemFailedToPlayToEnd(_ notification: Notification) {
        let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            ?? NSError(domain: "PlayerEventHandler", code: -2)
        emit(.playbackError(error))
    }

    // MARK: - Seek Tracking

    /// Call from the seek slider's touchUpInside handler after seek completes.
    func didSeek(to time: Double) {
        emit(.seekPerformed(toTime: time))
    }

    // MARK: - Emit

    private func emit(_ event: PlayerEvent) {
        delegate?.playerEventHandler(self, didReceive: event)
    }

    // MARK: - Deinit

    deinit {
        detach()
    }
}
