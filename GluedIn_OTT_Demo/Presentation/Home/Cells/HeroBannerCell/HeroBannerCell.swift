//
//  HeroBannerCell.swift
//  GluedIn_OTT_Demo
//
//  UITableViewCell for the large hero banner at the top of the Home screen.
//  Shows shimmer while loading; auto-retries when network reconnects.
//

import UIKit

// MARK: - Delegate

protocol HeroBannerCellDelegate: AnyObject {
    func heroBannerCellDidTapCTA(_ cell: HeroBannerCell)
}

// MARK: - HeroBannerCell

final class HeroBannerCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet private weak var bannerImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var ctaButton: UIButton!
    @IBOutlet private weak var gradientView: UIView!

    // MARK: - Constants

    static let reuseIdentifier = "HeroBannerCell"
    static let nibName = "HeroBannerCell"

    // MARK: - Properties

    weak var delegate: HeroBannerCellDelegate?
    private var imageLoadTask: Task<Void, Never>?
    private var shimmerView: ShimmerView?
    private var pendingRetryURL: String?

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        observeNetwork()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        imageLoadTask = nil
        pendingRetryURL = nil
        bannerImageView.image = nil
        titleLabel.text = nil
        descriptionLabel.text = nil
        removeShimmer()
    }

    // MARK: - Setup

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .black
        contentView.backgroundColor = .black

        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true

        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        titleLabel.numberOfLines = 2

        descriptionLabel.textColor = UIColor(white: 0.85, alpha: 1)
        descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.numberOfLines = 3

        setupCTAButton()
        addGradient(to: gradientView)
    }

    private func setupCTAButton() {
        ctaButton.backgroundColor = .white
        ctaButton.setTitleColor(.black, for: .normal)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        ctaButton.layer.cornerRadius = 5
        ctaButton.setTitle("▶  Play", for: .normal)
    }

    private func addGradient(to view: UIView) {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.5).cgColor,
            UIColor.black.cgColor
        ]
        gradient.locations = [0.0, 0.6, 1.0]
        view.layer.insertSublayer(gradient, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let gradient = gradientView.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = gradientView.bounds
        }
        shimmerView?.frame = bannerImageView.bounds
    }

    // MARK: - Configure

    func configure(with content: Content) {
        titleLabel.text = content.title
        descriptionLabel.text = content.description
        loadImage(from: content.bannerURL)
    }

    // MARK: - Actions

    @IBAction private func ctaButtonTapped(_ sender: UIButton) {
        delegate?.heroBannerCellDidTapCTA(self)
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
        let s = ShimmerView(frame: bannerImageView.bounds)
        bannerImageView.addSubview(s)
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
            bannerImageView.image = cached
            return
        }

        bannerImageView.image = nil
        showShimmer()

        guard let url = URL(string: urlString) else { return }

        imageLoadTask = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, let image = UIImage(data: data) else { return }
                ImageCache.shared.store(image, for: urlString)
                await MainActor.run {
                    guard let self, let iv = self.bannerImageView else { return }
                    self.removeShimmer()
                    UIView.transition(with: iv, duration: 0.3, options: .transitionCrossDissolve) {
                        iv.image = image
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    // Keep shimmer visible; store URL for auto-retry on reconnect
                    self.pendingRetryURL = urlString
                }
            }
        }
    }
}
