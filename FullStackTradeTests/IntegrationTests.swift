import XCTest
import Combine
@testable import FullStack_Trade

/// Integration tests that verify end-to-end behavior across the WebSocket service
/// layer and the ViewModel layer using a mock WebSocket service.
///
/// These tests exercise the same code paths as the real Hyperliquid integration
/// but run deterministically and complete in under 2 seconds.
final class IntegrationTests: XCTestCase {
    
    private var mockService: MockWebSocketService!
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        mockService = MockWebSocketService()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - WebSocket Service Integration
    
    func testWebSocketConnectsSuccessfully() {
        let connectedExpectation = expectation(description: "WebSocket connects")
        
        mockService.connectionStatePublisher
            .dropFirst() // Skip initial .disconnected
            .sink { state in
                if state == .connected {
                    connectedExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockService.connect()
        mockService.simulateConnected()
        
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error, "Should connect within timeout")
        }
    }
    
    func testWebSocketReceivesBTCOrderBook() {
        let dataExpectation = expectation(description: "Receives BTC book data")
        
        mockService.connectionStatePublisher
            .dropFirst()
            .sink { [weak self] state in
                if state == .connected {
                    self?.mockService.subscribe(coin: "BTC", nSigFigs: 2)
                }
            }
            .store(in: &cancellables)
        
        mockService.bookPublisher
            .first()
            .sink { bookData in
                XCTAssertEqual(bookData.coin, "BTC")
                XCTAssertGreaterThanOrEqual(bookData.levels.count, 2, "Should have bids and asks")
                XCTAssertFalse(bookData.levels[0].isEmpty, "Should have bid levels")
                XCTAssertFalse(bookData.levels[1].isEmpty, "Should have ask levels")
                XCTAssertGreaterThan(bookData.time, 0, "Should have a timestamp")
                dataExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        mockService.connect()
        mockService.simulateConnected()
        mockService.simulateBookUpdate(MockWebSocketService.makeBookData())
        
        waitForExpectations(timeout: 1) { error in
            self.mockService.disconnect()
            XCTAssertNil(error, "Should receive BTC book data")
        }
    }
    
    func testWebSocketReceivesETHOrderBook() {
        let dataExpectation = expectation(description: "Receives ETH book data")
        
        let ethBookData = WsBookData(
            coin: "ETH",
            levels: [
                [WsLevel(px: "3200", sz: "10.5", n: 8), WsLevel(px: "3190", sz: "5.0", n: 3)],
                [WsLevel(px: "3210", sz: "8.2", n: 6), WsLevel(px: "3220", sz: "3.0", n: 2)]
            ],
            time: 1700000000000
        )
        
        mockService.bookPublisher
            .first()
            .sink { bookData in
                XCTAssertEqual(bookData.coin, "ETH")
                XCTAssertGreaterThanOrEqual(bookData.levels.count, 2)
                dataExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        mockService.connect()
        mockService.simulateConnected()
        mockService.subscribe(coin: "ETH", nSigFigs: 3)
        mockService.simulateBookUpdate(ethBookData)
        
        waitForExpectations(timeout: 1) { error in
            self.mockService.disconnect()
            XCTAssertNil(error, "Should receive ETH book data")
        }
    }
    
    func testWebSocketDataHasValidPriceLevels() {
        let validationExpectation = expectation(description: "Book data has valid price levels")
        
        let bookData = MockWebSocketService.makeBookData(
            bidPrices: [("86000", "1.5", 5), ("85900", "2.0", 3), ("85800", "0.5", 1)],
            askPrices: [("86100", "1.2", 4), ("86200", "0.8", 2), ("86300", "3.0", 7)]
        )
        
        mockService.bookPublisher
            .first()
            .sink { bookData in
                let bids = bookData.levels[0]
                let asks = bookData.levels[1]
                
                // Validate bid levels
                for bid in bids {
                    let price = Double(bid.px)
                    let size = Double(bid.sz)
                    XCTAssertNotNil(price, "Bid price '\(bid.px)' should parse to Double")
                    XCTAssertNotNil(size, "Bid size '\(bid.sz)' should parse to Double")
                    XCTAssertGreaterThan(price ?? 0, 0, "Bid price should be positive")
                    XCTAssertGreaterThanOrEqual(size ?? -1, 0, "Bid size should be non-negative")
                    XCTAssertGreaterThan(bid.n, 0, "Bid should have at least 1 order")
                }
                
                // Validate ask levels
                for ask in asks {
                    let price = Double(ask.px)
                    let size = Double(ask.sz)
                    XCTAssertNotNil(price, "Ask price '\(ask.px)' should parse to Double")
                    XCTAssertNotNil(size, "Ask size '\(ask.sz)' should parse to Double")
                    XCTAssertGreaterThan(price ?? 0, 0, "Ask price should be positive")
                    XCTAssertGreaterThanOrEqual(size ?? -1, 0, "Ask size should be non-negative")
                    XCTAssertGreaterThan(ask.n, 0, "Ask should have at least 1 order")
                }
                
                // Best ask should be > best bid (no crossed book)
                if let bestBid = Double(bids.first?.px ?? "0"),
                   let bestAsk = Double(asks.first?.px ?? "0") {
                    XCTAssertGreaterThan(bestAsk, bestBid, "Best ask should exceed best bid")
                }
                
                validationExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        mockService.connect()
        mockService.simulateConnected()
        mockService.subscribe(coin: "BTC", nSigFigs: 5)
        mockService.simulateBookUpdate(bookData)
        
        waitForExpectations(timeout: 1) { error in
            self.mockService.disconnect()
            XCTAssertNil(error)
        }
    }
    
    func testDisconnectSetsStateCorrectly() {
        let connectedExpectation = expectation(description: "Connected")
        let disconnectedExpectation = expectation(description: "Disconnected after explicit call")
        
        var didConnect = false
        
        mockService.connectionStatePublisher
            .dropFirst()
            .sink { state in
                if state == .connected && !didConnect {
                    didConnect = true
                    connectedExpectation.fulfill()
                } else if state == .disconnected && didConnect {
                    disconnectedExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockService.connect()
        mockService.simulateConnected()
        
        wait(for: [connectedExpectation], timeout: 1)
        
        mockService.disconnect()
        mockService.simulateDisconnected()
        
        wait(for: [disconnectedExpectation], timeout: 1)
    }
    
    // MARK: - ViewModel End-to-End Integration
    
    func testViewModelReceivesLiveBTCData() {
        let viewModel = OrderBookViewModel(webSocketService: mockService)
        let dataExpectation = expectation(description: "ViewModel populates bids and asks")
        
        viewModel.start()
        mockService.simulateConnected()
        
        let bookData = MockWebSocketService.makeBookData(
            bidPrices: [("86000", "1.5", 5), ("85900", "2.0", 3)],
            askPrices: [("86100", "1.2", 4), ("86200", "0.8", 2)]
        )
        mockService.simulateBookUpdate(bookData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if !viewModel.bids.isEmpty && !viewModel.asks.isEmpty {
                dataExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { error in
            viewModel.stop()
            
            XCTAssertNil(error, "ViewModel should receive data")
            XCTAssertFalse(viewModel.bids.isEmpty, "Should have bids")
            XCTAssertFalse(viewModel.asks.isEmpty, "Should have asks")
            XCTAssertGreaterThan(viewModel.midPrice, 0, "Mid-price should be calculated")
            XCTAssertGreaterThan(viewModel.spread, 0, "Spread should be positive")
            XCTAssertEqual(viewModel.connectionState, .connected, "Should be connected")
        }
    }
    
    func testViewModelBidsAreSortedDescending() {
        let viewModel = OrderBookViewModel(webSocketService: mockService)
        let dataExpectation = expectation(description: "Bids are sorted")
        
        viewModel.start()
        mockService.simulateConnected()
        
        // Send unsorted bids to verify ViewModel sorts them
        let bookData = MockWebSocketService.makeBookData(
            bidPrices: [("85800", "0.5", 1), ("86000", "1.5", 5), ("85900", "2.0", 3)],
            askPrices: [("86100", "1.2", 4)]
        )
        mockService.simulateBookUpdate(bookData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if viewModel.bids.count >= 2 {
                dataExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { error in
            viewModel.stop()
            
            XCTAssertNil(error)
            // Bids should be in descending price order (highest first)
            for i in 0..<(viewModel.bids.count - 1) {
                XCTAssertGreaterThanOrEqual(
                    viewModel.bids[i].price,
                    viewModel.bids[i + 1].price,
                    "Bids should be sorted descending"
                )
            }
        }
    }
    
    func testViewModelCumulativeTotalsAreIncreasing() {
        let viewModel = OrderBookViewModel(webSocketService: mockService)
        let dataExpectation = expectation(description: "Totals are cumulative")
        
        viewModel.start()
        mockService.simulateConnected()
        
        let bookData = MockWebSocketService.makeBookData(
            bidPrices: [("86000", "1.5", 5), ("85900", "2.0", 3), ("85800", "0.5", 1)],
            askPrices: [("86100", "1.0", 4)]
        )
        mockService.simulateBookUpdate(bookData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if viewModel.bids.count >= 2 {
                dataExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { error in
            viewModel.stop()
            
            XCTAssertNil(error)
            // Cumulative totals should be non-decreasing
            for i in 0..<(viewModel.bids.count - 1) {
                XCTAssertLessThanOrEqual(
                    viewModel.bids[i].total,
                    viewModel.bids[i + 1].total,
                    "Cumulative totals should increase"
                )
            }
        }
    }
    
    func testViewModelCoinSwitchClearsAndRepopulates() {
        let viewModel = OrderBookViewModel(webSocketService: mockService)
        let initialDataExpectation = expectation(description: "Initial BTC data loaded")
        
        viewModel.start()
        mockService.simulateConnected()
        
        // Send initial BTC data
        mockService.simulateBookUpdate(MockWebSocketService.makeBookData())
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if !viewModel.bids.isEmpty {
                initialDataExpectation.fulfill()
            }
        }
        
        wait(for: [initialDataExpectation], timeout: 1)
        
        // Switch to ETH
        viewModel.selectCoin(.eth)
        XCTAssertEqual(viewModel.selectedCoin, .eth)
        
        // Send ETH data
        let ethBookData = WsBookData(
            coin: "ETH",
            levels: [
                [WsLevel(px: "3200", sz: "10.5", n: 8), WsLevel(px: "3190", sz: "5.0", n: 3)],
                [WsLevel(px: "3210", sz: "8.2", n: 6), WsLevel(px: "3220", sz: "3.0", n: 2)]
            ],
            time: 1700000000000
        )
        mockService.simulateBookUpdate(ethBookData)
        
        let ethDataExpectation = expectation(description: "ETH data loaded after switch")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if !viewModel.bids.isEmpty && viewModel.selectedCoin == .eth {
                ethDataExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { error in
            viewModel.stop()
            
            XCTAssertNil(error, "Should receive ETH data after coin switch")
            XCTAssertFalse(viewModel.bids.isEmpty, "Should have ETH bids")
            XCTAssertGreaterThan(viewModel.midPrice, 0, "Should have ETH mid-price")
        }
    }
    
    func testViewModelMaxDisplayLevels() {
        let viewModel = OrderBookViewModel(webSocketService: mockService)
        let dataExpectation = expectation(description: "Data loaded")
        
        viewModel.start()
        mockService.simulateConnected()
        
        // Send 20 levels per side to exceed the 15-level cap
        let bids: [(String, String, Int)] = (0..<20).map { i in
            ("\(86000 - i * 100)", "1.0", 1)
        }
        let asks: [(String, String, Int)] = (0..<20).map { i in
            ("\(86100 + i * 100)", "1.0", 1)
        }
        let bookData = MockWebSocketService.makeBookData(bidPrices: bids, askPrices: asks)
        mockService.simulateBookUpdate(bookData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if !viewModel.bids.isEmpty {
                dataExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1) { error in
            viewModel.stop()
            
            XCTAssertNil(error)
            XCTAssertLessThanOrEqual(viewModel.bids.count, 15, "Should cap at 15 bid levels")
            XCTAssertLessThanOrEqual(viewModel.asks.count, 15, "Should cap at 15 ask levels")
        }
    }
    
    func testMultipleUpdatesStreamContinuously() {
        let multipleUpdatesExpectation = expectation(description: "Receives multiple updates")
        var updateCount = 0
        let targetUpdates = 5
        
        mockService.bookPublisher
            .prefix(targetUpdates)
            .sink(receiveCompletion: { _ in
                multipleUpdatesExpectation.fulfill()
            }, receiveValue: { bookData in
                updateCount += 1
                XCTAssertEqual(bookData.coin, "BTC")
                XCTAssertGreaterThanOrEqual(bookData.levels.count, 2)
            })
            .store(in: &cancellables)
        
        mockService.connect()
        mockService.simulateConnected()
        mockService.subscribe(coin: "BTC", nSigFigs: 2)
        
        // Send multiple updates
        for i in 0..<targetUpdates {
            let bookData = MockWebSocketService.makeBookData(
                bidPrices: [("\(86000 + i * 10)", "1.5", 5), ("\(85900 + i * 10)", "2.0", 3)],
                askPrices: [("\(86100 + i * 10)", "1.2", 4), ("\(86200 + i * 10)", "0.8", 2)],
                time: 1700000000000 + i * 1000
            )
            mockService.simulateBookUpdate(bookData)
        }
        
        waitForExpectations(timeout: 1) { error in
            self.mockService.disconnect()
            XCTAssertNil(error, "Should receive \(targetUpdates) updates")
            XCTAssertEqual(updateCount, targetUpdates, "Should have received exactly \(targetUpdates) updates")
        }
    }
}
