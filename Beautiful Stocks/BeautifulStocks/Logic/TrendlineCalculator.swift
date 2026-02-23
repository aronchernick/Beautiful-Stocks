import Foundation

// MARK: - Exponential Trendline Calculator

/// Fits y = a·e^(bx) to time-series data using OLS on ln(y).
enum TrendlineCalculator {

    /// Fit an exponential trendline to price/growth data.
    ///
    /// Method: take ln(y) and perform linear regression  ln(y) = ln(a) + b·x
    /// where x is days since the first date.
    ///
    /// - Parameters:
    ///   - dates: Sorted array of dates (same count as values).
    ///   - values: Positive y-values (e.g., growth of $1).
    /// - Returns: `TrendlineResult` or nil if the fit fails.
    static func exponentialFit(dates: [Date], values: [Double]) -> TrendlineResult? {
        guard dates.count == values.count, dates.count >= 2 else { return nil }

        let baseDate = dates[0]

        // Build x (days since start) and lnY arrays, skipping non-positive values.
        var xs: [Double] = []
        var lnYs: [Double] = []

        for i in 0..<dates.count {
            guard values[i] > 0 else { continue }
            xs.append(dates[i].daysSince(baseDate))
            lnYs.append(log(values[i]))
        }

        let n = Double(xs.count)
        guard n >= 2 else { return nil }

        // Simple OLS for ln(y) = alpha + beta * x
        let sumX   = xs.reduce(0, +)
        let sumY   = lnYs.reduce(0, +)
        let sumXY  = zip(xs, lnYs).reduce(0.0) { $0 + $1.0 * $1.1 }
        let sumX2  = xs.reduce(0.0) { $0 + $1 * $1 }

        let denom = n * sumX2 - sumX * sumX
        guard abs(denom) > 1e-15 else { return nil }

        let beta  = (n * sumXY - sumX * sumY) / denom   // slope in log-space
        let alpha = (sumY - beta * sumX) / n             // intercept in log-space

        let a = exp(alpha)  // coefficient
        let b = beta        // exponent rate (per day)

        // R² calculation
        let meanLnY = sumY / n
        let ssTot = lnYs.reduce(0.0) { $0 + ($1 - meanLnY) * ($1 - meanLnY) }
        let ssRes = zip(xs, lnYs).reduce(0.0) { total, pair in
            let predicted = alpha + beta * pair.0
            let residual = pair.1 - predicted
            return total + residual * residual
        }
        let rSquared = ssTot > 0 ? 1.0 - ssRes / ssTot : 0

        // Annualized rate: e^(b*365.25) - 1
        let annualizedRate = exp(b * 365.25) - 1.0

        return TrendlineResult(
            a: a,
            b: b,
            rSquared: rSquared,
            annualizedRate: annualizedRate
        )
    }

    /// Generate trendline data points for charting.
    static func trendlinePoints(
        result: TrendlineResult,
        dates: [Date]
    ) -> [(date: Date, value: Double)] {
        guard let baseDate = dates.first else { return [] }
        return dates.map { date in
            let x = date.daysSince(baseDate)
            return (date: date, value: result.evaluate(at: x))
        }
    }
}

// MARK: - Drawdown Calculator

enum DrawdownCalculator {

    /// Compute drawdown series from a growth series.
    /// Each value is 0 (at peak) to -1 (100% loss from peak).
    static func drawdownSeries(from growthValues: [Double]) -> [Double] {
        var peak = 0.0
        return growthValues.map { value in
            peak = max(peak, value)
            guard peak > 0 else { return 0 }
            return (value - peak) / peak
        }
    }

    /// Maximum drawdown (most negative value).
    static func maxDrawdown(from growthValues: [Double]) -> Double {
        drawdownSeries(from: growthValues).min() ?? 0
    }

    /// Current drawdown (last value).
    static func currentDrawdown(from growthValues: [Double]) -> Double {
        drawdownSeries(from: growthValues).last ?? 0
    }
}
