import Foundation

// MARK: - Financial Modeling Prep Service

/// Fetches historical daily prices + dividends from Financial Modeling Prep.
final class FMPStockService: StockPriceProvider {

    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String = APIConfig.fmpAPIKey) {
        self.session = session
        self.apiKey = apiKey
    }

    /// Fetch daily historical prices with adjusted close and dividends.
    func fetchDailyPrices(
        ticker: String,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> [PricePoint] {

        // FMP endpoint: /historical-price-full/{ticker}
        var components = URLComponents(string: "\(APIConfig.fmpBaseURL)/historical-price-full/\(ticker)")!
        var queryItems: [URLQueryItem] = [
            .init(name: "apikey", value: apiKey),
        ]
        if let start = startDate {
            queryItems.append(.init(name: "from", value: DateFormatters.iso.string(from: start)))
        }
        if let end = endDate {
            queryItems.append(.init(name: "to", value: DateFormatters.iso.string(from: end)))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw FinanceError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw FinanceError.apiError(message: "FMP returned status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        let decoded: FMPHistoricalResponse
        do {
            decoded = try JSONDecoder().decode(FMPHistoricalResponse.self, from: data)
        } catch {
            throw FinanceError.decodingError(underlying: error)
        }

        guard !decoded.historical.isEmpty else {
            throw FinanceError.noData
        }

        // FMP returns newest-first; we want chronological order.
        let sorted = decoded.historical.sorted { $0.date < $1.date }

        return sorted.compactMap { day -> PricePoint? in
            guard let date = DateFormatters.iso.date(from: day.date) else { return nil }
            return PricePoint(
                date: date,
                close: day.close,
                adjustedClose: day.adjClose ?? day.close,
                dividend: day.dividend ?? 0
            )
        }
    }
}

// MARK: - FMP Dividend History

extension FMPStockService {

    /// Fetch dividend history separately if needed for more accuracy.
    func fetchDividends(ticker: String) async throws -> [(date: Date, amount: Double)] {
        var components = URLComponents(string: "\(APIConfig.fmpBaseURL)/historical-price-full/stock_dividend/\(ticker)")!
        components.queryItems = [.init(name: "apikey", value: apiKey)]

        guard let url = components.url else { throw FinanceError.invalidURL }
        let (data, _) = try await session.data(from: url)

        let decoded = try JSONDecoder().decode(FMPDividendResponse.self, from: data)
        return decoded.historical.compactMap { entry in
            guard let date = DateFormatters.iso.date(from: entry.date) else { return nil }
            return (date: date, amount: entry.dividend)
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - FMP JSON Shapes

private struct FMPHistoricalResponse: Decodable {
    let symbol: String?
    let historical: [FMPDailyPrice]
}

private struct FMPDailyPrice: Decodable {
    let date: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let adjClose: Double?
    let volume: Double?
    let dividend: Double?

    enum CodingKeys: String, CodingKey {
        case date, open, high, low, close, volume
        case adjClose = "adjClose"
        case dividend
    }
}

private struct FMPDividendResponse: Decodable {
    let symbol: String
    let historical: [FMPDividendEntry]
}

private struct FMPDividendEntry: Decodable {
    let date: String
    let dividend: Double
}
