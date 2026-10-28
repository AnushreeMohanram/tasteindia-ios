import Foundation

struct MealSummary: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let thumbnailURL: URL?
    var category: String?

    init(id: String, name: String, thumbnailURL: URL?, category: String? = nil) {
        self.id = id
        self.name = name
        self.thumbnailURL = thumbnailURL
        self.category = category
    }
}
