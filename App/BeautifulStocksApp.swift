import SwiftUI

@main
struct BeautifulStocksApp: App {
    @StateObject private var viewModel = PortfolioViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environment(\.appTheme, viewModel.currentTheme)
                .preferredColorScheme(viewModel.isDarkMode ? .dark : .light)
        }
    }
}
