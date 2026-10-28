import Foundation

enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    case cancelled
    case offline

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL could not be formed."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .httpStatus(let code):
            return "The server responded with status code \(code)."
        case .decodingFailed:
            return "The recipe data could not be read."
        case .cancelled:
            return "The request was cancelled."
        case .offline:
            return "You appear to be offline. Check your connection and try again."
        }
    }
}

protocol NetworkClientProtocol: Sendable {
    func data(for request: URLRequest) async throws -> Data
}

struct NetworkClient: NetworkClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            guard (200 ... 299).contains(http.statusCode) else {
                throw NetworkError.httpStatus(http.statusCode)
            }
            return data
        } catch is CancellationError {
            throw NetworkError.cancelled
        } catch let error as URLError where error.code == .cancelled {
            throw NetworkError.cancelled
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            throw NetworkError.offline
        } catch let error as URLError where error.code == .timedOut {
            throw NetworkError.httpStatus(408)
        } catch {
            throw error
        }
    }
}

struct FixtureNetworkClient: NetworkClientProtocol {
    private let responses: [String: Data]

    init(responses: [String: Data]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> Data {
        guard let url = request.url?.absoluteString else {
            throw NetworkError.invalidURL
        }
        if let data = responses.first(where: { url.contains($0.key) })?.value {
            return data
        }
        throw NetworkError.invalidResponse
    }
}
