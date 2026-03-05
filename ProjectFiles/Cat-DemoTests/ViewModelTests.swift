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

    // MARK: - Mock API

    final class MockCatAPIClient: CatAPIClient {

        var breedsByPage: [Int: Result<[CatBreed], Error>] = [:]
        var imageResult: Result<UIImage, Error> =
            .failure(NSError(domain: "mock", code: 1))

        func fetchBreeds(page: Int,
                         limit: Int,
                         completion: @escaping (Result<[CatBreed], Error>) -> Void) {

            if let result = breedsByPage[page] {
                completion(result)
            } else {
                completion(.success([]))
            }
        }

        func fetchCatImage(breedId: String,
                           completion: @escaping (Result<UIImage, Error>) -> Void) {
            completion(imageResult)
        }
    }

    // MARK: - Delegate Spy

    final class DelegateSpy: CatDataDelegate {

        var breedsChangedCalled = false

        func breedsChangedNotification() {
            breedsChangedCalled = true
        }

        func imageChangedNotification() { }

        func errorOccurred(_ message: String) { }
    }

    // MARK: - Helper

    private func makeBreed(id: String, name: String) -> CatBreed {
        CatBreed(
            id: id,
            name: name,
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
    }

    // MARK: - Tests

    func testOnViewDidLoadLoadsFirstPage() {

        let mockAPI = MockCatAPIClient()
        mockAPI.breedsByPage[0] = .success([
            makeBreed(id: "1", name: "Abyssinian"),
            makeBreed(id: "2", name: "Bengal")
        ])

        let vm = ViewModel(api: mockAPI)
        let spy = DelegateSpy()
        vm.catDataDelegate = spy

        vm.onViewDidLoad()

        XCTAssertTrue(spy.breedsChangedCalled)
        XCTAssertEqual(vm.numberOfRows, 2)
        XCTAssertEqual(vm.breed(at: 0).name, "Abyssinian")
    }

    func testPaginationLoadsSecondPage() {

        let mockAPI = MockCatAPIClient()

        mockAPI.breedsByPage[0] = .success(
            (0..<10).map { makeBreed(id: "\($0)", name: "Breed\($0)") }
        )

        mockAPI.breedsByPage[1] = .success(
            (10..<20).map { makeBreed(id: "\($0)", name: "Breed\($0)") }
        )

        let vm = ViewModel(api: mockAPI)
        let spy = DelegateSpy()
        vm.catDataDelegate = spy

        vm.onViewDidLoad()

        XCTAssertEqual(vm.numberOfRows, 10)

        // Simulate scrolling near bottom
        vm.onWillDisplayRow(9)

        XCTAssertEqual(vm.numberOfRows, 20)
    }

    func testSearchFiltersBreedsCorrectly() {

        let mockAPI = MockCatAPIClient()
        mockAPI.breedsByPage[0] = .success([
            makeBreed(id: "1", name: "Abyssinian"),
            makeBreed(id: "2", name: "Bengal"),
            makeBreed(id: "3", name: "Birman")
        ])

        let vm = ViewModel(api: mockAPI)
        vm.onViewDidLoad()

        vm.onSearchTextChanged("Bi")

        XCTAssertEqual(vm.numberOfRows, 1)
        XCTAssertEqual(vm.breed(at: 0).name, "Birman")
    }
}
