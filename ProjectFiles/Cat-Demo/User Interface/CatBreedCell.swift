//
//  CatBreedCell.swift
//  Cat-Demo
//
//  Created by Atharva Kulkarni on 25/02/26.
//

import UIKit

final class CatBreedCell: UITableViewCell {
    static let reuseId = "CatBreedCell"

    private let thumbImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let heartButton = UIButton(type: .system)

    private var representedImageURL: String?
    
    private var onHeartTap: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .default

        // Left thumbnail
        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = 26
        thumbImageView.backgroundColor = .secondarySystemBackground
        thumbImageView.image = UIImage(systemName: "photo")
        thumbImageView.tintColor = .tertiaryLabel

        NSLayoutConstraint.activate([
            thumbImageView.widthAnchor.constraint(equalToConstant: 52),
            thumbImageView.heightAnchor.constraint(equalToConstant: 52),
        ])

        // Labels
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 1

        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 3

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        // Heart
        heartButton.translatesAutoresizingMaskIntoConstraints = false
        heartButton.tintColor = .systemPink
        NSLayoutConstraint.activate([
            heartButton.widthAnchor.constraint(equalToConstant: 34),
            heartButton.heightAnchor.constraint(equalToConstant: 34),
        ])
        heartButton.addTarget(self, action: #selector(heartTapped), for: .touchUpInside)

        // Layout row
        let row = UIStackView(arrangedSubviews: [thumbImageView, textStack, heartButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])

        // Prevent text squeeze
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        heartButton.setContentHuggingPriority(.required, for: .horizontal)
        thumbImageView.setContentHuggingPriority(.required, for: .horizontal)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        representedImageURL = nil
        onHeartTap = nil
        heartButton.transform = .identity
        thumbImageView.image = UIImage(systemName: "photo")
        thumbImageView.tintColor = .tertiaryLabel
    }

    func configure(
        name: String,
        description: String,
        isFavorite: Bool,
        onHeartTap: @escaping () -> Void
    ) {
        titleLabel.text = name
        subtitleLabel.text = description
        self.onHeartTap = onHeartTap
        setFavoriteUI(isFavorite)
    }

    func setThumbnail(breed: CatBreed) {

        representedImageURL = nil
        thumbImageView.image = UIImage(systemName: "photo")
        thumbImageView.tintColor = .tertiaryLabel

        Task { [weak self] in
            guard let self else { return }

            do {
                var finalURL: String?

                if let direct = breed.image?.url {
                    finalURL = direct
                } else if let refId = breed.reference_image_id {
                    finalURL = try await Network.fetchImageURL(referenceImageId: refId)
                }

                guard let finalURL else { return }

                self.representedImageURL = finalURL
                let image = try await Network.fetchImage(from: finalURL)

                if self.representedImageURL == finalURL {
                    await MainActor.run {
                        self.thumbImageView.image = image
                        self.thumbImageView.tintColor = nil
                    }
                }

            } catch {
                // keep placeholder
            }
        }
    }
    
    func setFavoriteUI(_ isFavorite: Bool) {
        let symbol = isFavorite ? "pawprint.fill" : "pawprint"
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        heartButton.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
        heartButton.accessibilityLabel = isFavorite ? "Unfavorite" : "Favorite"
    }

    @objc private func heartTapped() {
        // small tap animation
        UIView.animate(withDuration: 0.12, animations: {
            self.heartButton.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }, completion: { _ in
            UIView.animate(withDuration: 0.12) {
                self.heartButton.transform = .identity
            }
        })
        onHeartTap?()
    }
}
