//
//  ContentRailCell.swift
//  GluedIn_OTT_Demo
//
//  UITableViewCell that hosts a horizontal UICollectionView for one content rail.
//  Layout is defined in ContentRailCell.xib.
//

import UIKit

// MARK: - Delegate

protocol ContentRailCellDelegate: AnyObject {
    func contentRailCell(_ cell: ContentRailCell, didSelectContent content: Content)
    func contentRailCellDidTapSeeAll(_ cell: ContentRailCell, rail: ContentRail)
}

// MARK: - ContentRailCell

final class ContentRailCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet private weak var railTitleLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!

    // MARK: - Constants

    static let reuseIdentifier = "ContentRailCell"
    static let nibName = "ContentRailCell"

    // MARK: - Properties

    weak var delegate: ContentRailCellDelegate?

    private var rail: ContentRail?
    private var items: [Content] = []
    private let seeAllButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupSeeAllButton()
        registerCells()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        items = []
        rail = nil
        collectionView.reloadData()
        seeAllButton.isHidden = true
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        railTitleLabel.textColor = .white
        railTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.collectionViewLayout = makeFlowLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    private func setupSeeAllButton() {
        seeAllButton.setTitle("See All  ›", for: .normal)
        seeAllButton.setTitleColor(UIColor(white: 0.65, alpha: 1), for: .normal)
        seeAllButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        seeAllButton.isHidden = true
        seeAllButton.addTarget(self, action: #selector(seeAllTapped), for: .touchUpInside)
        contentView.addSubview(seeAllButton)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let btnW: CGFloat = 80
        let btnH: CGFloat = 28
        let titleY = railTitleLabel.frame.minY
        let titleH = railTitleLabel.frame.height
        seeAllButton.frame = CGRect(
            x: contentView.bounds.width - btnW - 2,
            y: titleY + (titleH - btnH) / 2,
            width: btnW,
            height: btnH
        )
    }

    private func registerCells() {
        let nib = UINib(nibName: ContentCardCell.nibName, bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: ContentCardCell.reuseIdentifier)
    }

    private func makeFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 120, height: 175)
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return layout
    }

    // MARK: - Configure

    func configure(with rail: ContentRail) {
        self.rail = rail
        railTitleLabel.text = rail.title
        items = rail.items
        collectionView.reloadData()
        collectionView.setContentOffset(.zero, animated: false)
        seeAllButton.isHidden = true   // hidden until user scrolls to 6th cell
    }

    private func updateSeeAllVisibility() {
        guard items.count >= 6 else { seeAllButton.isHidden = true; return }
        let visible = collectionView.indexPathsForVisibleItems.contains { $0.item >= 5 }
        seeAllButton.isHidden = !visible
    }

    // MARK: - Actions

    @objc private func seeAllTapped() {
        guard let rail else { return }
        delegate?.contentRailCellDidTapSeeAll(self, rail: rail)
    }
}

// MARK: - UICollectionViewDataSource

extension ContentRailCell: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ContentCardCell.reuseIdentifier,
            for: indexPath
        ) as? ContentCardCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: items[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ContentRailCell: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let content = items[indexPath.item]
        delegate?.contentRailCell(self, didSelectContent: content)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSeeAllVisibility()
    }
}
