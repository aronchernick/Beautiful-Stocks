import SwiftUI

// MARK: - Summary Table

/// [Stock | Overall Return | Trendline CAGR | R²]
struct SummaryTable: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            // Header row
            HStack {
                Text("Asset").frame(maxWidth: .infinity, alignment: .leading)
                Text("Return").frame(width: 80, alignment: .trailing)
                Text("CAGR").frame(width: 70, alignment: .trailing)
                Text("R²").frame(width: 50, alignment: .trailing)
            }
            .font(.caption.bold())
            .foregroundStyle(theme.textSecondary)

            Divider().background(theme.gridLine)

            ForEach(vm.summaries) { summary in
                HStack {
                    // Asset name with color dot
                    HStack(spacing: 6) {
                        Circle().fill(summary.color).frame(width: 8, height: 8)
                        Text(summary.asset.id)
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Overall return
                    Text(summary.overallReturn.percentFormatted)
                        .frame(width: 80, alignment: .trailing)
                        .foregroundStyle(summary.overallReturn >= 0 ? theme.positiveColor : theme.negativeColor)

                    // Trendline CAGR
                    Text(summary.trendlineSlope.percentFormatted)
                        .frame(width: 70, alignment: .trailing)

                    // R²
                    Text(String(format: "%.3f", summary.rSquared))
                        .frame(width: 50, alignment: .trailing)
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(theme.textPrimary)
            }
        }
        .padding()
        .background(theme.surface.cornerRadius(12))
    }
}

// MARK: - Growth Table

/// [Stock | Initial ($10k) | Final Value]
struct GrowthTable: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Growth of \(vm.settings.initialInvestment.currencyFormatted)")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            // Header
            HStack {
                Text("Asset").frame(maxWidth: .infinity, alignment: .leading)
                Text("Initial").frame(width: 90, alignment: .trailing)
                Text("Final").frame(width: 90, alignment: .trailing)
            }
            .font(.caption.bold())
            .foregroundStyle(theme.textSecondary)

            Divider().background(theme.gridLine)

            ForEach(vm.summaries) { summary in
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(summary.color).frame(width: 8, height: 8)
                        Text(summary.asset.id)
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(summary.initialValue.currencyFormatted)
                        .frame(width: 90, alignment: .trailing)

                    Text(summary.finalValue.currencyFormatted)
                        .frame(width: 90, alignment: .trailing)
                        .foregroundStyle(summary.finalValue >= summary.initialValue
                                         ? theme.positiveColor : theme.negativeColor)
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(theme.textPrimary)
            }
        }
        .padding()
        .background(theme.surface.cornerRadius(12))
    }
}

// MARK: - Drawdown Table

/// [Stock | Current Drawdown | Max Drawdown]
struct DrawdownTable: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Drawdowns")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            HStack {
                Text("Asset").frame(maxWidth: .infinity, alignment: .leading)
                Text("Current").frame(width: 80, alignment: .trailing)
                Text("Max").frame(width: 80, alignment: .trailing)
            }
            .font(.caption.bold())
            .foregroundStyle(theme.textSecondary)

            Divider().background(theme.gridLine)

            ForEach(vm.summaries) { summary in
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(summary.color).frame(width: 8, height: 8)
                        Text(summary.asset.id)
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(summary.currentDrawdown.percentFormatted)
                        .frame(width: 80, alignment: .trailing)
                        .foregroundStyle(theme.negativeColor)

                    Text(summary.maxDrawdown.percentFormatted)
                        .frame(width: 80, alignment: .trailing)
                        .foregroundStyle(theme.negativeColor)
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(theme.textPrimary)
            }
        }
        .padding()
        .background(theme.surface.cornerRadius(12))
    }
}
