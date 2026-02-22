import SwiftUI
import Combine

// MARK: - Portfolio View Model

/// The main view model that orchestrates data loading, calculation,
/// and produces all display-ready data for the views.
@MainActor
final class PortfolioViewModel: ObservableObject {

    // MARK: - Published State

    @Published var settings = PortfolioSettings()
    @Published var isDarkMode = true

    // Computed display data
    @Published private(set) var returnSeries: [AssetReturnSeries] = []
    @Published private(set) var summaries: [AssetSummary] = []
    @Published private(set) var annualReturns: [AnnualReturn] = []
    @Published private(set) var allYears: [Int] = []

    // Resolved date range
    @Published private(set) var resolvedStartDate: Date = Date()
    @Published private(set) var resolvedEndDate: Date = Date()

    // Loading / error
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // Scrub state (shared across charts)
    @Published var scrubDate: Date?

    // MARK: - Dependencies

    private let dataService: FinanceDataService
    private var colorMap: [String: Color] = [:]

    var currentTheme: AppTheme {
        isDarkMode ? .dark : .light
    }

    init(dataService: FinanceDataService = FinanceDataService()) {
        self.dataService = dataService
    }

    // MARK: - Load & Compute

    func loadPortfolio() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Fetch all raw data
            let commonStart = try await dataService.loadData(for: settings.selectedAssets)

            // 2. Resolve date range
            let start = settings.startDate ?? commonStart
            let end = settings.endDate ?? (dataService.latestCommonDate(assets: settings.selectedAssets) ?? Date())
            resolvedStartDate = start
            resolvedEndDate = end

            // 3. Assign colors
            colorMap = AssetColorProvider.assignColors(to: settings.selectedAssets)

            // 4. Build interpolated CPI
            let cpiData = dataService.cpi(from: start, to: end)
            let cpiInterpolator = CPIInterpolator.makeInterpolator(from: cpiData)

            // 5. Compute return series for each asset
            var series: [AssetReturnSeries] = []
            var summaryList: [AssetSummary] = []
            var annualList: [AnnualReturn] = []

            // Collect all dates from the first equity for the USD baseline
            var allDates: [Date] = []

            for asset in settings.selectedAssets {
                let color = colorMap[asset.id] ?? .gray

                let dataPoints: [ReturnDataPoint]

                switch asset.kind {
                case .equity:
                    let prices = dataService.prices(for: asset.id, from: start, to: end)
                    dataPoints = ReturnCalculator.computeEquitySeries(
                        prices: prices,
                        cpiInterpolator: cpiInterpolator,
                        dividendsReinvested: settings.dividendsReinvested,
                        inflationAdjusted: settings.inflationAdjusted,
                        baseDate: start
                    )
                    if allDates.isEmpty {
                        allDates = prices.map(\.date)
                    }

                case .currency:
                    // USD uses dates from the first equity
                    // (will be filled after the loop if needed)
                    dataPoints = [] // placeholder
                }

                if asset.kind == .equity {
                    let s = AssetReturnSeries(id: asset.id, asset: asset, dataPoints: dataPoints, color: color)
                    series.append(s)

                    // Summary
                    if let summary = ReturnCalculator.computeSummary(
                        asset: asset,
                        series: dataPoints,
                        inflationAdjusted: settings.inflationAdjusted,
                        initialInvestment: settings.initialInvestment,
                        color: color
                    ) {
                        summaryList.append(summary)
                    }

                    // Annual returns
                    let annual = ReturnCalculator.annualReturns(
                        assetID: asset.id,
                        series: dataPoints,
                        inflationAdjusted: settings.inflationAdjusted
                    )
                    annualList.append(contentsOf: annual)
                }
            }

            // Now compute USD using the collected dates
            if let usdAsset = settings.selectedAssets.first(where: { $0.kind == .currency }) {
                let color = colorMap[usdAsset.id] ?? .gray
                let usdPoints = ReturnCalculator.computeUSDSeries(
                    dates: allDates,
                    cpiInterpolator: cpiInterpolator,
                    inflationAdjusted: settings.inflationAdjusted,
                    baseDate: start
                )
                let usdSeries = AssetReturnSeries(id: usdAsset.id, asset: usdAsset, dataPoints: usdPoints, color: color)
                series.insert(usdSeries, at: 0)

                if let summary = ReturnCalculator.computeSummary(
                    asset: usdAsset,
                    series: usdPoints,
                    inflationAdjusted: settings.inflationAdjusted,
                    initialInvestment: settings.initialInvestment,
                    color: color
                ) {
                    summaryList.insert(summary, at: 0)
                }

                let annual = ReturnCalculator.annualReturns(
                    assetID: usdAsset.id,
                    series: usdPoints,
                    inflationAdjusted: settings.inflationAdjusted
                )
                annualList.append(contentsOf: annual)
            }

            // 6. Publish results
            self.returnSeries = series
            self.summaries = summaryList
            self.annualReturns = annualList
            self.allYears = Array(Set(annualList.map(\.year))).sorted()

        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Scrub Helpers

    /// Get the interpolated value at the scrub date for a given series.
    func scrubValue(for seriesID: String) -> ReturnDataPoint? {
        guard let date = scrubDate,
              let series = returnSeries.first(where: { $0.id == seriesID }) else { return nil }
        // Find the closest data point at or before the scrub date
        return series.dataPoints.last(where: { $0.date <= date })
    }

    // MARK: - Asset Management

    func addAsset(_ asset: Asset) {
        guard !settings.selectedAssets.contains(asset) else { return }
        settings.selectedAssets.append(asset)
    }

    func removeAsset(_ asset: Asset) {
        settings.selectedAssets.removeAll { $0.id == asset.id }
    }

    func colorForAsset(_ assetID: String) -> Color {
        colorMap[assetID] ?? .gray
    }
}
