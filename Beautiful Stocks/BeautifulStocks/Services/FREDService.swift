import Foundation

// MARK: - Service Protocols

/// Fetches monthly CPI data from FRED.
protocol CPIDataProvider {
    func fetchCPI(startDate: Date?, endDate: Date?) async throws -> [CPIDataPoint]
}

/// Fetches historical stock prices (with adjusted close and dividends).
protocol StockPriceProvider {
    func fetchDailyPrices(ticker: String, startDate: Date?, endDate: Date?) async throws -> [PricePoint]
}

// MARK: - FRED CPI Service

/// Concrete implementation that talks to the FRED API.
final class FREDService: CPIDataProvider {

    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String = APIConfig.fredAPIKey) {
        self.session = session
        self.apiKey = apiKey
    }

    func fetchCPI(startDate: Date? = nil, endDate: Date? = nil) async throws -> [CPIDataPoint] {
        var components = URLComponents(string: APIConfig.fredBaseURL)!
        var queryItems: [URLQueryItem] = [
            .init(name: "series_id",  value: APIConfig.cpiSeriesID),
            .init(name: "api_key",    value: apiKey),
            .init(name: "file_type",  value: "json"),
            .init(name: "sort_order", value: "asc"),
        ]
        if let start = startDate {
            queryItems.append(.init(name: "observation_start", value: DateFormatters.iso.string(from: start)))
        }
        if let end = endDate {
            queryItems.append(.init(name: "observation_end", value: DateFormatters.iso.string(from: end)))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw FinanceError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw FinanceError.apiError(message: "FRED returned status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        let decoded = try JSONDecoder().decode(FREDResponse.self, from: data)
        return decoded.observations.compactMap { obs -> CPIDataPoint? in
            guard let date = DateFormatters.iso.date(from: obs.date),
                  let value = Double(obs.value), value > 0 else { return nil }
            return CPIDataPoint(date: date, value: value)
        }
    }
}

// MARK: - FRED JSON Shapes

private struct FREDResponse: Decodable {
    let observations: [FREDObservation]
}

private struct FREDObservation: Decodable {
    let date: String
    let value: String
}
