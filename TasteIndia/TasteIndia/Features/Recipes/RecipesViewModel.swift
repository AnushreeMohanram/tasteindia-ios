import Foundation
import Observation

@MainActor
@Observable
final class RecipesViewModel {
    private(set) var baseMeals: [MealSummary] = []
    private(set) var displayedMeals: [MealSummary] = []
    private(set) var loadState: LoadState<[MealSummary]> = .idle
    private(set) var categoryOptions: [String] = []
    private(set) var isApplyingRemoteFilters = false

    var filters = FilterCriteria()
    var scrollPositionID: String?
    var showFilters = false

    private let repository: MealRepositoryProtocol
    private let favouritesStore: FavouritesStore
    private var filterTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    private var filterGeneration = 0
    private var categoryIDCache: [String: Set<String>] = [:]
    private var ingredientIDCache: [String: Set<String>] = [:]
    private var searchDebounceTask: Task<Void, Never>?

    init(repository: MealRepositoryProtocol, favouritesStore: FavouritesStore) {
        self.repository = repository
        self.favouritesStore = favouritesStore
    }

    func bootstrapIfNeeded() async {
        guard case .idle = loadState else { return }
        await reloadIndianMeals()
    }

    func reloadIndianMeals() async {
        loadTask?.cancel()
        loadTask = Task {
            if baseMeals.isEmpty {
                loadState = .loading
            }

            do {
                let meals = try await repository.fetchIndianMeals()
                try Task.checkCancellation()
                baseMeals = meals
                categoryOptions = (try? await repository.fetchCategories()) ?? []
                await applyFilters()
                if displayedMeals.isEmpty {
                    loadState = .empty
                } else {
                    loadState = .loaded(displayedMeals)
                }
            } catch is CancellationError {
                return
            } catch {
                if !baseMeals.isEmpty {
                    loadState = .stale(baseMeals, message: error.localizedDescription)
                } else {
                    loadState = .failed(message: error.localizedDescription)
                }
            }
        }
        await loadTask?.value
    }

    func updateSearchText(_ text: String) {
        filters.searchText = text
        searchDebounceTask?.cancel()
        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await applyFilters()
        }
    }

    func updateFilters(_ updated: FilterCriteria) {
        filters = updated
        Task { await applyFilters() }
    }

    func clearAllFilters() {
        filters.clearAll()
        Task { await applyFilters() }
    }

    func toggleFavourite(id: String) {
        _ = favouritesStore.toggleFavourite(id: id)
        Task { await applyFilters() }
    }

    func isFavourite(id: String) -> Bool {
        favouritesStore.isFavourite(id: id)
    }

    func applyFiltersImmediately() {
        Task { await applyFilters() }
    }

    func seedForTesting(meals: [MealSummary]) {
        baseMeals = meals
        displayedMeals = meals
        loadState = meals.isEmpty ? .empty : .loaded(meals)
    }

    func applyFiltersForTesting() async {
        await applyFilters()
    }

    func refreshCachedEnrichment() async {
        var updated = baseMeals
        for index in updated.indices where updated[index].category == nil {
            if let detail = await repository.cachedMealDetail(id: updated[index].id) {
                updated[index].category = detail.category
            }
        }
        baseMeals = updated
        await applyFilters()
    }

    private func applyFilters() async {
        filterTask?.cancel()
        filterGeneration += 1
        let generation = filterGeneration

        filterTask = Task {
            isApplyingRemoteFilters = filters.category != nil || filters.ingredient != nil

            var categoryIDs: Set<String>?
            var ingredientIDs: Set<String>?

            if let category = filters.category {
                if let cached = categoryIDCache[category] {
                    categoryIDs = cached
                } else {
                    categoryIDs = try? await repository.fetchMealIDs(forCategory: category)
                    if let categoryIDs {
                        categoryIDCache[category] = categoryIDs
                    }
                }
            }

            if let ingredient = filters.ingredient {
                if let cached = ingredientIDCache[ingredient] {
                    ingredientIDs = cached
                } else {
                    ingredientIDs = try? await repository.fetchMealIDs(forIngredient: ingredient)
                    if let ingredientIDs {
                        ingredientIDCache[ingredient] = ingredientIDs
                    }
                }
            }

            guard generation == filterGeneration, !Task.isCancelled else { return }

            let favourites = favouritesStore.favouriteIDs
            let results = MealFilterEngine.apply(
                baseMeals: baseMeals,
                criteria: filters,
                favouriteIDs: favourites,
                categoryIDs: categoryIDs,
                ingredientIDs: ingredientIDs
            )

            guard generation == filterGeneration else { return }

            displayedMeals = results
            isApplyingRemoteFilters = false

            if baseMeals.isEmpty {
                return
            }
            if results.isEmpty {
                loadState = .empty
            } else if case .stale = loadState {
                loadState = .stale(results, message: loadState.value == nil ? "" : staleMessage(from: loadState))
            } else {
                loadState = .loaded(results)
            }
        }

        await filterTask?.value
    }

    private func staleMessage(from state: LoadState<[MealSummary]>) -> String {
        if case .stale(_, let message) = state {
            return message
        }
        return ""
    }
}
