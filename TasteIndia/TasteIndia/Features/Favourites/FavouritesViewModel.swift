import Foundation
import Observation

@MainActor
@Observable
final class FavouritesViewModel {
    private(set) var favouriteMeals: [MealSummary] = []
    private(set) var loadState: LoadState<[MealSummary]> = .idle
    var scrollPositionID: String?

    private let repository: MealRepositoryProtocol
    private let favouritesStore: FavouritesStore

    init(repository: MealRepositoryProtocol, favouritesStore: FavouritesStore) {
        self.repository = repository
        self.favouritesStore = favouritesStore
    }

    func bootstrapIfNeeded(from baseMeals: [MealSummary]) async {
        refresh(from: baseMeals)
    }

    func refresh(from baseMeals: [MealSummary]) {
        let ids = favouritesStore.favouriteIDs
        favouriteMeals = baseMeals
            .filter { ids.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        if favouriteMeals.isEmpty {
            loadState = ids.isEmpty ? .empty : .empty
        } else {
            loadState = .loaded(favouriteMeals)
        }
    }

    func toggleFavourite(id: String, baseMeals: [MealSummary]) {
        _ = favouritesStore.toggleFavourite(id: id)
        refresh(from: baseMeals)
    }

    func isFavourite(id: String) -> Bool {
        favouritesStore.isFavourite(id: id)
    }
}
