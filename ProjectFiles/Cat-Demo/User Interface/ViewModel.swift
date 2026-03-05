// Copyright © 2021 Intuit, Inc. All rights reserved.
import Foundation
import UIKit

protocol CatDataDelegate: AnyObject {
    func breedsChangedNotification()
    func imageChangedNotification()
    func errorOccurred(_ message: String)
}

final class ViewModel {

    weak var catDataDelegate: CatDataDelegate?

    private let api: CatAPIClient
    private let favorites: FavoritesStore

    init(api: CatAPIClient = NetworkClient(),
         favorites: FavoritesStore = .shared) {
        self.api = api
        self.favorites = favorites
    }

    // MARK: - Source of truth
    private var allBreeds: [CatBreed] = [] {
        didSet { rebuildVisibleBreedsAndNotify() }
    }

    private(set) var visibleBreeds: [CatBreed] = [] {
        didSet { catDataDelegate?.breedsChangedNotification() }
    }

    // MARK: - Detail image
    var catImage: UIImage? {
        didSet { catDataDelegate?.imageChangedNotification() }
    }

    // MARK: - Search state
    private var searchText: String = ""
    private(set) var emptyMessage: String? = nil

    // MARK: - Pagination state
    private var page = 0
    private let limit = 10
    private var isLoading = false
    private var hasMore = true

    // MARK: - Public helpers for VC
    var numberOfRows: Int { visibleBreeds.count }

    func breed(at index: Int) -> CatBreed {
        visibleBreeds[index]
    }

    func isFavorite(breedId: String) -> Bool {
        favorites.isFavorite(id: breedId)
    }

    @discardableResult
    func toggleFavorite(breedId: String) -> Bool {
        let newValue = favorites.toggle(id: breedId)
        // update the current list UI (only favorite icon changes)
        catDataDelegate?.breedsChangedNotification()
        return newValue
    }

    // MARK: - Inputs from VC
    func onViewDidLoad() {
        resetAndLoadFirstPage()
    }

    func onRetry() {
        resetAndLoadFirstPage()
    }

    func onSearchTextChanged(_ raw: String) {
        searchText = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        rebuildVisibleBreedsAndNotify()
    }

    /// Call from willDisplay(indexPath)
    func onWillDisplayRow(_ row: Int) {
        guard searchText.isEmpty else { return } // no pagination while searching

        // when user is within last N items, fetch next page
        let threshold = 8
        let lastIndex = max(0, visibleBreeds.count - 1)

        if row >= max(0, lastIndex - threshold) {
            loadNextPageIfNeeded()
        }
    }

    // MARK: - Networking
    private func resetAndLoadFirstPage() {
        page = 0
        hasMore = true
        isLoading = false
        allBreeds = []
        loadNextPageIfNeeded()
    }

    private func loadNextPageIfNeeded() {
        guard !isLoading, hasMore else { return }
        isLoading = true

        print("Loading page \(page), current count: \(allBreeds.count)")

        api.fetchBreeds(page: page, limit: limit) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let breeds):
                if breeds.isEmpty {
                    self.hasMore = false
                    return
                }
                self.page += 1
                self.allBreeds.append(contentsOf: breeds)

            case .failure(let error):
                self.catDataDelegate?.errorOccurred(error.localizedDescription)
            }
        }
    }

    func getCatImage(breedId: String) {
        api.fetchCatImage(breedId: breedId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let image):
                self.catImage = image
            case .failure(let error):
                self.catDataDelegate?.errorOccurred(error.localizedDescription)
            }
        }
    }

    // MARK: - Filtering + Empty state rules
    private func rebuildVisibleBreedsAndNotify() {
        // If user typed something:
        if !searchText.isEmpty {
            // Allow only letters + spaces
            let allowed = CharacterSet.letters.union(.whitespaces)
            if searchText.rangeOfCharacter(from: allowed.inverted) != nil {
                visibleBreeds = []
                emptyMessage = "Please type letters only."
                return
            }

            let q = searchText.lowercased()
            visibleBreeds = allBreeds.filter { ($0.name ?? "").lowercased().hasPrefix(q) }

            emptyMessage = visibleBreeds.isEmpty ? "No breeds found for “\(searchText)”" : nil
            return
        }

        // No search => show full list
        visibleBreeds = allBreeds
        emptyMessage = visibleBreeds.isEmpty ? "No breeds available." : nil
    }
}
