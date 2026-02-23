import Foundation
import SwiftUI

// MARK: - Return Calculator

/// Pure-function calculator.  No side effects, no network calls.
/// Takes raw data in, produces computed return series and summaries out.
enum ReturnCalculator {

    // MARK: - Core: Growth Series

    /// Compute a full return series for a single equity asset.
    ///
    /// - Parameters:
    ///   - prices: Chronologically sorted daily price points.
    ///   - cpiInterpolator: Function that returns interpolated CPI for any date.
    ///   - dividendsReinvested: If true, uses adjustedClose (which accounts for
    ///     dividend reinvestment and splits). If false, uses raw close.
    ///   - inflationAdjusted: If true, deflates values by the CPI factor.
    ///   - baseDate: The reference date for inflation adjustment (start of the series).
    /// - Returns: Array of `ReturnDataPoint` representing growth of $1.
    static func computeEquitySeries(
        prices: [PricePoint],
        cpiInterpolator: @escaping (Date) -> Double,
        dividendsReinvested: Bool,
        inflationAdjusted: Bool,
        baseDate: Date
    ) -> [ReturnDataPoint] {
        guard let first = prices.first else { return [] }

        let startPrice = dividendsReinvested ? first.adjustedClose : first.close
        guard startPrice > 0 else { return [] }

        var nominalPeak: Double = 1.0
        var realPeak: Double = 1.0

        return prices.map { point in
            let price = dividendsReinvested ? point.adjustedClose : point.close
            let nominalGrowth = price / startPrice

            let realGrowth: Double
            if inflationAdjusted {
                let factor = CPIInterpolator.realFactor(
                    baseDate: baseDate,
                    targetDate: point.date,
                    interpolator: cpiInterpolator
                )
                realGrowth = nominalGrowth * factor
            } else {
                realGrowth = nominalGrowth
            }

            // Track peaks for drawdown
            nominalPeak = max(nominalPeak, nominalGrowth)
            realPeak = max(realPeak, realGrowth)

            let displayGrowth = inflationAdjusted ? realGrowth : nominalGrowth
            let peak = inflationAdjusted ? realPeak : nominalPeak
            let drawdown = peak > 0 ? (displayGrowth - peak) / peak : 0

            return ReturnDataPoint(
                date: point.date,
                nominalGrowth: nominalGrowth,
                realGrowth: realGrowth,
                drawdownFromPeak: drawdown
            )
        }
    }

    // MARK: - USD Baseline Series

    /// The USD "asset" — always $1 nominally, but purchasing power decreases.
    /// When inflation adjusted, shows the declining value of $1 over time.
    static func computeUSDSeries(
        dates: [Date],
        cpiInterpolator: @escaping (Date) -> Double,
        inflationAdjusted: Bool,
        baseDate: Date
    ) -> [ReturnDataPoint] {
        guard !dates.isEmpty else { return [] }

        var realPeak: Double = 1.0

        return dates.map { date in
            let nominalGrowth = 1.0  // USD is always $1 nominally

            let realGrowth: Double
            if inflationAdjusted {
                let factor = CPIInterpolator.realFactor(
                    baseDate: baseDate,
                    targetDate: date,
                    interpolator: cpiInterpolator
                )
                realGrowth = nominalGrowth * factor
            } else {
                realGrowth = 1.0
            }

            let displayGrowth = inflationAdjusted ? realGrowth : nominalGrowth
            realPeak = max(realPeak, displayGrowth)
            let drawdown = realPeak > 0 ? (displayGrowth - realPeak) / realPeak : 0

            return ReturnDataPoint(
                date: date,
                nominalGrowth: nominalGrowth,
                realGrowth: realGrowth,
                drawdownFromPeak: drawdown
            )
        }
    }

    // MARK: - Annual Returns Matrix

    /// Compute year-by-year returns (real or nominal) from a return series.
    static func annualReturns(
        assetID: String,
        series: [ReturnDataPoint],
        inflationAdjusted: Bool
    ) -> [AnnualReturn] {
        guard series.count >= 2 else { return [] }

        // Group by year
        let byYear = Dictionary(grouping: series) { $0.date.year }
        let sortedYears = byYear.keys.sorted()

        var results: [AnnualReturn] = []

        for year in sortedYears {
            guard let yearPoints = byYear[year],
                  let firstOfYear = yearPoints.first,
                  let lastOfYear = yearPoints.last else { continue }

            let startVal = inflationAdjusted ? firstOfYear.realGrowth : firstOfYear.nominalGrowth
            let endVal = inflationAdjusted ? lastOfYear.realGrowth : lastOfYear.nominalGrowth

            guard startVal > 0 else { continue }
            let yearReturn = (endVal / startVal) - 1.0

            results.append(AnnualReturn(assetID: assetID, year: year, realReturn: yearReturn))
        }

        return results
    }

    // MARK: - Summary Statistics

    /// Compute summary statistics for one asset.
    static func computeSummary(
        asset: Asset,
        series: [ReturnDataPoint],
        inflationAdjusted: Bool,
        initialInvestment: Double,
        color: SwiftUI.Color
    ) -> AssetSummary? {
        guard let first = series.first, let last = series.last else { return nil }

        let startVal = inflationAdjusted ? first.realGrowth : first.nominalGrowth
        let endVal = inflationAdjusted ? last.realGrowth : last.nominalGrowth

        let overallReturn = startVal > 0 ? (endVal / startVal) - 1.0 : 0

        // Drawdown stats
        let drawdowns = series.map(\.drawdownFromPeak)
        let currentDrawdown = drawdowns.last ?? 0
        let maxDrawdown = drawdowns.min() ?? 0

        // Trendline
        let growthValues = series.map { inflationAdjusted ? $0.realGrowth : $0.nominalGrowth }
        let dates = series.map(\.date)
        let trendline = TrendlineCalculator.exponentialFit(dates: dates, values: growthValues)

        return AssetSummary(
            id: asset.id,
            asset: asset,
            color: color,
            overallReturn: overallReturn,
            trendlineSlope: trendline?.annualizedRate ?? 0,
            rSquared: trendline?.rSquared ?? 0,
            initialValue: initialInvestment,
            finalValue: initialInvestment * (1.0 + overallReturn),
            currentDrawdown: currentDrawdown,
            maxDrawdown: maxDrawdown
        )
    }
}
