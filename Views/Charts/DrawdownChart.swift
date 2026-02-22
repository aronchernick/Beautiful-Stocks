import SwiftUI
import Charts

// MARK: - Drawdown Chart

/// Area chart showing percentage drawdown from previous all-time highs.
/// Mirrors the same color scheme and scrubbing behavior as the main chart.
struct DrawdownChart: View {
    @EnvironmentObject private var vm: PortfolioViewModel
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title + scrub readout
            headerView

            Chart {
                ForEach(vm.returnSeries) { series in
                    ForEach(series.dataPoints) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Drawdown", point.drawdownFromPeak * 100)
                        )
                        .foregroundStyle(
                            series.color.opacity(0.15)
                        )

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Drawdown", point.drawdownFromPeak * 100)
                        )
                        .foregroundStyle(series.color)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                    }
                }

                // Scrub rule line
                if let scrubDate = vm.scrubDate {
                    RuleMark(x: .value("Scrub", scrubDate))
                        .foregroundStyle(theme.textSecondary.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
                }
            }
            .chartYScale(domain: .automatic(includesZero: true))
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
                            Text(String(format: "%.0f%%", v))
                                .foregroundStyle(theme.textSecondary)
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                DrawdownScrubOverlay(proxy: proxy)
            }
            .frame(height: 160)
        }
        .padding()
        .background(theme.surface.cornerRadius(12))
    }

    // MARK: - Header

    @ViewBuilder
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Drawdown from Peak")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            if let scrubDate = vm.scrubDate {
                HStack(spacing: 12) {
                    Text(DateFormatters.shortDate.string(from: scrubDate))
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)

                    ForEach(vm.returnSeries) { series in
                        if let point = vm.scrubValue(for: series.id) {
                            HStack(spacing: 3) {
                                Circle().fill(series.color).frame(width: 6, height: 6)
                                Text(point.drawdownFromPeak.percentFormatted)
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

// MARK: - Drawdown Scrub Overlay

private struct DrawdownScrubOverlay: View {
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
