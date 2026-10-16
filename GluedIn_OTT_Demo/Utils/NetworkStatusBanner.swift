//
//  NetworkStatusBanner.swift
//  GluedIn_OTT_Demo
//
//  Non-blocking pill banner shown at top of the window when connectivity changes.
//  Offline pill stays until reconnect; "Back Online" pill auto-dismisses after 1.5 s.
//

import UIKit

final class NetworkStatusBanner {

    static let shared = NetworkStatusBanner()
    private var pill: UIView?
    private var dismissTimer: Timer?

    private init() {}

    func show(connected: Bool) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        dismissTimer?.invalidate()
        pill?.removeFromSuperview()

        let container = UIView()
        container.backgroundColor = connected
            ? UIColor(red: 0.15, green: 0.72, blue: 0.38, alpha: 1)
            : UIColor(red: 0.85, green: 0.12, blue: 0.12, alpha: 1)
        container.layer.cornerRadius = 16
        container.clipsToBounds = true

        let label = UILabel()
        label.text   = connected ? "✓  Back Online" : "✕  No Internet Connection"
        label.textColor = .white
        label.font   = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.sizeToFit()

        let pillW = label.frame.width + 32
        let pillH: CGFloat = 32
        let safeTop = window.safeAreaInsets.top
        let xPos = (window.bounds.width - pillW) / 2

        container.frame = CGRect(x: xPos, y: -(pillH + 8), width: pillW, height: pillH)
        label.frame = CGRect(x: 16, y: (pillH - label.frame.height) / 2,
                             width: label.frame.width, height: label.frame.height)
        container.addSubview(label)
        window.addSubview(container)
        pill = container

        UIView.animate(withDuration: 0.38, delay: 0,
                       usingSpringWithDamping: 0.72, initialSpringVelocity: 0.4) {
            container.frame.origin.y = safeTop + 8
        }

        if connected {
            dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                self?.hidePill()
            }
        }
        // Offline pill stays until .networkDidReconnect triggers a new show(connected: true)
    }

    private func hidePill() {
        guard let p = pill else { return }
        UIView.animate(withDuration: 0.25) {
            p.frame.origin.y = -(p.frame.height + 8)
        } completion: { _ in
            p.removeFromSuperview()
            self.pill = nil
        }
    }
}
