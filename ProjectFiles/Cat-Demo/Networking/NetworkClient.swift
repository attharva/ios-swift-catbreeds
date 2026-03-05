//
//  NetworkClient.swift
//  Cat-Demo
//
//  Created by Atharva Kulkarni on 25/02/26.
//

import UIKit

final class NetworkClient: CatAPIClient {
    func fetchBreeds(page: Int, limit: Int, completion: @escaping (Result<[CatBreed], any Error>) -> Void) {
        Network.fetchCatBreeds(page: page, limit: limit, completion: completion)
    }
    
    func fetchCatImage(breedId: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        Network.fetchCatImage(breedId: breedId, completion: completion)
    }
}
