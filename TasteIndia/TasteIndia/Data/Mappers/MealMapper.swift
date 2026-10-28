import Foundation

enum MealMapper {
    static func mapSummary(_ dto: MealSummaryDTO) -> MealSummary {
        MealSummary(
            id: dto.idMeal,
            name: dto.strMeal,
            thumbnailURL: URL.safe(string: dto.strMealThumb)
        )
    }

    static func mapDetail(_ dto: MealDetailDTO) -> MealDetail {
        MealDetail(
            id: dto.idMeal,
            name: dto.strMeal,
            thumbnailURL: URL.safe(string: dto.strMealThumb),
            category: dto.strCategory?.nonEmpty,
            area: dto.strArea?.nonEmpty,
            instructions: dto.strInstructions?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            ingredients: normalizeIngredients(ingredients: dto.ingredientFields, measures: dto.measureFields),
            tags: normalizeTags(dto.strTags),
            sourceURL: URL.safe(string: dto.strSource),
            youtubeURL: URL.safe(string: dto.strYoutube),
            alternateName: dto.strMealAlternate?.nonEmpty,
            imageSource: dto.strImageSource?.nonEmpty,
            creativeCommonsConfirmed: dto.strCreativeCommonsConfirmed?.nonEmpty,
            dateModified: dto.dateModified?.nonEmpty
        )
    }

    static func normalizeIngredients(ingredients: [String?], measures: [String?]) -> [IngredientLine] {
        let pairs = zip(ingredients, measures)
        return pairs.compactMap { ingredient, measure in
            let name = ingredient?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let measurement = measure?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty || !measurement.isEmpty else { return nil }
            return IngredientLine(name: name, measurement: measurement)
        }
    }

    static func normalizeTags(_ raw: String?) -> [String] {
        guard let raw else { return [] }
        return raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension URL {
    static func safe(string: String?) -> URL? {
        guard let string = string?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty else {
            return nil
        }
        guard let url = URL(string: string), let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }
        return url
    }
}
