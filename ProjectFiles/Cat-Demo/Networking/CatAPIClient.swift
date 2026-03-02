//
//  CatAPIClient.swift
//  Cat-Demo
//
//  Created by Atharva Kulkarni on 25/02/26.
//

import UIKit

protocol CatAPIClient {
    func fetchBreeds(completion: @escaping (Result<[CatBreed], Error>) -> Void)
    func fetchCatImage(breedId: String, completion: @escaping (Result<UIImage, Error>) -> Void)
}



