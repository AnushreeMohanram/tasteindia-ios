import Foundation

struct MealDetail: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let thumbnailURL: URL?
    let category: String?
    let area: String?
    let instructions: String
    let ingredients: [IngredientLine]
    let tags: [String]
    let sourceURL: URL?
    let youtubeURL: URL?
    let alternateName: String?
    let imageSource: String?
    let creativeCommonsConfirmed: String?
    let dateModified: String?

    var instructionParagraphs: [String] {
        instructions
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

struct IngredientLine: Identifiable, Hashable, Sendable {
    var id: String { "\(name)-\(measurement)" }
    let name: String
    let measurement: String

    var displayText: String {
        if measurement.isEmpty { return name }
        if name.isEmpty { return measurement }
        return "\(measurement) \(name)"
    }
}
