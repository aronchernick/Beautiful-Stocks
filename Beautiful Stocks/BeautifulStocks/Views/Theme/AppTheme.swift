import SwiftUI

// MARK: - App Theme

/// Centralized theme with toggleable dark/light mode.
/// Default is the "Old Robinhood Gold" dark theme.
struct AppTheme {
    let background: Color
    let surface: Color
    let primaryAccent: Color
    let textPrimary: Color
    let textSecondary: Color
    let positiveColor: Color
    let negativeColor: Color
    let gridLine: Color

    // Old Robinhood Dark (default)
    static let dark = AppTheme(
        background:     Color(hex: 0x1F2123),
        surface:        Color(hex: 0x2A2C2E),
        primaryAccent:  Color(hex: 0xF6C86A),
        textPrimary:    .white,
        textSecondary:  Color(hex: 0x9B9B9B),
        positiveColor:  Color(hex: 0x5AC53A),
        negativeColor:  Color(hex: 0xEB5160),
        gridLine:       Color(hex: 0x3A3C3E)
    )

    // Light mode
    static let light = AppTheme(
        background:     Color(hex: 0xF5F5F5),
        surface:        .white,
        primaryAccent:  Color(hex: 0xD4A843),
        textPrimary:    Color(hex: 0x1A1A1A),
        textSecondary:  Color(hex: 0x6B6B6B),
        positiveColor:  Color(hex: 0x2E8B57),
        negativeColor:  Color(hex: 0xCC3333),
        gridLine:       Color(hex: 0xDDDDDD)
    )
}

// MARK: - Theme Environment Key

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.dark
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Color from Hex

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8)  & 0xFF) / 255.0,
            blue:  Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Asset Color Provider

/// Assigns a unique, deterministic color to each asset.
/// Colors remain consistent everywhere the asset appears.
enum AssetColorProvider {

    /// A curated palette that is visually distinct on both dark and light backgrounds.
    private static let palette: [Color] = [
        Color(hex: 0xF6C86A),  // Gold (accent) — reserved for first
        Color(hex: 0x5BC0EB),  // Sky blue
        Color(hex: 0xFDE74C),  // Yellow
        Color(hex: 0x9BC53D),  // Lime
        Color(hex: 0xE55934),  // Burnt orange
        Color(hex: 0xFA7921),  // Tangerine
        Color(hex: 0xC3423F),  // Crimson
        Color(hex: 0xA882DD),  // Lavender
        Color(hex: 0x55DDE0),  // Teal
        Color(hex: 0xF78154),  // Salmon
        Color(hex: 0xB8D8D8),  // Pale teal
        Color(hex: 0xEE6352),  // Coral
    ]

    /// Deterministic color for an asset based on its ID.
    /// USD always gets a distinct gray/green to stand out as the baseline.
    static func color(for asset: Asset, at index: Int) -> Color {
        if asset.kind == .currency {
            return Color(hex: 0x9B9B9B) // Muted gray for USD
        }
        return palette[index % palette.count]
    }

    /// Assign colors to an ordered array of assets.
    static func assignColors(to assets: [Asset]) -> [String: Color] {
        var result: [String: Color] = [:]
        var equityIndex = 0
        for asset in assets {
            if asset.kind == .currency {
                result[asset.id] = color(for: asset, at: 0)
            } else {
                result[asset.id] = color(for: asset, at: equityIndex)
                equityIndex += 1
            }
        }
        return result
    }
}
