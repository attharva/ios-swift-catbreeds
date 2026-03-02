//
//  CatBreedDetailViewController.swift
//  Cat-Demo
//
//  Created by Atharva Kulkarni on 25/02/26.
//

import UIKit

final class CatBreedDetailViewController: UIViewController {
    
    private let breed: CatBreed
    private let loader = PawLoaderView()
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let noImageLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    private let statsCard = UIView()
    private let statsStack = UIStackView()
    
    private let wikiButton = UIButton(type: .system)
    
    init(breed: CatBreed) {
        self.breed = breed
        super.init(nibName: nil, bundle: nil)
        self.title = breed.name ?? "Breed"
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        populate()
        
        loader.show(in: view)
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        stackView.axis = .vertical
        stackView.spacing = 14
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 18
        
        scrollView.addSubview(stackView)
        
        // Main image
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 16
        
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.15
        imageView.layer.shadowRadius = 8
        imageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        imageView.layer.masksToBounds = false
        
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .tertiaryLabel
        
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9.0/16.0).isActive = true
        
        // No Image
        noImageLabel.translatesAutoresizingMaskIntoConstraints = false
        noImageLabel.text = "No image available"
        noImageLabel.textAlignment = .center
        noImageLabel.textColor = .secondaryLabel
        noImageLabel.font = .preferredFont(forTextStyle: .body)
        noImageLabel.isHidden = true
        
        imageView.addSubview(noImageLabel)
        NSLayoutConstraint.activate([
            noImageLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            noImageLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            noImageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: imageView.leadingAnchor, constant: 12),
            noImageLabel.trailingAnchor.constraint(lessThanOrEqualTo: imageView.trailingAnchor, constant: -12)
        ])
        
        // Title
        nameLabel.font = .preferredFont(forTextStyle: .largeTitle)
        nameLabel.numberOfLines = 0
        
        // Subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        
        // Description
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.numberOfLines = 0
        
        // Stats card
        statsCard.translatesAutoresizingMaskIntoConstraints = false
        statsCard.backgroundColor = .secondarySystemBackground
        statsCard.layer.cornerRadius = 16
        
        statsStack.axis = .vertical
        statsStack.spacing = 10
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        statsCard.addSubview(statsStack)
        
        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 14),
            statsStack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 14),
            statsStack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -14),
            statsStack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -14),
        ])
        
        // Wiki button
        wikiButton.setTitle("Open Wikipedia", for: .normal)
        wikiButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        wikiButton.addTarget(self, action: #selector(openWiki), for: .touchUpInside)
        
        [imageView, nameLabel, subtitleLabel, descriptionLabel, statsCard, wikiButton].forEach {
            stackView.addArrangedSubview($0)
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])
    }
    
}

// MARK: - Extras
extension CatBreedDetailViewController {
    
    private func populate() {
        nameLabel.text = breed.name ?? "Unknown"
        descriptionLabel.text = breed.description ?? "No description available."
        
        let temperament = (breed.temperament ?? "—")
        let life = (breed.life_span ?? "—")
        
        subtitleLabel.text = "Temperament: \(temperament)\nLife span: \(life) years"
        
        // Build stats
        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        addStatRow(title: "Intelligence", value: breed.intelligence)
        addStatRow(title: "Energy", value: breed.energy_level)
        addStatRow(title: "Affection", value: breed.affection_level)
        addStatRow(title: "Grooming", value: breed.grooming)
        addStatRow(title: "Child Friendly", value: breed.child_friendly)
        addStatRow(title: "Dog Friendly", value: breed.dog_friendly)
        
        wikiButton.isHidden = (breed.wikipedia_url ?? "").isEmpty
    }
    
    private func addStatRow(title: String, value: Int?) {
        guard let value else { return }
        
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .equalSpacing
        
        let left = UILabel()
        left.font = .preferredFont(forTextStyle: .subheadline)
        left.text = title
        
        let right = UILabel()
        right.font = .preferredFont(forTextStyle: .subheadline)
        right.textColor = .secondaryLabel
        right.text = stars(value)
        
        row.addArrangedSubview(left)
        row.addArrangedSubview(right)
        
        statsStack.addArrangedSubview(row)
    }
    
    private func stars(_ value: Int) -> String {
        let clamped = max(0, min(5, value))
        return String(repeating: "★", count: clamped) + String(repeating: "☆", count: 5 - clamped)
    }
    
    func updateImage(_ image: UIImage?) {
        loader.hide(minDuration: 0.2)

        if let image {
            noImageLabel.isHidden = true
            imageView.image = image
            imageView.tintColor = nil
        } else {
            showNoImageState()
        }
    }
    @objc private func openWiki() {
        guard let urlString = breed.wikipedia_url,
              let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
}

// MARK: - Helper
extension CatBreedDetailViewController {
    func setLoading(_ loading: Bool) {
        if loading {
            loader.show(in: view)
            noImageLabel.isHidden = true
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .tertiaryLabel
        } else {
            loader.hide(minDuration: 0.2)
        }
    }
    
    func showNoImageState() {
        loader.hide(minDuration: 0.2)
        noImageLabel.isHidden = false
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .tertiaryLabel
    }
}
