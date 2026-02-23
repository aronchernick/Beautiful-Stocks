import Foundation

// MARK: - Cached CPI Service

/// A caching wrapper around any `CPIDataProvider`.
/// Stores fetched CPI data on disk and only re-fetches from the
/// network when the cache is missing or stale.
///
/// CPI data is released monthly, so a 7-day cache window is more
/// than sufficient to avoid redundant FRED API calls.
final class CachedCPIService: CPIDataProvider {

    private let upstream: CPIDataProvider
    private let cacheFileName = "cpi_cache.json"
    private let staleness: TimeInterval // seconds before re-fetching

    /// - Parameters:
    ///   - upstream: The real network-backed CPI provider (e.g. `FREDService`).
    ///   - staleness: How many seconds the cache is considered fresh.
    ///                Defaults to 7 days.
    init(upstream: CPIDataProvider = FREDService(),
         staleness: TimeInterval = 7 * 24 * 60 * 60) {
        self.upstream = upstream
        self.staleness = staleness
    }

    // MARK: - CPIDataProvider

    func fetchCPI(startDate: Date?, endDate: Date?) async throws -> [CPIDataPoint] {
        // 1. Try to load from disk if fresh enough
        if let cached = loadFromDisk(), !isCacheStale() {
            return cached
        }

        // 2. Fetch from network
        let fresh = try await upstream.fetchCPI(startDate: startDate, endDate: endDate)

        // 3. Persist to disk (fire-and-forget; don't block on errors)
        saveToDisk(fresh)

        return fresh
    }

    // MARK: - Disk Persistence

    private var cacheFileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("BeautifulStocks", isDirectory: true)

        // Ensure the directory exists
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        return dir.appendingPathComponent(cacheFileName)
    }

    private func loadFromDisk() -> [CPIDataPoint]? {
        let url = cacheFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([CPIDataPoint].self, from: data)
        } catch {
            // Corrupt cache — delete it so a fresh fetch takes over
            try? FileManager.default.removeItem(at: url)
            return nil
        }
    }

    private func saveToDisk(_ points: [CPIDataPoint]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(points)
            try data.write(to: cacheFileURL, options: .atomic)
        } catch {
            // Best-effort; the app still works without a cache
            print("[CachedCPIService] Failed to write cache: \(error)")
        }
    }

    private func isCacheStale() -> Bool {
        let url = cacheFileURL
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modified = attrs[.modificationDate] as? Date else {
            return true // no file → treat as stale
        }
        return Date().timeIntervalSince(modified) > staleness
    }
}
