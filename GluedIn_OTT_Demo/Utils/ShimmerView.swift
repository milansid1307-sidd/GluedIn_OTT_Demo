//
//  ShimmerView.swift
//  GluedIn_OTT_Demo
//
//  Drop-in loading placeholder. Add as subview over an image view, call stopAnimating()
//  to fade it out and remove it once the real image is ready.
//

import UIKit

final class ShimmerView: UIView {

    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor(white: 0.13, alpha: 1)
        gradientLayer.colors = [
            UIColor(white: 0.13, alpha: 1).cgColor,
            UIColor(white: 0.24, alpha: 1).cgColor,
            UIColor(white: 0.13, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        gradientLayer.locations  = [0.0, 0.5, 1.0]
        layer.addSublayer(gradientLayer)
        startAnimating()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func startAnimating() {
        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue    = [-1.0, -0.5, 0.0]
        anim.toValue      = [1.0, 1.5, 2.0]
        anim.duration     = 1.3
        anim.repeatCount  = .infinity
        gradientLayer.add(anim, forKey: "shimmer")
    }

    /// Fades out and removes self from superview.
    func stopAnimating() {
        UIView.animate(withDuration: 0.25) { self.alpha = 0 } completion: { _ in
            self.gradientLayer.removeAnimation(forKey: "shimmer")
            self.removeFromSuperview()
        }
    }
}
