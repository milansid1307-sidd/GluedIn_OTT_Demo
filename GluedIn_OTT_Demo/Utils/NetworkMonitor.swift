//
//  NetworkMonitor.swift
//  GluedIn_OTT_Demo
//
//  Wraps NWPathMonitor and broadcasts connectivity changes via NotificationCenter.
//  Image loaders subscribe to .networkDidReconnect to auto-retry stalled loads.
//

import Network
import Foundation

extension Notification.Name {
    static let networkDidReconnect   = Notification.Name("networkDidReconnect")
    static let networkDidDisconnect  = Notification.Name("networkDidDisconnect")
}

final class NetworkMonitor {

    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "com.gluedin.networkmonitor", qos: .utility)
    private var wasConnected = true

    private(set) var isConnected: Bool = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            DispatchQueue.main.async {
                let changed = connected != self.isConnected
                self.isConnected = connected
                guard changed else { return }
                if connected {
                    NotificationCenter.default.post(name: .networkDidReconnect, object: nil)
                } else {
                    NotificationCenter.default.post(name: .networkDidDisconnect, object: nil)
                }
            }
        }
        monitor.start(queue: queue)
    }

    /// Call once at app launch to activate the monitor.
    func startMonitoring() {}
}
