import Foundation

actor MealDetailCache {
    private var storage: [String: MealDetail] = [:]
    private var inFlight: [String: Task<MealDetail, Error>] = [:]
    private let maxConcurrentFetches: Int
    private var activeFetchCount = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(maxConcurrentFetches: Int = 3) {
        self.maxConcurrentFetches = maxConcurrentFetches
    }

    func cachedDetail(for id: String) -> MealDetail? {
        storage[id]
    }

    func store(_ detail: MealDetail) {
        storage[detail.id] = detail
    }

    func detail(for id: String, fetch: @Sendable @escaping () async throws -> MealDetail) async throws -> MealDetail {
        if let cached = storage[id] {
            return cached
        }
        if let task = inFlight[id] {
            return try await task.value
        }

        await acquireSlot()

        let task = Task<MealDetail, Error> {
            defer { Task { await self.releaseSlot() } }
            let detail = try await fetch()
            await self.store(detail)
            return detail
        }

        inFlight[id] = task

        do {
            let detail = try await task.value
            inFlight[id] = nil
            return detail
        } catch {
            inFlight[id] = nil
            throw error
        }
    }

    private func acquireSlot() async {
        if activeFetchCount < maxConcurrentFetches {
            activeFetchCount += 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
        activeFetchCount += 1
    }

    private func releaseSlot() {
        activeFetchCount = max(0, activeFetchCount - 1)
        if !waiters.isEmpty {
            let next = waiters.removeFirst()
            next.resume()
        }
    }
}
