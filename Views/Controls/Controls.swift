import SwiftUI

// MARK: - Toggle Controls

/// Inflation Adjusted / Dividends Reinvested toggles + Dark Mode switch.
struct ToggleControls: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                togglePill(
                    label: "Inflation Adjusted",
                    isOn: $vm.settings.inflationAdjusted,
                    icon: "chart.line.downtrend.xyaxis"
                )

                togglePill(
                    label: "Dividends Reinvested",
                    isOn: $vm.settings.dividendsReinvested,
                    icon: "arrow.triangle.2.circlepath"
                )
            }

            HStack {
                // Dark mode toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        vm.isDarkMode.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: vm.isDarkMode ? "moon.fill" : "sun.max.fill")
                        Text(vm.isDarkMode ? "Dark" : "Light")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(theme.primaryAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.primaryAccent.opacity(0.15).cornerRadius(8))
                }

                Spacer()
            }
        }
    }

    private func togglePill(label: String, isOn: Binding<Bool>, icon: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.wrappedValue.toggle()
            }
            HapticEngine.impact(style: .light)
            // Re-compute when toggled
            Task { await vm.loadPortfolio() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(isOn.wrappedValue ? theme.background : theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isOn.wrappedValue ? theme.primaryAccent : theme.gridLine)
            )
        }
    }
}

// MARK: - Date Range Selector

/// Start date and end date pickers (no 1Y/5Y buttons).
struct DateRangeSelector: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("FROM")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.textSecondary)
                DatePicker(
                    "",
                    selection: Binding(
                        get: { vm.settings.startDate ?? vm.resolvedStartDate },
                        set: { vm.settings.startDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(theme.primaryAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("TO")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.textSecondary)
                DatePicker(
                    "",
                    selection: Binding(
                        get: { vm.settings.endDate ?? vm.resolvedEndDate },
                        set: { vm.settings.endDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(theme.primaryAccent)
            }

            Spacer()

            // Apply button
            Button {
                Task { await vm.loadPortfolio() }
            } label: {
                Text("Apply")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.background)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(theme.primaryAccent.cornerRadius(8))
            }
        }
        .padding()
        .background(theme.surface.cornerRadius(12))
    }
}

// MARK: - Asset Picker

/// Simple asset add/remove interface.
struct AssetPicker: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.appTheme) private var theme
    @State private var newTicker = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Assets")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            // Current assets as removable chips
            FlowLayout(spacing: 8) {
                ForEach(vm.settings.selectedAssets) { asset in
                    assetChip(asset)
                }
            }

            // Add new ticker
            HStack {
                TextField("Add ticker (e.g. AAPL)", text: $newTicker)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(theme.textPrimary)
                    .padding(8)
                    .background(theme.gridLine.opacity(0.5).cornerRadius(8))
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .onSubmit { addTicker() }

                Button(action: addTicker) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(theme.primaryAccent)
                        .font(.title3)
                }
                .disabled(newTicker.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .background(theme.surface.cornerRadius(12))
    }

    private func assetChip(_ asset: Asset) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(vm.colorForAsset(asset.id))
                .frame(width: 8, height: 8)
            Text(asset.id)
                .font(.caption.weight(.medium))
                .foregroundStyle(theme.textPrimary)

            if asset.kind != .currency { // Don't allow removing USD
                Button {
                    vm.removeAsset(asset)
                    Task { await vm.loadPortfolio() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(theme.gridLine.opacity(0.5).cornerRadius(12))
    }

    private func addTicker() {
        let ticker = newTicker.trimmingCharacters(in: .whitespaces).uppercased()
        guard !ticker.isEmpty else { return }
        let asset = Asset(id: ticker, displayName: ticker, kind: .equity)
        vm.addAsset(asset)
        newTicker = ""
        isFocused = false
        Task { await vm.loadPortfolio() }
    }
}

// MARK: - Flow Layout (Horizontal Wrapping)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
