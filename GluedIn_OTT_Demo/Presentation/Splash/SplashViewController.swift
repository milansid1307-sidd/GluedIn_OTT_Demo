//
//  SplashViewController.swift
//  GluedIn_OTT_Demo
//
//  Shows splash_screen.gif full-screen for 1 second, then swaps root to HomeViewController.
//

import UIKit
import ImageIO

final class SplashViewController: UIViewController {

    private let gifImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupGIF()
        scheduleTransition()
    }

    private func setupGIF() {
        gifImageView.contentMode = .scaleAspectFill
        gifImageView.clipsToBounds = true
        gifImageView.frame = view.bounds
        gifImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(gifImageView)

        if let image = UIImage.animatedGIF(named: "splash_screen") {
            gifImageView.image = image
        }
    }

    private func scheduleTransition() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
            self?.transitionToHome()
        }
    }

    private func transitionToHome() {
        let homeVC = HomeViewController.instantiate()
        let nav = UINavigationController(rootViewController: homeVC)
        nav.navigationBar.barStyle = .black
        nav.navigationBar.isTranslucent = true

        guard let window = view.window else { return }
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
            window.rootViewController = nav
        }
    }
}

// MARK: - UIImage GIF Decoder

extension UIImage {

    static func animatedGIF(named name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "gif"),
              let data = NSData(contentsOfFile: path),
              let source = CGImageSourceCreateWithData(data, nil) else { return nil }

        let count = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var totalDuration: Double = 0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            let delay = gifFrameDelay(source: source, index: i)
            totalDuration += delay
            // Repeat frame to approximate timing at ~100ms per slot
            let repeatCount = max(1, Int(delay / 0.1))
            for _ in 0..<repeatCount {
                frames.append(UIImage(cgImage: cgImage))
            }
        }

        return UIImage.animatedImage(with: frames, duration: totalDuration)
    }

    private static func gifFrameDelay(source: CGImageSource, index: Int) -> Double {
        let defaultDelay = 0.1
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
              let gifProps = props[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
            return defaultDelay
        }
        let delay = (gifProps[kCGImagePropertyGIFUnclampedDelayTime as String]
                  ?? gifProps[kCGImagePropertyGIFDelayTime as String]) as? Double ?? defaultDelay
        return delay > 0.01 ? delay : defaultDelay
    }
}
