//
//  NetworkClient.swift
//  Cat-Demo
//
//  Created by Atharva Kulkarni on 25/02/26.
//

import UIKit

final class NetworkClient: CatAPIClient {
    func fetchBreeds(completion: @escaping (Result<[CatBreed], Error>) -> Void) {
        Network.fetchCatBreeds(completion: completion)
    }

    func fetchCatImage(breedId: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        Network.fetchCatImage(breedId: breedId, completion: completion)
    }
}
