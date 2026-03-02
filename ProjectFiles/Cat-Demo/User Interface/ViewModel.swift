// Copyright © 2021 Intuit, Inc. All rights reserved.
import Foundation
import UIKit

/// Basic Delegate interface to send messages
protocol CatDataDelegate {
    func breedsChangedNotification()
    func imageChangedNotification()
    func errorOccurred(_ message: String)
}

/// View model
final class ViewModel {
    
    var catDataDelegate: CatDataDelegate?

    private let api: CatAPIClient
    
    init(api: CatAPIClient = NetworkClient()) {
        self.api = api
    }

    var catBreeds: [CatBreed]? {
        didSet { catDataDelegate?.breedsChangedNotification() }
    }

    var catImage: UIImage? {
        didSet { catDataDelegate?.imageChangedNotification() }
    }

    func getBreeds() {
        api.fetchBreeds { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let breeds):
                self.catBreeds = breeds
            case .failure(let error):
                self.catDataDelegate?.errorOccurred(error.localizedDescription)
                print(error)
                self.catBreeds = []
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
                print(error)
            }
        }
    }

}
