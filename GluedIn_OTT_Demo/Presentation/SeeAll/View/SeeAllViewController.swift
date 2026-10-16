//
//  SeeAllViewController.swift
//  GluedIn_OTT_Demo
//
//  Full-screen sheet presented from the bottom. Paginates all items for a rail.
//  On item tap — dismisses itself, then calls onSelectContent so the presenter
//  can push ContentDetailViewController.
//

import UIKit

// MARK: - Associated Keys

private enum AssociatedKeys {
    static var headerView = "headerView"
}

final class SeeAllViewController: UIViewController {

    // MARK: - Callback

    var onSelectContent: ((Content) -> Void)?

    // MARK: - Properties

    private let railTitle: String
    private let allItems: [Content]

    private var displayedItems: [Content] = []
    private var currentPage = 0
    private let pageSize = 10
    private var isLoadingMore = false

    private var collectionView: UICollectionView!

    // MARK: - Init

    init(rail: ContentRail) {
        self.railTitle = rail.title
        self.allItems = rail.items
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupHeader()
        setupCollectionView()
        loadNextPage()
    }

    // MARK: - Header (title + close button)

    private func setupHeader() {
        let header = UIView()
        header.backgroundColor = .black
        header.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = railTitle
        titleLbl.textColor = .white
        titleLbl.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        header.addSubview(titleLbl)
        header.addSubview(closeBtn)
        view.addSubview(header)

        NSLayoutConstraint.activate([
            // Header pinned to safe area top, full width
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 52),

            titleLbl.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            titleLbl.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),

            closeBtn.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            closeBtn.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            closeBtn.widthAnchor.constraint(equalToConstant: 32),
            closeBtn.heightAnchor.constraint(equalToConstant: 32)
        ])

        // Pass header bottom anchor for collection view positioning
        objc_setAssociatedObject(self, &AssociatedKeys.headerView, header, .OBJC_ASSOCIATION_RETAIN)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - Collection View

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 16
        let col: CGFloat = 2
        let totalPad: CGFloat = 16 * (col + 1)
        let itemW = floor((view.bounds.width - totalPad) / col)
        layout.itemSize = CGSize(width: itemW, height: itemW * 1.45)
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            UINib(nibName: ContentCardCell.nibName, bundle: nil),
            forCellWithReuseIdentifier: ContentCardCell.reuseIdentifier
        )
        collectionView.register(
            SeeAllFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: SeeAllFooterView.reuseID
        )
        view.addSubview(collectionView)

        let header = objc_getAssociatedObject(self, &AssociatedKeys.headerView) as? UIView
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: header?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Pagination

    private func loadNextPage() {
        guard !isLoadingMore else { return }
        let start = currentPage * pageSize
        guard start < allItems.count else { return }

        isLoadingMore = true
        let end = min(start + pageSize, allItems.count)
        let newItems = Array(allItems[start..<end])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            let startIndex = self.displayedItems.count
            self.displayedItems.append(contentsOf: newItems)
            self.currentPage += 1
            self.isLoadingMore = false

            let newPaths = (startIndex..<self.displayedItems.count).map {
                IndexPath(item: $0, section: 0)
            }
            self.collectionView.insertItems(at: newPaths)
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private var hasMoreItems: Bool { displayedItems.count < allItems.count }
}

// MARK: - UICollectionViewDataSource

extension SeeAllViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        displayedItems.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ContentCardCell.reuseIdentifier,
            for: indexPath
        ) as? ContentCardCell else { return UICollectionViewCell() }
        cell.configure(with: displayedItems[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter,
           let footer = collectionView.dequeueReusableSupplementaryView(
               ofKind: kind, withReuseIdentifier: SeeAllFooterView.reuseID, for: indexPath
           ) as? SeeAllFooterView {
            hasMoreItems ? footer.startAnimating() : footer.stopAnimating()
            return footer
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension SeeAllViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let content = displayedItems[indexPath.item]
        dismiss(animated: true) { [weak self] in
            self?.onSelectContent?(content)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentH = scrollView.contentSize.height
        let frameH = scrollView.frame.height
        if offsetY > contentH - frameH - 100 {
            loadNextPage()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SeeAllViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        hasMoreItems ? CGSize(width: collectionView.bounds.width, height: 52) : .zero
    }
}

// MARK: - Footer

final class SeeAllFooterView: UICollectionReusableView {

    static let reuseID = "SeeAllFooter"
    private let spinner = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func startAnimating() { spinner.startAnimating() }
    func stopAnimating() { spinner.stopAnimating() }
}
