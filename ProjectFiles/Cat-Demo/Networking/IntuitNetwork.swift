// Copyright © 2021 Intuit, Inc. All rights reserved.
import Foundation
import UIKit

/// Network interface
class Network {
    
    private static let urlImageCache = NSCache<NSString, UIImage>()
    
    // Cache reference_image_id -> url (so we don't re-request)
    private static let imageUrlCache = NSCache<NSString, NSString>()
    
    private static let imageCache = NSCache<NSString, UIImage>()
    
    /// Errors from network responses
    ///
    /// - badUrl: URL could not be created
    /// - responseError: The request was unsuccessful due to an error
    /// - responseNoData: The request returned no usable data
    enum NetworkError: Int {
        case badUrl
        case responseError
        case responseNoData
        case decodeError
    }
    
    private class func validateHTTP(_ response: URLResponse?) -> Result<Void, Error> {
        guard let http = response as? HTTPURLResponse else {
            return .failure(APIError.invalidResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            return .failure(APIError.httpStatus(http.statusCode))
        }
        return .success(())
    }
    
    /// FetchCatBreeds - retrieve a list of cat breeds from The Cat API
    ///
    /// - Parameter completion: Closure that returns CatBreed on success, an Error on failure
    class func fetchCatBreeds(page: Int, limit: Int, completion: @escaping (Swift.Result<[CatBreed], Error>) -> Void) {
        
        func finish(_ result: Result<[CatBreed], Error>) {
            DispatchQueue.main.async { completion(result) }
        }
        
        /// Create the URL for the request
//        guard let url = URL(string: "https://api.thecatapi.com/v1/breeds") else {
//            let error = NSError(domain: "Network.fetchCats", code: NetworkError.badUrl.rawValue, userInfo: nil)
//            return completion(Result.failure(error))
//        }
        
        guard var components = URLComponents(string: "https://api.thecatapi.com/v1/breeds") else {
            return finish(.failure(URLError(.badURL)))
        }
        
        
        
//        https://api.thecatapi.com/v1/breeds?limit=10&page=0
        
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "page", value: "\(page)")
            
        ]
        
        guard let url = components.url else {
            
            return finish(.failure(URLError(.badURL)))
        
        }
        
        /// Start a data task for the URL
        URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let error {
                return finish(.failure(error))
            }
            
            guard let data else {
                return finish(.failure(APIError.noData))
            }
            
            switch validateHTTP(response) {
            case .failure(let err):
                return finish(.failure(err))
            case .success:
                break
            }
            
            do {
                let breeds = try JSONDecoder().decode([CatBreed].self, from: data)
                finish(.success(breeds))
            } catch {
                finish(.failure(error))
            }
            
        }.resume()
    }
    
    private struct ImageByIdResponse: Decodable {
        let url: String?
    }

    class func fetchImageURL(referenceImageId: String) async throws -> String {
        if let cached = imageUrlCache.object(forKey: referenceImageId as NSString) {
            return cached as String
        }

        guard let url = URL(string: "https://api.thecatapi.com/v1/images/\(referenceImageId)") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        
        
        switch validateHTTP(response) {
        case .failure(let err): throw err
        case .success: break
        }
        
        let decoded = try JSONDecoder().decode(ImageByIdResponse.self, from: data)
        
        guard let imageUrl = decoded.url, !imageUrl.isEmpty else {
            throw URLError(.badServerResponse)
        }

        imageUrlCache.setObject(imageUrl as NSString, forKey: referenceImageId as NSString)
        return imageUrl
    }
    
    class func fetchImage(from urlString: String) async throws -> UIImage {
        if let cached = urlImageCache.object(forKey: urlString as NSString) {
            return cached
        }

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        
//        print("Calling from Network,\(Thread.current)")

        switch validateHTTP(response) {
        case .failure(let err): throw err
        case .success: break
        }

//        print("Before UIImage(data:). isMainThread=\(Thread.isMainThread) thread=\(Thread.current)")
        
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

//        Command: po Thread.isMainThread
        
//        print("After UIImage(data:). isMainThread=\(Thread.isMainThread) thread=\(Thread.current)")
        
        urlImageCache.setObject(image, forKey: urlString as NSString)
        
        return image
    }
    
    /// Fetch a cat image
    /// - Parameters:
    ///   - breedId: The breed ID (retrieved from the `fetchCatBreeds` call
    ///   - completion: Returns a UIImage or Error
    
    class func fetchCatImage(breedId: String, completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        func finish(_ result: Result<UIImage, Error>) {
            DispatchQueue.main.async { completion(result) }
        }

        if let cached = imageCache.object(forKey: breedId as NSString) {
            return finish(.success(cached))
        }

        guard let url = URL(string: "https://api.thecatapi.com/v1/images/search?breed_ids=\(breedId)&include_breeds=true") else {
            let error = NSError(domain: "Network.fetchCatDetails", code: NetworkError.badUrl.rawValue, userInfo: nil)
            return finish(.failure(error))
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil else {
                let error = NSError(domain: "Network.fetchCatDetails", code: NetworkError.responseError.rawValue, userInfo: nil)
                return finish(.failure(error))
            }

            guard let data = data else {
                let error = NSError(domain: "Network.fetchCatDetails", code: NetworkError.responseNoData.rawValue, userInfo: nil)
                return finish(.failure(error))
            }

            do {
                let catDetails = try JSONDecoder().decode([CatDetails].self, from: data)
                
                guard let urlString = catDetails.first?.url else {
                    return finish(.failure(CatImageError.noImageAvailable))
                }

                guard let catImageUrl = URL(string: urlString) else {
                    let error = NSError(domain: "Network.fetchCatDetails", code: NetworkError.badUrl.rawValue, userInfo: nil)
                    return finish(.failure(error))
                }

                URLSession.shared.dataTask(with: catImageUrl) { imageData, _, imageError in
                    guard imageError == nil else {
                        let error = NSError(domain: "Network.fetchCatDetails", code: NetworkError.responseError.rawValue, userInfo: nil)
                        return finish(.failure(error))
                    }

                    guard let imageData = imageData, let image = UIImage(data: imageData) else {
                        let error = NSError(domain: "Network.fetchCatDetails", code: NetworkError.responseNoData.rawValue, userInfo: nil)
                        return finish(.failure(error))
                    }

                    imageCache.setObject(image, forKey: breedId as NSString)
                    finish(.success(image))
                }.resume()

            } catch {
                let error = NSError(domain: "Network.decode", code: NetworkError.decodeError.rawValue, userInfo: nil)
                return finish(.failure(error))
            }
        }.resume()
    }
}
