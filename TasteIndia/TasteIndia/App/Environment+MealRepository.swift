import SwiftUI

private struct MealRepositoryKey: EnvironmentKey {
    static let defaultValue: MealRepositoryProtocol = PreviewMealRepository()
}

extension EnvironmentValues {
    var mealRepository: MealRepositoryProtocol {
        get { self[MealRepositoryKey.self] }
        set { self[MealRepositoryKey.self] = newValue }
    }
}

private struct PreviewMealRepository: MealRepositoryProtocol {
    func fetchIndianMeals() async throws -> [MealSummary] { [] }
    func fetchCategories() async throws -> [String] { [] }
    func fetchMealIDs(forCategory category: String) async throws -> Set<String> { [] }
    func fetchMealIDs(forIngredient ingredient: String) async throws -> Set<String> { [] }
    func fetchMealDetail(id: String) async throws -> MealDetail {
        throw NetworkError.invalidResponse
    }
    func cachedMealDetail(id: String) async -> MealDetail? { nil }
}
