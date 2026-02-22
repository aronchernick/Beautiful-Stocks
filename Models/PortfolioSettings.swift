import Foundation

// MARK: - Portfolio-Level Settings

/// Tracks user-configurable state for the portfolio view.
struct PortfolioSettings {
    var selectedAssets: [Asset] = Asset.defaultBasket
    var inflationAdjusted: Bool = true
    var dividendsReinvested: Bool = true
    var startDate: Date? = nil   // nil = earliest common date
    var endDate: Date? = nil     // nil = today
    var initialInvestment: Double = 10_000
}
