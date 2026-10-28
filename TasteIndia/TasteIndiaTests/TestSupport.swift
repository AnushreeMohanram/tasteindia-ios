import Foundation

/// Shared test double used across unit tests.
@MainActor
final class MockMealRepository: MealRepositoryProtocol {
    var categoryDelay: TimeInterval = 0
    var ingredientDelay: TimeInterval = 0

    func fetchIndianMeals() async throws -> [MealSummary] { [] }
    func fetchCategories() async throws -> [String] { ["Chicken", "Lamb"] }

    func fetchMealIDs(forCategory category: String) async throws -> Set<String> {
        if categoryDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(categoryDelay * 1_000_000_000))
        }
        if category == "Chicken" { return ["2"] }
        return []
    }

    func fetchMealIDs(forIngredient ingredient: String) async throws -> Set<String> {
        if ingredientDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(ingredientDelay * 1_000_000_000))
        }
        if ingredient == "Lamb" { return ["3"] }
        return []
    }

    func fetchMealDetail(id: String) async throws -> MealDetail {
        throw NetworkError.invalidResponse
    }

    func cachedMealDetail(id: String) async -> MealDetail? { nil }
}

enum TestFixtures {
    static func data(named name: String) throws -> Data {
        let bundle = Bundle(for: BundleToken.self)
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
}

private final class BundleToken {}

private func XCTUnwrap<T>(_ expression: T?, file: StaticString = #file, line: UInt = #line) throws -> T {
    guard let value = expression else {
        throw NSError(domain: "TestFixtures", code: 1)
    }
    return value
}
