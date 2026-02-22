import Foundation

// MARK: - CPI Interpolator

/// Interpolates monthly CPI values to daily granularity so that
/// inflation adjustments don't "jump" on the first of each month.
///
/// Uses linear interpolation between consecutive monthly readings.
/// Extrapolates flat for dates beyond the last known CPI.
enum CPIInterpolator {

    /// Build a lookup function that returns the interpolated CPI for any date.
    /// - Parameter monthlyCPI: Sorted array of monthly CPI observations.
    /// - Returns: A closure  `(Date) -> Double`  that gives the CPI value for any date.
    static func makeInterpolator(from monthlyCPI: [CPIDataPoint]) -> (Date) -> Double {
        guard monthlyCPI.count >= 2 else {
            let fallback = monthlyCPI.first?.value ?? 100.0
            return { _ in fallback }
        }

        // Pre-compute a sorted array of (timeInterval, cpiValue) for binary search.
        let entries: [(ti: TimeInterval, value: Double)] = monthlyCPI.map {
            ($0.date.timeIntervalSinceReferenceDate, $0.value)
        }

        return { date in
            let t = date.timeIntervalSinceReferenceDate

            // Before first observation → use first value
            guard t >= entries.first!.ti else { return entries.first!.value }
            // After last observation → use last value
            guard t <= entries.last!.ti else { return entries.last!.value }

            // Binary search for the bracketing pair
            var lo = 0, hi = entries.count - 1
            while lo < hi - 1 {
                let mid = (lo + hi) / 2
                if entries[mid].ti <= t {
                    lo = mid
                } else {
                    hi = mid
                }
            }

            let left = entries[lo]
            let right = entries[hi]

            // Edge case: exactly on a known date
            if left.ti == t { return left.value }
            if right.ti == t { return right.value }

            // Linear interpolation
            let fraction = (t - left.ti) / (right.ti - left.ti)
            return left.value + fraction * (right.value - left.value)
        }
    }

    /// Convenience: compute the CPI factor to adjust a nominal value.
    /// factor = CPI(baseDate) / CPI(targetDate)
    /// Multiply a nominal value by this factor to convert to "base-date dollars."
    static func realFactor(
        baseDate: Date,
        targetDate: Date,
        interpolator: (Date) -> Double
    ) -> Double {
        let baseCPI = interpolator(baseDate)
        let targetCPI = interpolator(targetDate)
        guard targetCPI > 0 else { return 1.0 }
        return baseCPI / targetCPI
    }
}
