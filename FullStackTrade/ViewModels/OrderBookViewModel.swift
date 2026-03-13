import Foundation
import Combine
import SwiftUI

@Observable
final class OrderBookViewModel {
    
    // MARK: - Constants
    
    private static let maxDisplayLevels = 15
    
    // MARK: - Published State
    
    var bids: [PriceLevel] = []
    var asks: [PriceLevel] = []
    var selectedCoin: TradingCoin = .btc
    var selectedPrecision: PrecisionOption = .two
    var connectionState: ConnectionState = .disconnected
    var spread: Double = 0
    var spreadPercent: Double = 0
    var midPrice: Double = 0
    var lastUpdateTime: Date?
    var maxTotalBids: Double = 1
    var maxTotalAsks: Double = 1
    
    // MARK: - Private Properties
    
    private let webSocketService: WebSocketServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(webSocketService: WebSocketServiceProtocol = HyperliquidWebSocketService()) {
        self.webSocketService = webSocketService
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    func start() {
        webSocketService.connect()
    }
    
    func stop() {
        webSocketService.disconnect()
    }
    
    func selectCoin(_ coin: TradingCoin) {
        guard coin != selectedCoin else { return }
        
        // Unsubscribe from current
        webSocketService.unsubscribe(
            coin: selectedCoin.rawValue,
            nSigFigs: selectedPrecision.rawValue
        )
        
        // Clear current data
        withAnimation(.easeInOut(duration: 0.2)) {
            bids = []
            asks = []
            spread = 0
            spreadPercent = 0
            midPrice = 0
        }
        
        // Update selection and subscribe
        selectedCoin = coin
        webSocketService.subscribe(
            coin: coin.rawValue,
            nSigFigs: selectedPrecision.rawValue
        )
    }
    
    func selectPrecision(_ precision: PrecisionOption) {
        guard precision != selectedPrecision else { return }
        
        // Unsubscribe from current
        webSocketService.unsubscribe(
            coin: selectedCoin.rawValue,
            nSigFigs: selectedPrecision.rawValue
        )
        
        // Update selection and subscribe
        selectedPrecision = precision
        webSocketService.subscribe(
            coin: selectedCoin.rawValue,
            nSigFigs: precision.rawValue
        )
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        webSocketService.bookPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bookData in
                self?.processBookUpdate(bookData)
            }
            .store(in: &cancellables)
        
        webSocketService.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self?.connectionState = state
                }
                
                // Auto-subscribe on connect
                if state == .connected, let self = self {
                    self.webSocketService.subscribe(
                        coin: self.selectedCoin.rawValue,
                        nSigFigs: self.selectedPrecision.rawValue
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    private func processBookUpdate(_ data: WsBookData) {
        guard data.levels.count >= 2 else { return }
        
        let rawBids = data.levels[0]
        let rawAsks = data.levels[1]
        
        // Transform to PriceLevels
        var newBids = rawBids.prefix(Self.maxDisplayLevels).compactMap { level -> PriceLevel? in
            guard let price = Double(level.px), let size = Double(level.sz) else { return nil }
            return PriceLevel(price: price, size: size, orderCount: level.n, total: 0)
        }
        
        var newAsks = rawAsks.prefix(Self.maxDisplayLevels).compactMap { level -> PriceLevel? in
            guard let price = Double(level.px), let size = Double(level.sz) else { return nil }
            return PriceLevel(price: price, size: size, orderCount: level.n, total: 0)
        }
        
        // Sort: bids descending (highest first), asks ascending (lowest first)
        newBids.sort { $0.price > $1.price }
        newAsks.sort { $0.price < $1.price }
        
        // Calculate cumulative totals
        calculateCumulativeTotals(&newBids)
        calculateCumulativeTotals(&newAsks)
        
        // Calculate spread
        let bestBid = newBids.first?.price ?? 0
        let bestAsk = newAsks.first?.price ?? 0
        let newSpread = bestAsk > 0 && bestBid > 0 ? bestAsk - bestBid : 0
        let newMidPrice = bestAsk > 0 && bestBid > 0 ? (bestAsk + bestBid) / 2.0 : 0
        let newSpreadPercent = newMidPrice > 0 ? (newSpread / newMidPrice) * 100.0 : 0
        
        // Max totals for depth bar scaling
        let maxBid = newBids.last?.total ?? 1
        let maxAsk = newAsks.last?.total ?? 1
        
        // Reverse asks for display (lowest ask at bottom, near spread)
        let displayAsks = newAsks.reversed().map { $0 }
        
        // Update state
        withAnimation(.easeInOut(duration: 0.15)) {
            self.bids = newBids
            self.asks = displayAsks
            self.spread = newSpread
            self.spreadPercent = newSpreadPercent
            self.midPrice = newMidPrice
            self.maxTotalBids = maxBid
            self.maxTotalAsks = maxAsk
            self.lastUpdateTime = Date(timeIntervalSince1970: TimeInterval(data.time) / 1000.0)
        }
    }
    
    private func calculateCumulativeTotals(_ levels: inout [PriceLevel]) {
        var cumulative: Double = 0
        for i in 0..<levels.count {
            cumulative += levels[i].size
            levels[i].total = cumulative
        }
    }
}
