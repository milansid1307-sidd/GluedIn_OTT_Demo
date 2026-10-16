//
//  PlayerViewController.swift
//  GluedIn_OTT_Demo
//
//  Hosts AVPlayer with custom controls. PlayerEventHandler bridges raw KVO/notifications
//  into typed PlayerEvents — forwarded to PlayerViewModel for state management.
//
//  Event flow: AVPlayer → PlayerEventHandler → PlayerViewModel → AnalyticsEventRepository
//

import UIKit
import AVFoundation
import AVKit

// MARK: - PlayerViewController

final class PlayerViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var playerContainerView: UIView!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var progressSlider: UISlider!
    @IBOutlet private weak var currentTimeLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var controlsView: UIView!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!

    // MARK: - Properties

    var viewModel: PlayerViewModel!

    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var pipController: AVPictureInPictureController?
    private let eventHandler = PlayerEventHandler()
    private var periodicTimeObserver: Any?

    /// Auto-hide controls after inactivity
    private var controlsTimer: Timer?
    /// True when user explicitly tapped pause — suppresses auto-loop on completion
    private var userPaused = false

    private var playerMuteButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupPlayer()
        setupControls()
        bindViewModel()
        startPlayback()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = playerContainerView.bounds
        if playerMuteButton != nil {
            playerMuteButton.frame = CGRect(
                x: 16,
                y: progressSlider.frame.minY - 40,
                width: 28, height: 28
            )
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    override var shouldAutorotate: Bool { true }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
        eventHandler.detach()
        removePeriodicTimeObserver()
    }

    // MARK: - Setup

    private func setupAppearance() {
        view.backgroundColor = .black
        titleLabel.text = viewModel.content.title
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)

        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true

        controlsView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
    }

    private func setupPlayer() {
        guard let url = URL(string: viewModel.content.videoURL) else { return }

        // Activate audio session for background playback and PiP
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)

        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerContainerView.layer.addSublayer(playerLayer)

        eventHandler.delegate = self
        eventHandler.attach(to: player)

        setupPiP()
        addPeriodicTimeObserver()
    }

    private func setupPiP() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.delegate = self
        // Auto-start PiP when user backgrounds the app (iOS 14+)
        if #available(iOS 14.2, *) {
            pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        }
    }

    private func setupControls() {
        playPauseButton.tintColor = .white
        playPauseButton.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        playPauseButton.layer.cornerRadius = 32
        playPauseButton.layer.masksToBounds = true
        playPauseButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        progressSlider.tintColor = UIColor(red: 229/255, green: 9/255, blue: 20/255, alpha: 1)
        progressSlider.thumbTintColor = .white
        progressSlider.value = 0
        progressSlider.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderTouchUp), for: [.touchUpInside, .touchUpOutside])

        currentTimeLabel.textColor = .white
        currentTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        durationLabel.textColor = UIColor(white: 0.7, alpha: 1)
        durationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)

        backButton.setTitle("", for: .normal)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white

        // Tap on player surface toggles controls
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePlayerTap))
        playerContainerView.addGestureRecognizer(tap)

        setupMuteButton()
        updatePlayPauseIcon(isPlaying: false)
        startControlsTimer()
    }

    private func setupMuteButton() {
        playerMuteButton = UIButton(type: .system)
        playerMuteButton.tintColor = .white
        playerMuteButton.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
        playerMuteButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        playerMuteButton.layer.cornerRadius = 14
        playerMuteButton.layer.masksToBounds = true
        playerMuteButton.addTarget(self, action: #selector(playerMuteTapped), for: .touchUpInside)
        // Position above slider on the left — frame set in viewDidLayoutSubviews
        playerMuteButton.frame = CGRect(x: 16, y: progressSlider.frame.minY - 40, width: 28, height: 28)
        controlsView.addSubview(playerMuteButton)
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        viewModel.delegate = self
    }

    // MARK: - Playback

    private func startPlayback() {
        loadingIndicator.startAnimating()
        player.play()
    }

    // MARK: - Periodic Time Observer

    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        periodicTimeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            self?.onTimeUpdate(time: time)
        }
    }

    private func removePeriodicTimeObserver() {
        if let token = periodicTimeObserver {
            player.removeTimeObserver(token)
            periodicTimeObserver = nil
        }
    }

    private func onTimeUpdate(time: CMTime) {
        guard let item = player.currentItem else { return }
        let duration = item.duration
        guard duration.isNumeric, duration.seconds > 0 else { return }

        let current = Float(time.seconds)
        let total = Float(duration.seconds)
        viewModel.updateProgress(current: current, duration: total)
    }

    // MARK: - Controls Auto-Hide

    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }

    private func hideControls() {
        UIView.animate(withDuration: 0.3) {
            self.controlsView.alpha = 0
        }
    }

    private func showControls() {
        UIView.animate(withDuration: 0.3) {
            self.controlsView.alpha = 1
        }
        startControlsTimer()
    }

    // MARK: - UI Update Helpers

    private func updatePlayPauseIcon(isPlaying: Bool) {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    private func formatTime(_ seconds: Float) -> String {
        let s = Int(seconds)
        let minutes = s / 60
        let secs = s % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    // MARK: - IBActions

    @IBAction private func playPauseButtonTapped(_ sender: UIButton) {
        if player.timeControlStatus != .paused {
            player.pause()
            userPaused = true
            updatePlayPauseIcon(isPlaying: false)
        } else {
            player.play()
            userPaused = false
            updatePlayPauseIcon(isPlaying: true)
        }
        showControls()
    }

    @objc private func playerMuteTapped() {
        player.isMuted.toggle()
        let icon = player.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
        playerMuteButton.setImage(UIImage(systemName: icon), for: .normal)
        showControls()
    }

    @IBAction private func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handlePlayerTap() {
        controlsView.alpha < 0.5 ? showControls() : startControlsTimer()
    }

    // MARK: - Slider Actions

    @objc private func sliderTouchDown() {
        // Pause auto-hide while scrubbing
        controlsTimer?.invalidate()
        player.pause()
    }

    @objc private func sliderValueChanged() {
        guard let duration = player.currentItem?.duration, duration.isNumeric else { return }
        let targetTime = Double(progressSlider.value) * duration.seconds
        currentTimeLabel.text = formatTime(Float(targetTime))
    }

    @objc private func sliderTouchUp() {
        guard let duration = player.currentItem?.duration, duration.isNumeric else { return }
        let targetTime = Double(progressSlider.value) * duration.seconds
        let seekTime = CMTime(seconds: targetTime, preferredTimescale: 600)

        player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            self?.player.play()
            self?.eventHandler.didSeek(to: targetTime)
            self?.startControlsTimer()
        }
    }
}

// MARK: - PlayerEventHandlerDelegate

extension PlayerViewController: PlayerEventHandlerDelegate {

    func playerEventHandler(_ handler: PlayerEventHandler, didReceive event: PlayerEvent) {
        // Dispatch all events to ViewModel — VC does not handle events directly.
        Task { @MainActor in
            self.viewModel.handle(event: event)

            // Handle loading indicator visibility
            switch event {
            case .bufferingStarted:
                self.loadingIndicator.startAnimating()
            case .bufferingEnded, .playbackStarted:
                self.loadingIndicator.stopAnimating()
            default:
                break
            }
        }
    }
}

// MARK: - PlayerViewModelDelegate

extension PlayerViewController: PlayerViewModelDelegate {

    func playerViewModel(_ vm: PlayerViewModel, didUpdatePlaybackState isPlaying: Bool) {
        updatePlayPauseIcon(isPlaying: isPlaying)
    }

    func playerViewModel(_ vm: PlayerViewModel, didUpdateProgress progress: Float, duration: Float) {
        guard duration > 0 else { return }
        progressSlider.value = progress / duration
        currentTimeLabel.text = formatTime(progress)
        durationLabel.text = formatTime(duration)
    }

    func playerViewModelDidComplete(_ vm: PlayerViewModel) {
        if userPaused {
            updatePlayPauseIcon(isPlaying: false)
            progressSlider.value = 1.0
            showControls()
        } else {
            // Auto-loop: seek to start and continue playing
            player.seek(to: .zero)
            player.play()
            updatePlayPauseIcon(isPlaying: true)
        }
    }

    func playerViewModel(_ vm: PlayerViewModel, didEncounterError message: String) {
        loadingIndicator.stopAnimating()
        let alert = UIAlertController(title: "Playback Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Go Back", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - AVPictureInPictureControllerDelegate

extension PlayerViewController: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(_ controller: AVPictureInPictureController) {
        // Controls hidden while PiP is active
        controlsView.alpha = 0
        controlsTimer?.invalidate()
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        showControls()
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}

// MARK: - Instantiation

extension PlayerViewController {

    static func instantiate(with content: Content) -> PlayerViewController {
        let vc = PlayerViewController(nibName: "PlayerViewController", bundle: nil)
        let analytics = AnalyticsEventRepository()
        vc.viewModel = PlayerViewModel(content: content, analyticsRepository: analytics)
        return vc
    }
}
