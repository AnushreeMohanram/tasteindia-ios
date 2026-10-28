import Foundation

enum TheMealDBEndpoints {
    static let baseURL = URL(string: "https://www.themealdb.com/api/json/v1/1/")!

    static func indianMeals() -> URL {
        baseURL.appending(path: "filter.php", directoryHint: .notDirectory)
            .appending(queryItems: [URLQueryItem(name: "a", value: "Indian")])
    }

    /// Fallback when the documented `a=Indian` filter returns no meals (observed API drift).
    static func indiaMealsFallback() -> URL {
        baseURL.appending(path: "filter.php", directoryHint: .notDirectory)
            .appending(queryItems: [URLQueryItem(name: "a", value: "India")])
    }

    static func lookup(mealID: String) -> URL {
        baseURL.appending(path: "lookup.php", directoryHint: .notDirectory)
            .appending(queryItems: [URLQueryItem(name: "i", value: mealID)])
    }

    static func filterByCategory(_ category: String) -> URL {
        baseURL.appending(path: "filter.php", directoryHint: .notDirectory)
            .appending(queryItems: [URLQueryItem(name: "c", value: category)])
    }

    static func filterByIngredient(_ ingredient: String) -> URL {
        baseURL.appending(path: "filter.php", directoryHint: .notDirectory)
            .appending(queryItems: [URLQueryItem(name: "i", value: ingredient)])
    }

    static func categories() -> URL {
        baseURL.appending(path: "list.php", directoryHint: .notDirectory)
            .appending(queryItems: [URLQueryItem(name: "c", value: "list")])
    }

    static func request(url: URL, timeout: TimeInterval = 20) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}

private extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.queryItems = (components.queryItems ?? []) + queryItems
        return components.url ?? self
    }
}
