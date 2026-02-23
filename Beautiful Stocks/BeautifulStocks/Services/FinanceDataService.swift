import Foundation
import Combine

// MARK: - Finance Data Service (Coordinator)

/// High-level coordinator that combines CPI + Stock data fetching,
/// resolves the common date range, and provides clean data ready
/// for the ReturnCalculator.
@MainActor
final class FinanceDataService: ObservableObject {

    // Sub-services (protocol-typed for testability)
    private let cpiProvider: CPIDataProvider
    private let stockProvider: StockPriceProvider

    // Cached raw data
    @Published private(set) var cpiData: [CPIDataPoint] = []
    @Published private(set) var stockData: [String: [PricePoint]] = [:]  // keyed by ticker
    @Published private(set) var isLoading = false
    @Published private(set) var error: FinanceError?

    nonisolated init(cpiProvider: CPIDataProvider = CachedCPIService(),
                     stockProvider: StockPriceProvider = FMPStockService()) {
        self.cpiProvider = cpiProvider
        self.stockProvider = stockProvider
    }

    // MARK: - Public API

    /// Load all data for a set of assets.
    /// Returns the earliest common start date across every asset + CPI.
    @discardableResult
    func loadData(for assets: [Asset]) async throws -> Date {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // 1. Fetch CPI + all equity prices concurrently.
            let equities = assets.filter { $0.kind == .equity }

            async let cpiTask = cpiProvider.fetchCPI(startDate: nil, endDate: nil)
            let priceTasks: [(String, Task<[PricePoint], Error>)] = equities.map { asset in
                (asset.id, Task { try await self.stockProvider.fetchDailyPrices(ticker: asset.id, startDate: nil, endDate: nil) })
            }

            // Await CPI
            let cpi = try await cpiTask
            self.cpiData = cpi

            // Await each equity
            var priceDict: [String: [PricePoint]] = [:]
            for (ticker, task) in priceTasks {
                priceDict[ticker] = try await task.value
            }
            self.stockData = priceDict

            // 2. Determine the earliest common start date.
            let commonStart = self.earliestCommonDate(assets: assets)
            return commonStart ?? cpi.first?.date ?? Date()

        } catch let e as FinanceError {
            self.error = e
            throw e
        } catch {
            let wrapped = FinanceError.networkError(underlying: error)
            self.error = wrapped
            throw wrapped
        }
    }

    // MARK: - Date Range Resolution

    /// Find the latest "first date" across all assets and CPI.
    /// This ensures every series has data from this point forward.
    func earliestCommonDate(assets: [Asset]) -> Date? {
        var startDates: [Date] = []

        // CPI start
        if let first = cpiData.first?.date {
            startDates.append(first)
        }

        // Each equity's first price date
        for asset in assets where asset.kind == .equity {
            if let first = stockData[asset.id]?.first?.date {
                startDates.append(first)
            }
        }

        // The common start is the LATEST of all first dates
        return startDates.max()
    }

    /// Find the earliest "last date" across all assets.
    func latestCommonDate(assets: [Asset]) -> Date? {
        var endDates: [Date] = []

        if let last = cpiData.last?.date {
            endDates.append(last)
        }

        for asset in assets where asset.kind == .equity {
            if let last = stockData[asset.id]?.last?.date {
                endDates.append(last)
            }
        }

        // The common end is the EARLIEST of all last dates
        return endDates.min()
    }

    // MARK: - Data Accessors

    /// Get price data for an equity, trimmed to a date range.
    func prices(for ticker: String, from start: Date, to end: Date) -> [PricePoint] {
        (stockData[ticker] ?? []).trimmed(from: start, to: end)
    }

    /// Get CPI data trimmed to a date range.
    func cpi(from start: Date, to end: Date) -> [CPIDataPoint] {
        cpiData.trimmed(from: start, to: end)
    }
}
