import Foundation
import Observation

@MainActor
@Observable
final class RecipeDetailViewModel {
    private(set) var loadState: LoadState<MealDetail> = .idle

    private let repository: MealRepositoryProtocol
    private let favouritesStore: FavouritesStore
    private let mealID: String
    private var loadTask: Task<Void, Never>?

    init(mealID: String, repository: MealRepositoryProtocol, favouritesStore: FavouritesStore) {
        self.mealID = mealID
        self.repository = repository
        self.favouritesStore = favouritesStore
    }

    func load() async {
        loadTask?.cancel()
        loadTask = Task {
            if loadState.value == nil {
                loadState = .loading
            }

            if let cached = await repository.cachedMealDetail(id: mealID) {
                loadState = .loaded(cached)
            }

            do {
                let detail = try await repository.fetchMealDetail(id: mealID)
                try Task.checkCancellation()
                loadState = .loaded(detail)
            } catch is CancellationError {
                return
            } catch {
                if let existing = loadState.value {
                    loadState = .stale(existing, message: error.localizedDescription)
                } else {
                    loadState = .failed(message: error.localizedDescription)
                }
            }
        }
        await loadTask?.value
    }

    func toggleFavourite() -> Bool {
        favouritesStore.toggleFavourite(id: mealID)
    }

    func isFavourite() -> Bool {
        favouritesStore.isFavourite(id: mealID)
    }
}
