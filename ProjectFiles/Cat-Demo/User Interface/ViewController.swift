// Copyright © 2021 Intuit, Inc. All rights reserved.
import UIKit

final class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet private var tableView: UITableView!
    
    // MARK: - Dependencies
    private let viewModel = ViewModel()
    private let loader = PawLoaderView()
    
    // MARK: - Search
    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredBreeds: [CatBreed] = []
    
    private var isSearching: Bool {
        let text = (searchController.searchBar.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return !text.isEmpty
    }
    
    // Single source for table content
    private var dataSource: [CatBreed] {
        isSearching ? filteredBreeds : (viewModel.catBreeds ?? [])
    }
    
    // MARK: - Empty state
    private let emptyStateView = EmptyStateView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavBarTitle()
        setupSearch()
        setupTableView()
        bindViewModel()
        
        loader.show(in: view)
        viewModel.getBreeds()
    }
}

// MARK: - Setup
private extension ViewController {
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 96
        
        tableView.register(CatBreedCell.self, forCellReuseIdentifier: CatBreedCell.reuseId)
    }
    
    func bindViewModel() {
        viewModel.catDataDelegate = self
    }
    
    func setupSearch() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search breeds"
        searchController.searchResultsUpdater = self
        
        definesPresentationContext = true
    }
}

// MARK: - UITableViewDataSource / UITableViewDelegate
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CatBreedCell.reuseId,
            for: indexPath
        ) as! CatBreedCell
        
        let breed = dataSource[indexPath.row]
        
        let id = breed.id ?? ""
        let isFav = (!id.isEmpty) ? FavoritesStore.shared.isFavorite(id: id) : false
        
        cell.configure(
            name: breed.name ?? "Unknown",
            description: breed.description ?? "No description",
            isFavorite: isFav,
            onHeartTap: { [weak tableView] in
                guard let id = breed.id, !id.isEmpty else { return }
                let newValue = FavoritesStore.shared.toggle(id: id)
                (tableView?.cellForRow(at: indexPath) as? CatBreedCell)?.setFavoriteUI(newValue)
            }
        )
        
        cell.setThumbnail(breed: breed)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
                
        let breed = dataSource[indexPath.row]
        let detailVC = CatBreedDetailViewController(breed: breed)
        navigationController?.pushViewController(detailVC, animated: true)
        
        detailVC.setLoading(true)
        
        if let id = breed.id {
            viewModel.getCatImage(breedId: id)
        }
    }
}

// MARK: - CatDataDelegate
extension ViewController: CatDataDelegate {
    
    func errorOccurred(_ message: String) {
        DispatchQueue.main.async {

            if let detailVC = self.navigationController?.topViewController as? CatBreedDetailViewController {

                if message.lowercased().contains("no image available") {
                    detailVC.showNoImageState()
                    return
                }

                detailVC.setLoading(false)
                self.showAlert(
                    message: message,
                    retryHandler: nil
                )
                return
            }

            self.loader.hide(minDuration: 0.2)
            self.showAlert(
                message: message,
                retryHandler: { [weak self] in
                    guard let self else { return }
                    self.loader.show(in: self.view)
                    self.viewModel.getBreeds()
                }
            )
        }
    }
    
    func breedsChangedNotification() {
        DispatchQueue.main.async {
            self.loader.hide(minDuration: 0.35)
            self.tableView.reloadData()
            self.showEmptyState(message: nil)
        }
    }
    
    func imageChangedNotification() {
        DispatchQueue.main.async {
            (self.navigationController?.topViewController as? CatBreedDetailViewController)?
                .updateImage(self.viewModel.catImage)
        }
    }
}

// MARK: - Empty State
private extension ViewController {
    
    func showEmptyState(message: String?) {
        if let message {
            emptyStateView.setMessage(message)
            tableView.backgroundView = emptyStateView
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }
}

// MARK: - Filtering Logic
extension ViewController {
    
    func applyFilter(raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Empty -> reset
        guard !trimmed.isEmpty else {
            filteredBreeds = []
            tableView.reloadData()
            showEmptyState(message: nil)
            return
        }
        
        // Allow only letters + spaces
        let allowed = CharacterSet.letters.union(.whitespaces)
        if trimmed.rangeOfCharacter(from: allowed.inverted) != nil {
            filteredBreeds = []
            tableView.reloadData()
            showEmptyState(message: "Please type letters only.")
            return
        }
        
        let query = trimmed.lowercased()
        let all = viewModel.catBreeds ?? []
        
        // Prefix match
        filteredBreeds = all.filter {
            ($0.name ?? "").lowercased().hasPrefix(query)
        }
        
        tableView.reloadData()
        
        if filteredBreeds.isEmpty {
            showEmptyState(message: "No breeds found for “\(trimmed)”")
        } else {
            showEmptyState(message: nil)
        }
    }
}

