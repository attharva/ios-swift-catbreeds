//
//  FavoritesStore.swift
//  Cat-Demo
//
//  Created by Atharva Kulkarni on 25/02/26.
//

import Foundation

final class FavoritesStore {
    static let shared = FavoritesStore()

    private let key = "favorite_breed_ids"
    private var cached: Set<String>?

    private init() {}

    func isFavorite(id: String) -> Bool {
        loadIfNeeded()
        return cached?.contains(id) ?? false
    }

    func toggle(id: String) -> Bool {
        loadIfNeeded()
        if cached?.contains(id) == true {
            cached?.remove(id)
        } else {
            cached?.insert(id)
        }
        save()
        return cached?.contains(id) ?? false
    }

    private func loadIfNeeded() {
        if cached != nil { return }
        let arr = UserDefaults.standard.stringArray(forKey: key) ?? []
        cached = Set(arr)
    }

    private func save() {
        UserDefaults.standard.set(Array(cached ?? []), forKey: key)
    }
}
