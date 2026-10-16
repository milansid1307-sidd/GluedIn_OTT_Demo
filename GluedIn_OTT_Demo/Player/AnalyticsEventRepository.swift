//
//  AnalyticsEventRepository.swift
//  GluedIn_OTT_Demo
//
//  Receives player events from the ViewModel and logs/dispatches them.
//  Replace the print statements with real SDK calls (Firebase, Mixpanel, etc.) here.
//

import Foundation
import os.log

/// Contract for analytics event tracking — keeps the ViewModel decoupled from the SDK.
protocol AnalyticsEventRepositoryProtocol {
    func track(event: PlayerEvent)
}

/// Console-logging implementation — satisfies the protocol without coupling to any SDK.
final class AnalyticsEventRepository: AnalyticsEventRepositoryProtocol {

    // MARK: - Logger

    private let logger = Logger(subsystem: "com.gluedIn.OTT", category: "PlayerAnalytics")

    // MARK: - AnalyticsEventRepositoryProtocol

    func track(event: PlayerEvent) {
        // In production: analyticsSDK.log(event.logLabel, properties: buildProperties(event))
        logger.info("📊 \(event.logLabel, privacy: .public)")
    }
}
