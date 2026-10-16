//
//  ContentDetailViewController.swift
//  GluedIn_OTT_Demo
//
//  Displays full content detail — banner, metadata, genre tags, play/download/list CTAs,
//  cast, and about section. Extra views are added programmatically below the XIB layout.
//

import UIKit
import AVFoundation

// MARK: - ContentDetailViewController

final class ContentDetailViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var bannerImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var backButton: UIButton!

    // MARK: - Properties

    var viewModel: ContentDetailViewModel!

    private var imageLoadTask: Task<Void, Never>?
    private var shimmerView: ShimmerView?
    private var pendingRetryURL: String?
    /// Stored during viewDidLoad, built once layout bounds are known in viewDidLayoutSubviews.
    private var pendingDetailContent: Content?

    // Preview player
    private var previewPlayer: AVPlayer?
    private var previewPlayerLayer: AVPlayerLayer?
    private var muteButton: UIButton?
    private var previewStartWorkItem: DispatchWorkItem?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupPlayButton()
        setupBackButton()
        bindViewModel()
        addGradient()
        observeNetwork()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        // Restart preview each time screen appears (e.g. returning from player)
        if previewPlayer == nil, let url = viewModel.content?.videoURL {
            startPreview(videoURL: url)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPreview()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = gradientView.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = gradientView.bounds
        }
        previewPlayerLayer?.frame = bannerImageView.bounds

        // Build dynamic content once the scrollView has correct bounds
        if let content = pendingDetailContent {
            pendingDetailContent = nil
            compactStaticLabels()
            buildDynamicContent(for: content)
        }
    }

    /// Resizes title label to fit actual text, then shifts play button and
    /// description label up so spacing is visually consistent (~16pt gaps).
    private func compactStaticLabels() {
        let w = scrollView.bounds.width - 32

        // Title: shrink to actual text height, min 1 line
        let fittedTitleH = titleLabel.sizeThatFits(CGSize(width: w, height: 120)).height
        let clampedTitleH = min(fittedTitleH, 120)
        titleLabel.frame.size.height = clampedTitleH

        let gap: CGFloat = 16

        // Play button: 16pt below title text bottom
        playButton.frame.origin.y = titleLabel.frame.maxY + gap

        // Description: 16pt below play button
        descriptionLabel.frame.origin.y = playButton.frame.maxY + gap
    }

    // MARK: - Setup

    private func setupAppearance() {
        view.backgroundColor = .black
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never   // banner fills under status bar

        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true

        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.numberOfLines = 2

        descriptionLabel.textColor = UIColor(white: 0.8, alpha: 1)
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.numberOfLines = 6
    }

    private func setupPlayButton() {
        playButton.backgroundColor = UIColor(red: 229/255, green: 9/255, blue: 20/255, alpha: 1)
        playButton.setTitle("▶  Play", for: .normal)
        playButton.setTitleColor(.white, for: .normal)
        playButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        playButton.layer.cornerRadius = 6
    }

    private func setupBackButton() {
        backButton.setTitle("", for: .normal)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        // Push button below status bar when scrollView goes edge-to-edge
        let topInset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.safeAreaInsets.top ?? 44
        backButton.frame.origin.y = topInset + 4
    }

    private func observeNetwork() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(retryPendingImage),
            name: .networkDidReconnect, object: nil
        )
    }

    @objc private func retryPendingImage() {
        guard let url = pendingRetryURL else { return }
        pendingRetryURL = nil
        loadBannerImage(from: url)
    }

    // MARK: - Preview Player

    private func startPreview(videoURL: String) {
        guard let url = URL(string: videoURL) else { return }

        previewStartWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.setupPreviewPlayer(url: url)
        }
        previewStartWorkItem = work
        // Start after 1.5s so banner image loads first
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    private func setupPreviewPlayer(url: URL) {
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.play()

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bannerImageView.bounds
        bannerImageView.layer.addSublayer(layer)

        previewPlayer = player
        previewPlayerLayer = layer

        // Loop preview
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(previewDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )

        addMuteButton()

        // Reveal mute button only when video actually starts playing
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.new], context: nil)
    }

    @objc private func previewDidEnd() {
        previewPlayer?.seek(to: .zero)
        previewPlayer?.play()
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard keyPath == "timeControlStatus",
              let player = object as? AVPlayer,
              player === previewPlayer else { return }
        DispatchQueue.main.async { [weak self] in
            if player.timeControlStatus == .playing {
                self?.muteButton?.isHidden = false
            }
        }
    }

    private func stopPreview() {
        previewStartWorkItem?.cancel()
        previewPlayer?.removeObserver(self, forKeyPath: "timeControlStatus")
        previewPlayer?.pause()
        previewPlayerLayer?.removeFromSuperlayer()
        previewPlayer = nil
        previewPlayerLayer = nil
        muteButton?.removeFromSuperview()
        muteButton = nil
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    private func addMuteButton() {
        let btn = UIButton(type: .system)
        btn.tintColor = .white
        btn.setImage(UIImage(systemName: "speaker.slash.fill"), for: .normal)
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = true
        btn.isHidden = true   // hidden until player actually starts
        btn.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)

        // bannerImageView.frame gives correct position in scrollView coordinates
        let size: CGFloat = 32
        let margin: CGFloat = 12
        let bf = bannerImageView.frame
        btn.frame = CGRect(
            x: bf.maxX - size - margin,
            y: bf.maxY - size - margin,
            width: size,
            height: size
        )
        scrollView.addSubview(btn)
        muteButton = btn
    }

    @objc private func toggleMute() {
        guard let player = previewPlayer else { return }
        player.isMuted.toggle()
        let iconName = player.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
        muteButton?.setImage(UIImage(systemName: iconName), for: .normal)
    }

    private func addGradient() {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 1.0]
        gradientView.layer.insertSublayer(gradient, at: 0)
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state: state)
        }
        render(state: viewModel.state)
    }

    private func render(state: ViewState<Content>) {
        switch state {
        case .idle, .loading, .empty:
            break
        case .success(let content):
            populate(with: content)
        case .error(let message):
            showError(message)
        }
    }

    private func populate(with content: Content) {
        titleLabel.text = content.title
        descriptionLabel.text = content.description
        loadBannerImage(from: content.bannerURL)
        startPreview(videoURL: content.videoURL)
        // Defer dynamic content until layout pass provides correct scrollView bounds
        pendingDetailContent = content
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Actions

    @IBAction private func playButtonTapped(_ sender: UIButton) {
        guard let content = viewModel.content else { return }
        let playerVC = PlayerViewController.instantiate(with: content)
        navigationController?.pushViewController(playerVC, animated: true)
    }

    @IBAction private func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @objc private func downloadTapped() {
        showToast("Downloads coming soon. Stay tuned!")
    }

    @objc private func myListTapped() {
        showToast("My List feature is on its way!")
    }

    private func showToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textColor = .white
        toast.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        toast.textAlignment = .center
        toast.backgroundColor = UIColor(white: 0.15, alpha: 0.95)
        toast.layer.cornerRadius = 20
        toast.clipsToBounds = true
        toast.numberOfLines = 0
        toast.alpha = 0

        let padding: CGFloat = 16
        let maxW = view.bounds.width - 48
        let textH = toast.sizeThatFits(CGSize(width: maxW - padding * 2, height: 200)).height
        let toastH = textH + padding * 2
        toast.frame = CGRect(
            x: 24,
            y: view.bounds.height - toastH - view.safeAreaInsets.bottom - 24,
            width: maxW,
            height: toastH
        )
        view.addSubview(toast)

        UIView.animate(withDuration: 0.3) { toast.alpha = 1 } completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 2.0) { toast.alpha = 0 } completion: { _ in
                toast.removeFromSuperview()
            }
        }
    }

    // MARK: - Image Loading

    private func loadBannerImage(from urlString: String) {
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
                    self?.pendingRetryURL = urlString
                    // Shimmer stays — will retry when network reconnects
                }
            }
        }
    }

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
}

// MARK: - Dynamic Detail Content

extension ContentDetailViewController {

    private func buildDynamicContent(for content: Content) {
        // Remove previously added dynamic views
        scrollView.subviews.filter { $0.tag == 9001 }.forEach { $0.removeFromSuperview() }

        // Data comes from ViewModel — VC does not compute presentation metadata.
        guard let data = viewModel.presentationData else { return }
        let w = max(scrollView.bounds.width, 393)

        // Resize description label to its actual content height (capped at 6 lines)
        let maxDescHeight = ceil(descriptionLabel.font.lineHeight * 6 + 4)
        let fittedHeight = descriptionLabel.sizeThatFits(
            CGSize(width: w - 32, height: maxDescHeight)
        ).height
        descriptionLabel.frame.size.height = min(fittedHeight, maxDescHeight)

        // Start dynamic content immediately after description + small padding
        var y = descriptionLabel.frame.maxY + 20

        func add(_ view: UIView) {
            view.tag = 9001
            scrollView.addSubview(view)
        }

        // Star rating row
        let starScore = starRating(for: data.rating)
        let ratingLabel = UILabel(frame: CGRect(x: 16, y: y, width: w - 32, height: 22))
        ratingLabel.text = "\(starScore.stars)  \(starScore.score) · \(data.rating)"
        ratingLabel.textColor = UIColor(red: 1, green: 0.82, blue: 0.2, alpha: 1)   // gold
        ratingLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        add(ratingLabel)
        y += 32

        // Metadata row: Year · Duration · Quality
        let metaLabel = UILabel(frame: CGRect(x: 16, y: y, width: w - 32, height: 20))
        metaLabel.text = "\(data.year)  ·  \(data.seasons)  ·  \(data.quality)"
        metaLabel.textColor = UIColor(white: 0.6, alpha: 1)
        metaLabel.font = UIFont.systemFont(ofSize: 13)
        add(metaLabel)
        y += 36

        // Genre pills
        var xOff: CGFloat = 16
        for genre in data.genres {
            let pill = UILabel()
            pill.text = genre
            pill.textColor = .white
            pill.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            pill.textAlignment = .center
            let pillW = genre.size(withAttributes: [.font: pill.font!]).width + 24
            pill.frame = CGRect(x: xOff, y: y, width: pillW, height: 26)
            pill.backgroundColor = UIColor(white: 0.22, alpha: 1)
            pill.layer.cornerRadius = 13
            pill.clipsToBounds = true
            add(pill)
            xOff += pillW + 8
        }
        y += 44

        // Action buttons: Download + My List
        let dlBtn = makeActionButton("⬇  Download", frame: CGRect(x: 16, y: y, width: 155, height: 40))
        dlBtn.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)
        add(dlBtn)
        let listBtn = makeActionButton("+  My List", frame: CGRect(x: 179, y: y, width: 155, height: 40))
        listBtn.addTarget(self, action: #selector(myListTapped), for: .touchUpInside)
        add(listBtn)
        y += 60

        // Thin divider
        let divider = UIView(frame: CGRect(x: 16, y: y, width: w - 32, height: 0.5))
        divider.backgroundColor = UIColor(white: 0.25, alpha: 1)
        add(divider)
        y += 20

        // Cast & Crew section
        add(sectionHeader("Cast & Crew", y: y))
        y += 30

        let castLabel = UILabel(frame: CGRect(x: 16, y: y, width: w - 32, height: 36))
        castLabel.text = data.cast
        castLabel.textColor = UIColor(white: 0.7, alpha: 1)
        castLabel.font = UIFont.systemFont(ofSize: 13)
        castLabel.numberOfLines = 2
        add(castLabel)
        y += 50

        // About section
        add(sectionHeader("About \(content.title)", y: y))
        y += 30

        let creatorLabel = UILabel(frame: CGRect(x: 16, y: y, width: w - 32, height: 20))
        creatorLabel.text = "Creator: \(data.creator)"
        creatorLabel.textColor = UIColor(white: 0.55, alpha: 1)
        creatorLabel.font = UIFont.systemFont(ofSize: 13)
        add(creatorLabel)
        y += 24

        let genreLineLabel = UILabel(frame: CGRect(x: 16, y: y, width: w - 32, height: 20))
        genreLineLabel.text = "Genres: \(data.genres.joined(separator: ", "))"
        genreLineLabel.textColor = UIColor(white: 0.55, alpha: 1)
        genreLineLabel.font = UIFont.systemFont(ofSize: 13)
        add(genreLineLabel)
        y += 24

        let adjectivesLabel = UILabel(frame: CGRect(x: 16, y: y, width: w - 32, height: 20))
        adjectivesLabel.text = "This show is: \(data.adjectives.joined(separator: ", "))"
        adjectivesLabel.textColor = UIColor(white: 0.55, alpha: 1)
        adjectivesLabel.font = UIFont.systemFont(ofSize: 13)
        add(adjectivesLabel)
        y += 40

        scrollView.contentSize = CGSize(width: w, height: y + 20)
    }

    private func starRating(for rating: String) -> (stars: String, score: String) {
        switch rating {
        case "TV-MA": return ("★★★★★", "9.2/10")
        case "TV-14": return ("★★★★☆", "8.5/10")
        case "TV-PG": return ("★★★☆☆", "7.8/10")
        default:      return ("★★★★☆", "8.1/10")
        }
    }

    private func makeActionButton(_ title: String, frame: CGRect) -> UIButton {
        let btn = UIButton(type: .system)
        btn.frame = frame
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        btn.backgroundColor = UIColor(white: 0.2, alpha: 1)
        btn.layer.cornerRadius = 6
        return btn
    }

    private func sectionHeader(_ text: String, y: CGFloat) -> UILabel {
        let label = UILabel(frame: CGRect(x: 16, y: y, width: 340, height: 24))
        label.text = text
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        return label
    }
}

// MARK: - Instantiation

extension ContentDetailViewController {

    /// Creates a detail VC with a pre-loaded content model — no additional fetch needed.
    static func instantiate(with content: Content) -> ContentDetailViewController {
        let vc = ContentDetailViewController(nibName: "ContentDetailViewController", bundle: nil)
        let dataSource = MockContentDataSource()
        let repository = ContentRepositoryImpl(dataSource: dataSource)
        let useCase = GetContentDetailUseCase(repository: repository)
        let vm = ContentDetailViewModel(useCase: useCase)
        vm.setContent(content)
        vc.viewModel = vm
        return vc
    }
}
