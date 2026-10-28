import Foundation

enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case stale(Value, message: String)
    case failed(message: String)

    var value: Value? {
        switch self {
        case .loaded(let value), .stale(let value, _):
            return value
        default:
            return nil
        }
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
