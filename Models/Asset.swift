import Foundation
import SwiftUI

// MARK: - Asset Identification

/// Represents a financial asset that can be tracked in the portfolio.
/// Assets are either equities (stocks/funds) or the USD baseline.
struct Asset: Identifiable, Hashable, Codable {
    let id: String          // Ticker symbol or "USD"
    let displayName: String
    let kind: Kind

    enum Kind: String, Codable, Hashable {
        case equity     // Stocks, ETFs, Mutual Funds
        case currency   // USD baseline
    }

    // The three default-basket assets
    static let usd   = Asset(id: "USD",   displayName: "US Dollar",               kind: .currency)
    static let vfinx = Asset(id: "VFINX", displayName: "Vanguard 500 Index Fund",  kind: .equity)
    static let vbmfx = Asset(id: "VBMFX", displayName: "Vanguard Total Bond Mkt",  kind: .equity)

    static let defaultBasket: [Asset] = [.usd, .vbmfx, .vfinx]
}

// MARK: - Price Point

/// A single dated price observation, optionally carrying a dividend amount.
struct PricePoint: Identifiable, Codable {
    var id: Date { date }
    let date: Date
    let close: Double
    let adjustedClose: Double   // Accounts for splits + dividends
    let dividend: Double        // Cash dividend on this date (0 if none)
}

// MARK: - CPI Data Point

/// Monthly CPI observation from FRED (series CPIAUCSL).
struct CPIDataPoint: Identifiable, Codable {
    var id: Date { date }
    let date: Date    // First day of the month
    let value: Double // CPI index value
}

// MARK: - Computed Result Types

/// Holds a full time-series of computed return data for one asset.
struct AssetReturnSeries: Identifiable {
    let id: String // asset id
    let asset: Asset
    let dataPoints: [ReturnDataPoint]
    let color: Color
}

/// A single day's computed return values for one asset.
struct ReturnDataPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let nominalGrowth: Double        // Growth of $1 (nominal)
    let realGrowth: Double           // Growth of $1 (inflation-adjusted)
    let drawdownFromPeak: Double     // 0 to -1 (percentage below peak)
}

// MARK: - Trendline Result

struct TrendlineResult {
    let a: Double          // y = a·e^(bx)
    let b: Double
    let rSquared: Double   // Goodness of fit
    let annualizedRate: Double // human-readable CAGR from the slope

    /// Evaluate the trendline at a given x (days since start).
    func evaluate(at x: Double) -> Double {
        a * exp(b * x)
    }
}

// MARK: - Summary Row (for tables)

struct AssetSummary: Identifiable {
    let id: String
    let asset: Asset
    let color: Color
    let overallReturn: Double        // e.g. 1.45 = +145%
    let trendlineSlope: Double       // annualized rate from exp trendline
    let rSquared: Double
    let initialValue: Double         // e.g. 10_000
    let finalValue: Double
    let currentDrawdown: Double      // 0 to -1
    let maxDrawdown: Double          // 0 to -1
}

// MARK: - Annual Return Cell

struct AnnualReturn: Identifiable {
    var id: String { "\(assetID)-\(year)" }
    let assetID: String
    let year: Int
    let realReturn: Double  // e.g. 0.12 = +12%
}
