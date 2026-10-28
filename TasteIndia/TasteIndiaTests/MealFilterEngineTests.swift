import XCTest
@testable import TasteIndia

final class MealFilterEngineTests: XCTestCase {
    private let baseMeals: [MealSummary] = [
        MealSummary(id: "1", name: "Dal fry", thumbnailURL: nil, category: "Vegetarian"),
        MealSummary(id: "2", name: "Chicken Handi", thumbnailURL: nil, category: "Chicken"),
        MealSummary(id: "3", name: "Lamb Biryani", thumbnailURL: nil, category: "Lamb")
    ]

    func testCategoryIntersectionKeepsIndianBoundary() {
        let categoryIDs: Set<String> = ["1", "2", "999"]
        var criteria = FilterCriteria()
        criteria.category = "Chicken"

        let results = MealFilterEngine.apply(
            baseMeals: baseMeals,
            criteria: criteria,
            favouriteIDs: [],
            categoryIDs: categoryIDs,
            ingredientIDs: nil
        )

        XCTAssertEqual(results.map(\.id), ["2"])
    }

    func testCombinedCategoryAndIngredientIntersection() {
        let categoryIDs: Set<String> = ["1", "2", "3"]
        let ingredientIDs: Set<String> = ["2", "3"]
        var criteria = FilterCriteria()
        criteria.category = "Mixed"
        criteria.ingredient = "Chicken"

        let results = MealFilterEngine.apply(
            baseMeals: baseMeals,
            criteria: criteria,
            favouriteIDs: [],
            categoryIDs: categoryIDs,
            ingredientIDs: ingredientIDs
        )

        XCTAssertEqual(results.map(\.id), ["2"])
    }

    func testFavouritesOnlyFilter() {
        var criteria = FilterCriteria()
        criteria.favouritesOnly = true

        let results = MealFilterEngine.apply(
            baseMeals: baseMeals,
            criteria: criteria,
            favouriteIDs: ["1", "3"],
            categoryIDs: nil,
            ingredientIDs: nil
        )

        XCTAssertEqual(Set(results.map(\.id)), ["1", "3"])
    }

    func testSortOrderDescending() {
        var criteria = FilterCriteria()
        criteria.sortOrder = .nameDescending

        let results = MealFilterEngine.apply(
            baseMeals: baseMeals,
            criteria: criteria,
            favouriteIDs: [],
            categoryIDs: nil,
            ingredientIDs: nil
        )

        XCTAssertEqual(results.map(\.name), ["Lamb Biryani", "Dal fry", "Chicken Handi"])
    }
}
