//
//  PlayerEvent.swift
//  GluedIn_OTT_Demo
//
//  Typed representation of all AVPlayer lifecycle events.
//  Events flow: AVPlayer → PlayerEventHandler → PlayerViewModel → AnalyticsEventRepository
//

import Foundation

/// All observable player events — add new cases here to extend the event vocabulary.
enum PlayerEvent {
    case playerReady
    case playbackStarted
    case playbackPaused
    case seekPerformed(toTime: Double)
    case bufferingStarted
    case bufferingEnded
    case playbackCompleted
    case playbackError(Error)

    // MARK: - Log String

    /// Human-readable log label matching the format requested in the assignment.
    var logLabel: String {
        switch self {
        case .playerReady:              return "PLAYER_READY"
        case .playbackStarted:          return "PLAYER_STARTED"
        case .playbackPaused:           return "PLAYER_PAUSED"
        case .seekPerformed(let t):     return "PLAYER_SEEKED to \(String(format: "%.2f", t))s"
        case .bufferingStarted:         return "PLAYER_BUFFERING_STARTED"
        case .bufferingEnded:           return "PLAYER_BUFFERING_ENDED"
        case .playbackCompleted:        return "PLAYER_COMPLETED"
        case .playbackError(let err):   return "PLAYER_ERROR: \(err.localizedDescription)"
        }
    }
}
