import WidgetKit

struct OrderBookTimelineProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> OrderBookEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (OrderBookEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<OrderBookEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            
            // Refresh every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func fetchEntry() async -> OrderBookEntry {
        do {
            async let btcTask = HyperliquidAPIService.fetchL2Book(coin: "BTC")
            async let ethTask = HyperliquidAPIService.fetchL2Book(coin: "ETH")
            
            let (btc, eth) = try await (btcTask, ethTask)
            
            return OrderBookEntry(
                date: .now,
                btcData: btc,
                ethData: eth,
                isPlaceholder: false
            )
        } catch {
            return .placeholder
        }
    }
}
