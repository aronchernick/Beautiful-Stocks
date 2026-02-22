import Foundation

// MARK: - Date Helpers

extension Date {
    /// Days elapsed since a reference date (for trendline x-axis).
    func daysSince(_ reference: Date) -> Double {
        timeIntervalSince(reference) / 86_400
    }

    /// Start of the month (day 1) in UTC.
    var startOfMonth: Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.year, .month], from: self)
        return cal.date(from: comps)!
    }

    var year: Int {
        Calendar(identifier: .gregorian).component(.year, from: self)
    }
}

// MARK: - Double Formatting

extension Double {
    /// Format as percentage string, e.g. 0.1234 -> "+12.34%"
    var percentFormatted: String {
        let pct = self * 100
        let sign = pct >= 0 ? "+" : ""
        return String(format: "\(sign)%.2f%%", pct)
    }

    /// Format as currency string, e.g. 12345.67 -> "$12,345.67"
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }
}

// MARK: - Array Helpers

extension Array where Element == PricePoint {
    /// Trim the array to only dates within the given range (inclusive).
    func trimmed(from start: Date, to end: Date) -> [PricePoint] {
        filter { $0.date >= start && $0.date <= end }
    }
}

extension Array where Element == CPIDataPoint {
    /// Trim CPI data to a date range.
    func trimmed(from start: Date, to end: Date) -> [CPIDataPoint] {
        filter { $0.date >= start && $0.date <= end }
    }
}
