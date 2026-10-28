import Foundation

enum SortOrder: String, CaseIterable, Identifiable, Sendable {
    case nameAscending = "Name A–Z"
    case nameDescending = "Name Z–A"

    var id: String { rawValue }
}

struct FilterCriteria: Equatable, Sendable {
    var searchText: String = ""
    var category: String?
    var ingredient: String?
    var favouritesOnly: Bool = false
    var sortOrder: SortOrder = .nameAscending

    var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || category != nil
            || ingredient != nil
            || favouritesOnly
    }

    var activeFilterLabels: [String] {
        var labels: [String] = []
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            labels.append("Search: \(trimmedSearch)")
        }
        if let category {
            labels.append("Category: \(category)")
        }
        if let ingredient {
            labels.append("Ingredient: \(ingredient)")
        }
        if favouritesOnly {
            labels.append("Favourites only")
        }
        labels.append("Sort: \(sortOrder.rawValue)")
        return labels
    }

    mutating func clearAll() {
        searchText = ""
        category = nil
        ingredient = nil
        favouritesOnly = false
        sortOrder = .nameAscending
    }
}
