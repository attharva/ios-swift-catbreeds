//
//  EnumError.swift
//  Cat-Demo
//
//  Created by Atharva Kulkarni on 25/02/26.
//

import UIKit

enum APIError: LocalizedError {
    
    case invalidURL
    case transport(Error)
    case invalidResponse
    case httpStatus(Int)
    case noData
    case decoding(Error)
    case imageDecode

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL."
        case .transport(let err): return "Network error: \(err.localizedDescription)"
        case .invalidResponse: return "Invalid server response."
        case .httpStatus(let code): return "Request failed (HTTP \(code))."
        case .noData: return "No data received from server."
        case .decoding: return "Failed to parse server response."
        case .imageDecode: return "Failed to decode image."
        }
    }
}

enum CatImageError: LocalizedError {
    case noImageAvailable

    var errorDescription: String? {
        switch self {
        case .noImageAvailable:
            return "No image available for this breed."
        }
    }
}
