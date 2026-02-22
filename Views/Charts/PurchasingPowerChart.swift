import SwiftUI
import Charts

// MARK: - Purchasing Power Chart (Main Graph)

/// LineMark chart showing growth of $1 (or $10k) over time for all assets.
/// Supports haptic-feedback scrubbing via drag gesture.
struct PurchasingPowerChart: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title + scrub readout
            headerView

            // Chart
            Chart {
                ForEach(vm.returnSeries) { series in
                    ForEach(series.dataPoints) { point in
                        let yValue = vm.settings.inflationAdjusted
                            ? point.realGrowth
                            : point.nominalGrowth
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Growth", yValue * vm.settings.initialInvestment)
                        )
                        .foregroundStyle(series.color)
                        .lineStyle(StrokeStyle(lineWidth: series.asset.kind == .currency ? 1.5 : 2.0,
                                               dash: series.asset.kind == .currency ? [5, 3] : []))
                    }
                }

                // Scrub rule line
                if let scrubDate = vm.scrubDate {
                    RuleMark(x: .value("Scrub", scrubDate))
                        .foregroundStyle(theme.textSecondary.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(theme.gridLine)
                    AxisValueLabel()
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(theme.gridLine)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v.currencyFormatted)
                                .foregroundStyle(theme.textSecondary)
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                ScrubOverlay(proxy: proxy)
            }
            .frame(height: 280)
        }
        .padding()
        .background(theme.surface.cornerRadius(12))
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vm.settings.inflationAdjusted ? "Purchasing Power Over Time" : "Growth Over Time")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            if let scrubDate = vm.scrubDate {
                HStack(spacing: 12) {
                    Text(DateFormatters.shortDate.string(from: scrubDate))
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)

                    ForEach(vm.returnSeries) { series in
                        if let point = vm.scrubValue(for: series.id) {
                            let value = (vm.settings.inflationAdjusted ? point.realGrowth : point.nominalGrowth)
                                * vm.settings.initialInvestment
                            HStack(spacing: 3) {
                                Circle().fill(series.color).frame(width: 6, height: 6)
                                Text(value.currencyFormatted)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(theme.textPrimary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Scrub Overlay (Gesture Handler)

/// Transparent overlay that handles drag gestures for chart scrubbing.
private struct ScrubOverlay: View {
    let proxy: ChartProxy
    @EnvironmentObject private var vm: PortfolioViewModel

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let x = value.location.x - geo[proxy.plotAreaFrame].origin.x
                            if let date: Date = proxy.value(atX: x) {
                                if vm.scrubDate != date {
                                    vm.scrubDate = date
                                    HapticEngine.selectionChanged()
                                }
                            }
                        }
                        .onEnded { _ in
                            vm.scrubDate = nil
                        }
                )
        }
    }
}

// MARK: - Haptic Engine

enum HapticEngine {
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    static func selectionChanged() {
        selectionGenerator.selectionChanged()
    }

    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
