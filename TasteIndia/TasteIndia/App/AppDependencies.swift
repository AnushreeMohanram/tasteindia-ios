import Foundation

@MainActor
final class AppDependencies {
    let mealRepository: MealRepositoryProtocol
    let favouritesStore: FavouritesStore

    let recipesViewModel: RecipesViewModel
    let favouritesViewModel: FavouritesViewModel

    init(
        mealRepository: MealRepositoryProtocol? = nil,
        favouritesStore: FavouritesStore? = nil
    ) {
        let networkClient = NetworkClient()
        let detailCache = MealDetailCache(maxConcurrentFetches: 3)
        let repository = mealRepository ?? TheMealDBMealRepository(
            networkClient: networkClient,
            detailCache: detailCache
        )
        let store = favouritesStore ?? FavouritesStore()

        self.mealRepository = repository
        self.favouritesStore = store
        self.recipesViewModel = RecipesViewModel(repository: repository, favouritesStore: store)
        self.favouritesViewModel = FavouritesViewModel(repository: repository, favouritesStore: store)
    }
}
