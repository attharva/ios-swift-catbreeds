//
//  ViewModelTests.swift
//  Cat-DemoTests
//
//  Created by Atharva Kulkarni on 25/02/26.
//

import XCTest
@testable import Cat_Demo
import UIKit

final class ViewModelTests: XCTestCase {

    final class MockCatAPIClient: CatAPIClient {
        var breedsResult: Result<[CatBreed], Error> = .success([])
        var imageResult: Result<UIImage, Error> = .failure(NSError(domain: "mock", code: 1))

        func fetchBreeds(completion: @escaping (Result<[CatBreed], Error>) -> Void) {
            completion(breedsResult)
        }

        func fetchCatImage(breedId: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
            completion(imageResult)
        }
    }

    final class DelegateSpy: CatDataDelegate {
        
        func errorOccurred(_ message: String) {
            print("error", message)
        }
        
        var onBreedsChanged: (() -> Void)?
        var onImageChanged: (() -> Void)?

        func breedsChangedNotification() { onBreedsChanged?() }
        func imageChangedNotification() { onImageChanged?() }
    }

    func testGetBreedsUpdatesCatBreeds() {
        let mock = MockCatAPIClient()
        mock.breedsResult = .success([
            CatBreed(
                id: "1",
                name: "Abyssinian",
                description: "desc",
                temperament: nil,
                life_span: nil,
                wikipedia_url: nil,
                experimental: nil,
                hairless: nil,
                indoor: nil,
                lap: nil,
                hypoallergenic: nil,
                rare: nil,
                natural: nil,
                adaptability: nil,
                affection_level: nil,
                child_friendly: nil,
                dog_friendly: nil,
                energy_level: nil,
                grooming: nil,
                health_issues: nil,
                intelligence: nil,
                shedding_level: nil,
                social_needs: nil,
                stranger_friendly: nil,
                vocalisation: nil,
                reference_image_id: nil,
                image: nil
            )
        ])

        let vm = ViewModel(api: mock)

        let exp = expectation(description: "breedsChangedNotification called")
        let spy = DelegateSpy()
        spy.onBreedsChanged = { exp.fulfill() }
        vm.catDataDelegate = spy

        vm.getBreeds()
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(vm.catBreeds?.count, 1)
        XCTAssertEqual(vm.catBreeds?.first?.name, "Abyssinian")
    }
}
