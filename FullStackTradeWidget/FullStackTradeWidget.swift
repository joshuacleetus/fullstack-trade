import SwiftUI
import WidgetKit

struct OrderBookWidget: Widget {
    let kind: String = "OrderBookWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OrderBookTimelineProvider()) { entry in
            OrderBookWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FullStack Trade")
        .description("Live BTC & ETH orderbook prices from Hyperliquid")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct OrderBookWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: OrderBookEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

@main
struct FullStackTradeWidgetBundle: WidgetBundle {
    var body: some Widget {
        OrderBookWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    OrderBookWidget()
} timeline: {
    OrderBookEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    OrderBookWidget()
} timeline: {
    OrderBookEntry.placeholder
}
