import XCTest
@testable import FullStack_Trade

final class PerformanceTests: XCTestCase {
    
    // MARK: - PriceLevel Formatting Performance
    
    func testPriceLevelFormattingPerformance() {
        // Measure formatting 1000 price levels (simulates rendering a full orderbook)
        let levels = (0..<1000).map {
            PriceLevel(price: 86000.0 + Double($0), size: Double.random(in: 0.001...100.0), orderCount: Int.random(in: 1...20), total: Double.random(in: 0.1...500.0))
        }
        
        measure {
            for level in levels {
                _ = level.formattedPrice
                _ = level.formattedSize
                _ = level.formattedTotal
            }
        }
    }
    
    func testPriceLevelCreationPerformance() {
        // Measure creating 1000 PriceLevel structs
        measure {
            for i in 0..<1000 {
                _ = PriceLevel(price: Double(86000 + i), size: 1.5, orderCount: 3, total: 0)
            }
        }
    }
    
    // MARK: - ViewModel Data Processing Performance
    
    func testBookUpdateProcessingPerformance() {
        // Measure how fast the ViewModel processes incoming book data
        let mockService = MockWebSocketService()
        let viewModel = OrderBookViewModel(webSocketService: mockService)
        viewModel.start()
        mockService.simulateConnected()
        
        // Create realistic book data with 15 levels per side
        let bidPrices: [(String, String, Int)] = (0..<15).map {
            ("\(86000 - $0 * 10)", String(format: "%.4f", Double.random(in: 0.1...10.0)), Int.random(in: 1...15))
        }
        let askPrices: [(String, String, Int)] = (0..<15).map {
            ("\(86100 + $0 * 10)", String(format: "%.4f", Double.random(in: 0.1...10.0)), Int.random(in: 1...15))
        }
        
        measure {
            for _ in 0..<100 {
                let data = MockWebSocketService.makeBookData(bidPrices: bidPrices, askPrices: askPrices)
                mockService.simulateBookUpdate(data)
                // Allow Combine pipeline to process
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.001))
            }
        }
    }
    
    func testLargeOrderBookProcessing() {
        // Measure processing a large orderbook (50 levels per side)
        let mockService = MockWebSocketService()
        let viewModel = OrderBookViewModel(webSocketService: mockService)
        viewModel.start()
        mockService.simulateConnected()
        
        let bidPrices: [(String, String, Int)] = (0..<50).map {
            ("\(86000 - $0 * 5)", String(format: "%.4f", Double.random(in: 0.01...50.0)), Int.random(in: 1...30))
        }
        let askPrices: [(String, String, Int)] = (0..<50).map {
            ("\(86100 + $0 * 5)", String(format: "%.4f", Double.random(in: 0.01...50.0)), Int.random(in: 1...30))
        }
        
        measure {
            for _ in 0..<50 {
                let data = MockWebSocketService.makeBookData(bidPrices: bidPrices, askPrices: askPrices)
                mockService.simulateBookUpdate(data)
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.001))
            }
        }
    }
    
    // MARK: - Coin & Precision Switching Performance
    
    func testCoinSwitchingPerformance() {
        // Measure overhead of switching coins rapidly
        let mockService = MockWebSocketService()
        let viewModel = OrderBookViewModel(webSocketService: mockService)
        viewModel.start()
        mockService.simulateConnected()
        
        measure {
            for _ in 0..<100 {
                viewModel.selectCoin(.eth)
                viewModel.selectCoin(.btc)
            }
        }
    }
    
    func testPrecisionSwitchingPerformance() {
        // Measure overhead of switching precisions rapidly
        let mockService = MockWebSocketService()
        let viewModel = OrderBookViewModel(webSocketService: mockService)
        viewModel.start()
        mockService.simulateConnected()
        
        measure {
            for _ in 0..<100 {
                viewModel.selectPrecision(.two)
                viewModel.selectPrecision(.three)
                viewModel.selectPrecision(.four)
                viewModel.selectPrecision(.five)
            }
        }
    }
    
    // MARK: - Spread Calculation Performance
    
    func testSpreadCalculationThroughput() {
        // Measure spread/midPrice calculation across many updates with varying prices
        let mockService = MockWebSocketService()
        let viewModel = OrderBookViewModel(webSocketService: mockService)
        viewModel.start()
        mockService.simulateConnected()
        
        measure {
            for i in 0..<200 {
                let offset = Double(i % 50)
                let bids: [(String, String, Int)] = [
                    ("\(86000 + offset)", "1.5", 5),
                    ("\(85990 + offset)", "2.0", 3)
                ]
                let asks: [(String, String, Int)] = [
                    ("\(86010 + offset)", "1.2", 4),
                    ("\(86020 + offset)", "0.8", 2)
                ]
                let data = MockWebSocketService.makeBookData(bidPrices: bids, askPrices: asks)
                mockService.simulateBookUpdate(data)
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.001))
            }
        }
    }
    
    // MARK: - WsLevel Parsing Performance
    
    func testWsLevelParsingPerformance() {
        // Measure string-to-Double parsing which happens on every WebSocket tick
        let levels = (0..<100).map {
            WsLevel(px: String(format: "%.1f", 86000.0 + Double($0) * 0.5), sz: String(format: "%.4f", Double.random(in: 0.001...10.0)), n: Int.random(in: 1...20))
        }
        
        measure {
            for _ in 0..<100 {
                for level in levels {
                    _ = Double(level.px)
                    _ = Double(level.sz)
                }
            }
        }
    }
    
    // MARK: - Flash Detection Performance
    
    func testFlashDetectionPerformance() {
        // Measure the Set operations used for detecting price changes
        measure {
            var previousPrices: Set<Double> = []
            for i in 0..<500 {
                let currentPrices = Set((0..<15).map { 86000.0 + Double($0 * 10) + Double(i % 5) })
                _ = currentPrices.subtracting(previousPrices)
                previousPrices = currentPrices
            }
        }
    }
    
    // MARK: - Cumulative Total Calculation Performance
    
    func testCumulativeTotalCalculationPerformance() {
        // Measure cumulative total calculation on large arrays
        measure {
            for _ in 0..<1000 {
                var levels = (0..<50).map {
                    PriceLevel(price: 86000.0 + Double($0), size: Double.random(in: 0.01...10.0), orderCount: 3, total: 0)
                }
                var cumulative: Double = 0
                for i in 0..<levels.count {
                    cumulative += levels[i].size
                    levels[i].total = cumulative
                }
            }
        }
    }
}
