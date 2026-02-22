import SwiftUI

// MARK: - Main Content View

/// Root scrollable view that composes all sections:
/// controls, charts, and data tables.
struct ContentView: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.appTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // App header
                headerSection

                // Toggle controls (Inflation, Dividends, Dark Mode)
                ToggleControls()

                // Asset picker
                AssetPicker()

                // Date range
                DateRangeSelector()

                if vm.isLoading {
                    loadingView
                } else if let error = vm.errorMessage {
                    errorView(error)
                } else if !vm.returnSeries.isEmpty {
                    // Charts
                    PurchasingPowerChart()
                    DrawdownChart()

                    // Tables
                    SummaryTable()
                    GrowthTable()
                    DrawdownTable()
                    AnnualMatrix()

                    Spacer(minLength: 40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(theme.background.ignoresSafeArea())
        .task {
            await vm.loadPortfolio()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Beautiful Stocks")
                    .font(.title2.bold())
                    .foregroundStyle(theme.primaryAccent)
                Text("Total Real Returns Explorer")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(theme.primaryAccent)
                .scaleEffect(1.5)
            Text("Fetching market data…")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(theme.negativeColor)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await vm.loadPortfolio() }
            }
            .font(.subheadline.bold())
            .foregroundStyle(theme.primaryAccent)
        }
        .padding(24)
        .background(theme.surface.cornerRadius(12))
    }
}
