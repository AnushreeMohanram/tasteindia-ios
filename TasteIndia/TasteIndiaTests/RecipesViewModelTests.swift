import XCTest
@testable import TasteIndia

@MainActor
final class RecipesViewModelTests: XCTestCase {
    func testLatestQueryWinsWhenFiltersChangeRapidly() async {
        var repository = MockMealRepository()
        repository.categoryDelay = 0.2
        repository.ingredientDelay = 0.05
        let store = FavouritesStore(userDefaults: UserDefaults(suiteName: "RecipesViewModelTests")!)
        let viewModel = RecipesViewModel(repository: repository, favouritesStore: store)

        viewModel.seedForTesting(meals: [
            MealSummary(id: "1", name: "Dal fry", thumbnailURL: nil),
            MealSummary(id: "2", name: "Chicken Handi", thumbnailURL: nil),
            MealSummary(id: "3", name: "Lamb Biryani", thumbnailURL: nil)
        ])

        viewModel.filters.category = "Chicken"
        await viewModel.applyFiltersForTesting()

        viewModel.filters.category = nil
        viewModel.filters.ingredient = "Lamb"
        await viewModel.applyFiltersForTesting()

        try? await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertEqual(viewModel.filters.ingredient, "Lamb")
        XCTAssertNil(viewModel.filters.category)
        XCTAssertEqual(viewModel.displayedMeals.map(\.id), ["3"])
    }

    func testSearchDebouncingUsesLatestText() async {
        let repository = MockMealRepository()
        let store = FavouritesStore(userDefaults: UserDefaults(suiteName: "RecipesViewModelTestsSearch")!)
        let viewModel = RecipesViewModel(repository: repository, favouritesStore: store)
        viewModel.seedForTesting(meals: [
            MealSummary(id: "1", name: "Dal fry", thumbnailURL: nil),
            MealSummary(id: "2", name: "Chicken Handi", thumbnailURL: nil)
        ])

        viewModel.updateSearchText("Chi")
        viewModel.updateSearchText("Chicken")

        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertEqual(viewModel.displayedMeals.count, 1)
        XCTAssertEqual(viewModel.displayedMeals.first?.name, "Chicken Handi")
    }
}
