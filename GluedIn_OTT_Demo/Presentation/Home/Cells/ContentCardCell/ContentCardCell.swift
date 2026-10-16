//
//  ContentCardCell.swift
//  GluedIn_OTT_Demo
//
//  UICollectionViewCell for a single content item in a horizontal rail.
//  Views are programmatic — shimmer while loading, auto-retry on reconnect.
//

import UIKit

final class ContentCardCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "ContentCardCell"
    static let nibName = "ContentCardCell"

    // MARK: - Views

    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.18, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let gradientContainerView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .white
        lbl.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - Properties

    private var imageLoadTask: Task<Void, Never>?
    private var shimmerView: ShimmerView?
    private var pendingRetryURL: String?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        observeNetwork()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        observeNetwork()
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        imageLoadTask = nil
        pendingRetryURL = nil
        thumbnailImageView.image = nil
        thumbnailImageView.backgroundColor = UIColor(white: 0.18, alpha: 1)
        titleLabel.text = nil
        removeShimmer()
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(gradientContainerView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            gradientContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientContainerView.heightAnchor.constraint(equalToConstant: 55),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])

        addGradient(to: gradientContainerView)
    }

    private func addGradient(to view: UIView) {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.85).cgColor]
        gradient.locations = [0.0, 1.0]
        view.layer.insertSublayer(gradient, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientContainerView.layer.sublayers?.first?.frame = gradientContainerView.bounds
        shimmerView?.frame = thumbnailImageView.bounds
    }

    // MARK: - Configure

    func configure(with content: Content) {
        titleLabel.text = content.title
        loadImage(from: content.thumbnailURL)
    }

    // MARK: - Network Retry

    private func observeNetwork() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(retryPendingImage),
            name: .networkDidReconnect, object: nil
        )
    }

    @objc private func retryPendingImage() {
        guard let url = pendingRetryURL else { return }
        pendingRetryURL = nil
        loadImage(from: url)
    }

    // MARK: - Image Loading

    private func showShimmer() {
        removeShimmer()
        let s = ShimmerView(frame: thumbnailImageView.bounds)
        thumbnailImageView.addSubview(s)
        shimmerView = s
    }

    private func removeShimmer() {
        shimmerView?.removeFromSuperview()
        shimmerView = nil
    }

    private func loadImage(from urlString: String) {
        imageLoadTask?.cancel()

        if let cached = ImageCache.shared.image(for: urlString) {
            removeShimmer()
            thumbnailImageView.image = cached
            thumbnailImageView.backgroundColor = .clear
            return
        }

        thumbnailImageView.image = nil
        thumbnailImageView.backgroundColor = UIColor(white: 0.18, alpha: 1)
        showShimmer()

        guard let url = URL(string: urlString) else { return }

        imageLoadTask = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, let image = UIImage(data: data) else { return }
                ImageCache.shared.store(image, for: urlString)
                await MainActor.run {
                    guard let self else { return }
                    self.removeShimmer()
                    let iv = self.thumbnailImageView
                    UIView.transition(with: iv, duration: 0.25, options: .transitionCrossDissolve) {
                        iv.image = image
                        iv.backgroundColor = .clear
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.pendingRetryURL = urlString
                }
            }
        }
    }
}
