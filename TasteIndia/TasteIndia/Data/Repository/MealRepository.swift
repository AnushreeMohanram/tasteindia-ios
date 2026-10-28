import Foundation

protocol MealRepositoryProtocol: Sendable {
    func fetchIndianMeals() async throws -> [MealSummary]
    func fetchCategories() async throws -> [String]
    func fetchMealIDs(forCategory category: String) async throws -> Set<String>
    func fetchMealIDs(forIngredient ingredient: String) async throws -> Set<String>
    func fetchMealDetail(id: String) async throws -> MealDetail
    func cachedMealDetail(id: String) async -> MealDetail?
}

struct MealFilterEngine {
    static func apply(
        baseMeals: [MealSummary],
        criteria: FilterCriteria,
        favouriteIDs: Set<String>,
        categoryIDs: Set<String>?,
        ingredientIDs: Set<String>?
    ) -> [MealSummary] {
        var indianBoundary = Set(baseMeals.map(\.id))
        var results = baseMeals

        if let categoryIDs {
            let allowed = indianBoundary.intersection(categoryIDs)
            results = results.filter { allowed.contains($0.id) }
            indianBoundary = allowed
        }

        if let ingredientIDs {
            let allowed = indianBoundary.intersection(ingredientIDs)
            results = results.filter { allowed.contains($0.id) }
        }

        let trimmedSearch = criteria.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            results = results.filter {
                $0.name.localizedCaseInsensitiveContains(trimmedSearch)
            }
        }

        if criteria.favouritesOnly {
            results = results.filter { favouriteIDs.contains($0.id) }
        }

        switch criteria.sortOrder {
        case .nameAscending:
            results.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            results.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        }

        return results
    }
}

final class TheMealDBMealRepository: MealRepositoryProtocol, @unchecked Sendable {
    private let networkClient: NetworkClientProtocol
    private let detailCache: MealDetailCache
    private let decoder: JSONDecoder

    init(networkClient: NetworkClientProtocol, detailCache: MealDetailCache, decoder: JSONDecoder = JSONDecoder()) {
        self.networkClient = networkClient
        self.detailCache = detailCache
        self.decoder = decoder
    }

    func fetchIndianMeals() async throws -> [MealSummary] {
        let primary = try await fetchMeals(from: TheMealDBEndpoints.indianMeals())
        if !primary.isEmpty {
            return primary
        }
        return try await fetchMeals(from: TheMealDBEndpoints.indiaMealsFallback())
    }

    func fetchCategories() async throws -> [String] {
        let request = TheMealDBEndpoints.request(url: TheMealDBEndpoints.categories())
        let data = try await networkClient.data(for: request)
        let response = try decoder.decode(CategoryListResponseDTO.self, from: data)
        return response.meals?.map(\.strCategory).sorted() ?? []
    }

    func fetchMealIDs(forCategory category: String) async throws -> Set<String> {
        let url = TheMealDBEndpoints.filterByCategory(category)
        let meals = try await fetchMeals(from: url)
        return Set(meals.map(\.id))
    }

    func fetchMealIDs(forIngredient ingredient: String) async throws -> Set<String> {
        let url = TheMealDBEndpoints.filterByIngredient(ingredient)
        let meals = try await fetchMeals(from: url)
        return Set(meals.map(\.id))
    }

    func fetchMealDetail(id: String) async throws -> MealDetail {
        try await detailCache.detail(for: id) {
            let request = TheMealDBEndpoints.request(url: TheMealDBEndpoints.lookup(mealID: id))
            let data = try await self.networkClient.data(for: request)
            let response = try self.decoder.decode(MealLookupResponseDTO.self, from: data)
            guard let dto = response.meals?.first else {
                throw NetworkError.decodingFailed
            }
            return MealMapper.mapDetail(dto)
        }
    }

    func cachedMealDetail(id: String) async -> MealDetail? {
        await detailCache.cachedDetail(for: id)
    }

    private func fetchMeals(from url: URL) async throws -> [MealSummary] {
        let request = TheMealDBEndpoints.request(url: url)
        let data = try await networkClient.data(for: request)
        let response = try decoder.decode(MealsListResponseDTO.self, from: data)
        return response.meals?.map(MealMapper.mapSummary) ?? []
    }
}
