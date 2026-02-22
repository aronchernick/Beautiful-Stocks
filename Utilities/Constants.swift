import Foundation

// MARK: - API Configuration

/// Central place for API keys and endpoints.
/// In production, load these from a .plist or environment variable.
enum APIConfig {
    // FRED (Federal Reserve Economic Data)
    static var fredAPIKey: String {
        // Replace with your key or load from Info.plist
        ProcessInfo.processInfo.environment["FRED_API_KEY"] ?? "YOUR_FRED_API_KEY"
    }
    static let fredBaseURL = "https://api.stlouisfed.org/fred/series/observations"
    static let cpiSeriesID = "CPIAUCSL" // Consumer Price Index for All Urban Consumers

    // Financial Modeling Prep (stock prices + dividends)
    static var fmpAPIKey: String {
        ProcessInfo.processInfo.environment["FMP_API_KEY"] ?? "YOUR_FMP_API_KEY"
    }
    static let fmpBaseURL = "https://financialmodelingprep.com/api/v3"
}

// MARK: - Shared Formatters

enum DateFormatters {
    /// FRED returns dates as "YYYY-MM-DD"
    static let iso: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    static let yearOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f
    }()

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
}

// MARK: - Custom Errors

enum FinanceError: LocalizedError {
    case invalidURL
    case networkError(underlying: Error)
    case decodingError(underlying: Error)
    case noData
    case apiError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:                 return "Invalid URL."
        case .networkError(let e):        return "Network error: \(e.localizedDescription)"
        case .decodingError(let e):       return "Decoding error: \(e.localizedDescription)"
        case .noData:                     return "No data returned from the server."
        case .apiError(let msg):          return "API error: \(msg)"
        }
    }
}
