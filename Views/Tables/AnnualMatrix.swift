import SwiftUI

// MARK: - Annual Returns Matrix

/// Year-by-year grid with Green for positive real returns, Red for negative.
/// Scrollable both horizontally (years) and vertically (assets).
struct AnnualMatrix: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.appTheme) private var theme

    private let cellWidth: CGFloat = 60
    private let cellHeight: CGFloat = 32
    private let labelWidth: CGFloat = 60

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Annual Returns")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            if vm.allYears.isEmpty {
                Text("No data")
                    .foregroundStyle(theme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 2) {
                        // Header: asset labels + years
                        headerRow

                        // One row per asset
                        ForEach(vm.settings.selectedAssets) { asset in
                            assetRow(asset)
                        }
                    }
                }
            }
        }
        .padding()
        .background(theme.surface.cornerRadius(12))
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: 2) {
            Text("Asset")
                .frame(width: labelWidth, alignment: .leading)
                .font(.caption2.bold())
                .foregroundStyle(theme.textSecondary)

            ForEach(vm.allYears, id: \.self) { year in
                Text(String(year))
                    .frame(width: cellWidth)
                    .font(.caption2.bold())
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    // MARK: - Asset Row

    private func assetRow(_ asset: Asset) -> some View {
        HStack(spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(vm.colorForAsset(asset.id))
                    .frame(width: 6, height: 6)
                Text(asset.id)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(theme.textPrimary)
            }
            .frame(width: labelWidth, alignment: .leading)

            ForEach(vm.allYears, id: \.self) { year in
                annualCell(assetID: asset.id, year: year)
            }
        }
    }

    // MARK: - Annual Cell

    private func annualCell(assetID: String, year: Int) -> some View {
        let entry = vm.annualReturns.first { $0.assetID == assetID && $0.year == year }
        let returnVal = entry?.realReturn

        return Group {
            if let r = returnVal {
                Text(String(format: "%.1f%%", r * 100))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: cellWidth, height: cellHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(r >= 0 ? theme.positiveColor.opacity(cellOpacity(for: r))
                                         : theme.negativeColor.opacity(cellOpacity(for: r)))
                    )
            } else {
                Text("—")
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: cellWidth, height: cellHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.gridLine.opacity(0.3))
                    )
            }
        }
    }

    /// Vary opacity based on magnitude for visual weight.
    private func cellOpacity(for value: Double) -> Double {
        let magnitude = min(abs(value), 0.5)  // cap at 50%
        return 0.3 + (magnitude / 0.5) * 0.7  // range 0.3 to 1.0
    }
}
