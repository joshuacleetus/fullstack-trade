import SwiftUI

@main
struct FullStackTradeApp: App {
    var body: some Scene {
        WindowGroup {
            OrderBookView()
                .preferredColorScheme(.dark)
        }
    }
}
