import Foundation

struct HyperliquidAPIService {
    
    private static let apiURL = URL(string: "https://api.hyperliquid.xyz/info")!
    
    static func fetchL2Book(coin: String) async throws -> CoinSnapshot {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let body: [String: Any] = [
            "type": "l2Book",
            "coin": coin,
            "nSigFigs": 5
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(L2BookResponse.self, from: data)
        
        guard let topBid = response.levels.first?.first,
              let topAsk = response.levels.last?.first else {
            throw APIError.noData
        }
        
        let bidPrice = Double(topBid.px) ?? 0
        let askPrice = Double(topAsk.px) ?? 0
        let mid = (bidPrice + askPrice) / 2
        let spread = askPrice - bidPrice
        let spreadPct = mid > 0 ? spread / mid : 0
        
        return CoinSnapshot(
            coin: coin,
            bestBid: bidPrice,
            bestAsk: askPrice,
            midPrice: mid,
            spread: spread,
            spreadPercent: spreadPct
        )
    }
    
    enum APIError: Error {
        case noData
    }
}

// MARK: - API Response Models

private struct L2BookResponse: Decodable {
    let levels: [[L2Level]]
}

private struct L2Level: Decodable {
    let px: String
    let sz: String
    let n: Int
}
