import Foundation

// MARK: - Supported Coins

enum TradingCoin: String, CaseIterable, Identifiable {
    case btc = "BTC"
    case eth = "ETH"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .btc: return "BTC"
        case .eth: return "ETH"
        }
    }
    
    var icon: String {
        switch self {
        case .btc: return "bitcoinsign.circle.fill"
        case .eth: return "diamond.fill"
        }
    }
}

// MARK: - Precision Options

enum PrecisionOption: Int, CaseIterable, Identifiable {
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    
    var id: Int { rawValue }
    
    var displayLabel: String {
        "\(rawValue) sig"
    }
}

// MARK: - Connection State

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
    
    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Live"
        case .error(let msg): return "Error: \(msg)"
        }
    }
    
    var color: String {
        switch self {
        case .connected: return "statusGreen"
        case .connecting: return "statusYellow"
        case .disconnected, .error: return "statusRed"
        }
    }
}

// MARK: - Price Level (View-Ready)

struct PriceLevel: Identifiable, Equatable {
    var id: Double { price } // Use price as stable ID for efficient SwiftUI diffing
    let price: Double
    let size: Double
    let orderCount: Int
    var total: Double // cumulative size
    
    var formattedPrice: String {
        if price >= 1000 {
            return String(format: "%.1f", price)
        } else if price >= 100 {
            return String(format: "%.2f", price)
        } else if price >= 1 {
            return String(format: "%.4f", price)
        } else {
            return String(format: "%.6f", price)
        }
    }
    
    var formattedSize: String {
        if size >= 1000 {
            return String(format: "%.1f", size)
        } else if size >= 100 {
            return String(format: "%.2f", size)
        } else if size >= 1 {
            return String(format: "%.4f", size)
        } else {
            return String(format: "%.6f", size)
        }
    }
    
    var formattedTotal: String {
        if total >= 1000 {
            return String(format: "%.1f", total)
        } else if total >= 100 {
            return String(format: "%.2f", total)
        } else if total >= 1 {
            return String(format: "%.4f", total)
        } else {
            return String(format: "%.6f", total)
        }
    }
}

// MARK: - OrderBook Snapshot

struct OrderBookSnapshot {
    let coin: String
    let bids: [PriceLevel]
    let asks: [PriceLevel]
    let timestamp: Date
    let spread: Double
    let spreadPercent: Double
    let midPrice: Double
}
