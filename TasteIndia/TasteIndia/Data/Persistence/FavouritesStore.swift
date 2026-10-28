import Foundation
import Observation

@MainActor
@Observable
final class FavouritesStore {
    static let storageKey = "tasteindia.favouriteMealIDs"

    private(set) var favouriteIDs: Set<String>
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let stored = userDefaults.stringArray(forKey: Self.storageKey) ?? []
        self.favouriteIDs = Set(stored)
    }

    func isFavourite(id: String) -> Bool {
        favouriteIDs.contains(id)
    }

    func setFavourite(_ isFavourite: Bool, for id: String) {
        if isFavourite {
            favouriteIDs.insert(id)
        } else {
            favouriteIDs.remove(id)
        }
        persist()
    }

    @discardableResult
    func toggleFavourite(id: String) -> Bool {
        let isNowFavourite: Bool
        if favouriteIDs.contains(id) {
            favouriteIDs.remove(id)
            isNowFavourite = false
        } else {
            favouriteIDs.insert(id)
            isNowFavourite = true
        }
        persist()
        return isNowFavourite
    }

    private func persist() {
        userDefaults.set(Array(favouriteIDs).sorted(), forKey: Self.storageKey)
    }
}

protocol FavouritesStoreProtocol: AnyObject, Sendable {
    func allFavouriteIDs() -> Set<String>
    func isFavourite(id: String) -> Bool
    func setFavourite(_ isFavourite: Bool, for id: String)
    func toggleFavourite(id: String) -> Bool
}

extension FavouritesStore: FavouritesStoreProtocol {
    func allFavouriteIDs() -> Set<String> { favouriteIDs }
}

final class InMemoryFavouritesStore: FavouritesStoreProtocol, @unchecked Sendable {
    private var ids: Set<String>
    private let lock = NSLock()

    init(initial: Set<String> = []) {
        self.ids = initial
    }

    func allFavouriteIDs() -> Set<String> {
        lock.lock()
        defer { lock.unlock() }
        return ids
    }

    func isFavourite(id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return ids.contains(id)
    }

    func setFavourite(_ isFavourite: Bool, for id: String) {
        lock.lock()
        defer { lock.unlock() }
        if isFavourite {
            ids.insert(id)
        } else {
            ids.remove(id)
        }
    }

    func toggleFavourite(id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if ids.contains(id) {
            ids.remove(id)
            return false
        }
        ids.insert(id)
        return true
    }
}
