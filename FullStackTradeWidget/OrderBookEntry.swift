import WidgetKit
import Foundation

struct OrderBookEntry: TimelineEntry {
    let date: Date
    let btcData: CoinSnapshot
    let ethData: CoinSnapshot
    let isPlaceholder: Bool
    
    static var placeholder: OrderBookEntry {
        OrderBookEntry(
            date: .now,
            btcData: CoinSnapshot(
                coin: "BTC",
                bestBid: 67234.50,
                bestAsk: 67235.80,
                midPrice: 67235.15,
                spread: 1.30,
                spreadPercent: 0.0019
            ),
            ethData: CoinSnapshot(
                coin: "ETH",
                bestBid: 3456.78,
                bestAsk: 3457.12,
                midPrice: 3456.95,
                spread: 0.34,
                spreadPercent: 0.0098
            ),
            isPlaceholder: true
        )
    }
}

struct CoinSnapshot {
    let coin: String
    let bestBid: Double
    let bestAsk: Double
    let midPrice: Double
    let spread: Double
    let spreadPercent: Double
    
    var formattedMidPrice: String {
        if midPrice >= 10000 {
            return String(format: "%.1f", midPrice)
        } else if midPrice >= 100 {
            return String(format: "%.2f", midPrice)
        } else {
            return String(format: "%.2f", midPrice)
        }
    }
    
    var formattedBid: String {
        if bestBid >= 10000 {
            return String(format: "%.1f", bestBid)
        } else {
            return String(format: "%.2f", bestBid)
        }
    }
    
    var formattedAsk: String {
        if bestAsk >= 10000 {
            return String(format: "%.1f", bestAsk)
        } else {
            return String(format: "%.2f", bestAsk)
        }
    }
    
    var formattedSpreadPercent: String {
        String(format: "%.3f%%", spreadPercent * 100)
    }
}
