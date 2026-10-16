//
//  HomeViewController.swift
//  GluedIn_OTT_Demo
//
//  Root screen — hero banner + horizontal content rails.
//  Observes HomeViewModel state and delegates navigation to the coordinator pattern.
//

import UIKit

// MARK: - HomeViewController

/// Entry point for the OTT home experience. Manages a UITableView with a hero header row
/// and one row per content rail. Navigation is push-based via UINavigationController.
final class HomeViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Properties

    var viewModel: HomeViewModel!

    // Loading / error overlay views
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorView = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupTableView()
        setupOverlays()
        bindViewModel()
        viewModel.loadContent()
    }

    // MARK: - Setup

    private func setupAppearance() {
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupTableView() {
        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .never   // hero fills under status bar
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        registerCells()
    }

    private func registerCells() {
        tableView.register(
            UINib(nibName: HeroBannerCell.nibName, bundle: nil),
            forCellReuseIdentifier: HeroBannerCell.reuseIdentifier
        )
        tableView.register(
            UINib(nibName: ContentRailCell.nibName, bundle: nil),
            forCellReuseIdentifier: ContentRailCell.reuseIdentifier
        )
    }

    private func setupOverlays() {
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        errorView.textColor = UIColor(white: 0.7, alpha: 1)
        errorView.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        errorView.textAlignment = .center
        errorView.numberOfLines = 0
        errorView.isHidden = true
        errorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorView)
        NSLayoutConstraint.activate([
            errorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state: state)
        }

        viewModel.onRailsAppended = { [weak self] newCount in
            guard let self else { return }
            let totalRails = self.viewModel.rails.count
            let startRow = totalRails - newCount + 1  // +1 because row 0 is hero
            let newIndexPaths = (0..<newCount).map {
                IndexPath(row: startRow + $0, section: 0)
            }
            self.tableView.insertRows(at: newIndexPaths, with: .automatic)
        }
    }

    private func render(state: ViewState<HomeContent>) {
        switch state {
        case .idle:
            break

        case .loading:
            tableView.isHidden = true
            errorView.isHidden = true
            loadingIndicator.startAnimating()

        case .success:
            loadingIndicator.stopAnimating()
            errorView.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()

        case .empty:
            loadingIndicator.stopAnimating()
            tableView.isHidden = true
            errorView.isHidden = false
            errorView.text = "No content available."

        case .error(let message):
            loadingIndicator.stopAnimating()
            tableView.isHidden = true
            errorView.isHidden = false
            errorView.text = "Something went wrong.\n\(message)"
        }
    }

    // MARK: - Navigation

    private func navigateToDetail(content: Content) {
        let detailVC = ContentDetailViewController.instantiate(with: content)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension HomeViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let railCount = viewModel.rails.count
        return railCount > 0 ? 1 + railCount : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return makeHeroBannerCell(for: indexPath)
        } else {
            return makeContentRailCell(for: indexPath)
        }
    }

    // MARK: Cell Factories

    private func makeHeroBannerCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: HeroBannerCell.reuseIdentifier, for: indexPath
        ) as? HeroBannerCell,
              let hero = viewModel.heroBanner else {
            return UITableViewCell()
        }
        cell.configure(with: hero)
        cell.delegate = self
        return cell
    }

    private func makeContentRailCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ContentRailCell.reuseIdentifier, for: indexPath
        ) as? ContentRailCell else {
            return UITableViewCell()
        }
        let railIndex = indexPath.row - 1
        cell.configure(with: viewModel.rails[railIndex])
        cell.delegate = self
        return cell
    }
}

// MARK: - UITableViewDelegate

extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? view.bounds.height * 0.55 : 230
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Trigger next page when user is 1 rail away from the end
        let lastRailRow = viewModel.rails.count  // row 0 = hero, row N = rail N-1
        guard lastRailRow > 0, indexPath.row >= lastRailRow else { return }
        viewModel.loadNextPage()
    }
}

// MARK: - HeroBannerCellDelegate

extension HomeViewController: HeroBannerCellDelegate {

    func heroBannerCellDidTapCTA(_ cell: HeroBannerCell) {
        guard let hero = viewModel.heroBanner else { return }
        navigateToDetail(content: hero)
    }
}

// MARK: - ContentRailCellDelegate

extension HomeViewController: ContentRailCellDelegate {

    func contentRailCell(_ cell: ContentRailCell, didSelectContent content: Content) {
        navigateToDetail(content: content)
    }

    func contentRailCellDidTapSeeAll(_ cell: ContentRailCell, rail: ContentRail) {
        let seeAllVC = SeeAllViewController(rail: rail)
        seeAllVC.onSelectContent = { [weak self] content in
            self?.navigateToDetail(content: content)
        }
        present(seeAllVC, animated: true)
    }
}

// MARK: - Instantiation

extension HomeViewController {

    /// Creates HomeViewController from its XIB and injects a fully-wired ViewModel.
    static func instantiate() -> HomeViewController {
        let vc = HomeViewController(nibName: "HomeViewController", bundle: nil)
        let dataSource = MockContentDataSource()
        let repository = ContentRepositoryImpl(dataSource: dataSource)
        let homeUseCase = GetHomeContentUseCase(repository: repository)
        let moreRailsUseCase = GetMoreRailsUseCase(repository: repository)
        vc.viewModel = HomeViewModel(useCase: homeUseCase, moreRailsUseCase: moreRailsUseCase)
        return vc
    }
}
