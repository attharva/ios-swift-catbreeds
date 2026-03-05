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
    
    // MARK: - Empty state
    private let emptyStateView = EmptyStateView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavBarTitle()
        setupSearch()
        setupTableView()
        bindViewModel()
        
        loader.show(in: view)
        viewModel.onViewDidLoad()
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
        viewModel.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: CatBreedCell.reuseId,
            for: indexPath
        ) as! CatBreedCell

        let breed = viewModel.breed(at: indexPath.row)

        let id = breed.id ?? ""
        let isFav = (!id.isEmpty) ? viewModel.isFavorite(breedId: id) : false

        cell.configure(
            name: breed.name ?? "Unknown",
            description: breed.description ?? "No description",
            isFavorite: isFav,
            onHeartTap: { [weak self, weak tableView] in
                guard let self else { return }
                guard let id = breed.id, !id.isEmpty else { return }
                let newValue = self.viewModel.toggleFavorite(breedId: id)
                (tableView?.cellForRow(at: indexPath) as? CatBreedCell)?.setFavoriteUI(newValue)
            }
        )
        
        cell.setThumbnail(breed: breed)
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.onWillDisplayRow(indexPath.row)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let breed = viewModel.breed(at: indexPath.row)
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
                self.showAlert(message: message, retryHandler: nil)
                return
            }

            self.loader.hide(minDuration: 0.2)
            
            self.showAlert(
                message: message,
                retryHandler: { [weak self] in
                    guard let self else { return }
                    self.loader.show(in: self.view)
                    self.viewModel.onRetry()
                }
            )
        }
    }

    func breedsChangedNotification() {
        DispatchQueue.main.async {
            self.loader.hide(minDuration: 0.35)
            self.tableView.reloadData()
            self.showEmptyState(message: self.viewModel.emptyMessage)
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

// MARK: - UISearchResultsUpdating
extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.onSearchTextChanged(searchController.searchBar.text ?? "")
    }
}


