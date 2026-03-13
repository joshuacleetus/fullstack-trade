import XCTest
@testable import FullStack_Trade

final class OrderBookViewModelTests: XCTestCase {
    
    private var viewModel: OrderBookViewModel!
    private var mockService: MockWebSocketService!
    
    override func setUp() {
        super.setUp()
        mockService = MockWebSocketService()
        viewModel = OrderBookViewModel(webSocketService: mockService)
    }
    
    override func tearDown() {
        viewModel.stop()
        viewModel = nil
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertTrue(viewModel.bids.isEmpty)
        XCTAssertTrue(viewModel.asks.isEmpty)
        XCTAssertEqual(viewModel.selectedCoin, .btc)
        XCTAssertEqual(viewModel.selectedPrecision, .two)
        XCTAssertEqual(viewModel.spread, 0)
        XCTAssertEqual(viewModel.midPrice, 0)
        XCTAssertEqual(viewModel.midPriceDirection, 0)
    }
    
    // MARK: - Connection Tests
    
    func testStartConnects() {
        viewModel.start()
        XCTAssertEqual(mockService.connectCallCount, 1)
    }
    
    func testStopDisconnects() {
        viewModel.start()
        viewModel.stop()
        XCTAssertEqual(mockService.disconnectCallCount, 1)
    }
    
    func testAutoSubscribesOnConnect() {
        let expectation = XCTestExpectation(description: "Auto-subscribe on connect")
        
        viewModel.start()
        mockService.simulateConnected()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.mockService.subscriptions.count, 1)
            XCTAssertEqual(self.mockService.subscriptions.first?.coin, "BTC")
            XCTAssertEqual(self.mockService.subscriptions.first?.nSigFigs, 2)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConnectionStateUpdates() {
        let expectation = XCTestExpectation(description: "Connection state updates")
        
        mockService.simulateConnected()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.connectionState, .connected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Coin Selection Tests
    
    func testSelectCoinUnsubscribesFromCurrent() {
        viewModel.selectCoin(.eth)
        
        XCTAssertEqual(mockService.unsubscriptions.count, 1)
        XCTAssertEqual(mockService.unsubscriptions.first?.coin, "BTC")
    }
    
    func testSelectCoinSubscribesToNew() {
        viewModel.selectCoin(.eth)
        
        XCTAssertEqual(mockService.subscriptions.count, 1)
        XCTAssertEqual(mockService.subscriptions.first?.coin, "ETH")
    }
    
    func testSelectSameCoinNoOp() {
        viewModel.selectCoin(.btc) // Already BTC
        
        XCTAssertEqual(mockService.subscriptions.count, 0)
        XCTAssertEqual(mockService.unsubscriptions.count, 0)
    }
    
    func testSelectCoinClearsData() {
        // Simulate some data first
        mockService.simulateBookUpdate(MockWebSocketService.makeBookData())
        
        let expectation = XCTestExpectation(description: "Data cleared on coin switch")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.viewModel.selectCoin(.eth)
            XCTAssertTrue(self.viewModel.bids.isEmpty)
            XCTAssertTrue(self.viewModel.asks.isEmpty)
            XCTAssertEqual(self.viewModel.spread, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Precision Selection Tests
    
    func testSelectPrecisionUnsubscribesAndResubscribes() {
        viewModel.selectPrecision(.five)
        
        XCTAssertEqual(mockService.unsubscriptions.count, 1)
        XCTAssertEqual(mockService.unsubscriptions.first?.nSigFigs, 2) // Old value
        XCTAssertEqual(mockService.subscriptions.count, 1)
        XCTAssertEqual(mockService.subscriptions.first?.nSigFigs, 5) // New value
    }
    
    func testSelectSamePrecisionNoOp() {
        viewModel.selectPrecision(.two) // Already .two
        
        XCTAssertEqual(mockService.subscriptions.count, 0)
        XCTAssertEqual(mockService.unsubscriptions.count, 0)
    }
    
    // MARK: - Book Data Processing Tests
    
    func testProcessBookUpdate() {
        let expectation = XCTestExpectation(description: "Book data processed")
        
        let bookData = MockWebSocketService.makeBookData(
            bidPrices: [("86000", "1.5", 5), ("85900", "2.0", 3), ("85800", "0.5", 1)],
            askPrices: [("86100", "1.2", 4), ("86200", "0.8", 2), ("86300", "3.0", 7)]
        )
        mockService.simulateBookUpdate(bookData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Bids: sorted descending by price
            XCTAssertEqual(self.viewModel.bids.count, 3)
            XCTAssertEqual(self.viewModel.bids.first?.price, 86000)
            XCTAssertEqual(self.viewModel.bids.last?.price, 85800)
            
            // Asks: reversed for display (highest first, lowest at bottom near spread)
            XCTAssertEqual(self.viewModel.asks.count, 3)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSpreadCalculation() {
        let expectation = XCTestExpectation(description: "Spread calculated")
        
        let bookData = MockWebSocketService.makeBookData(
            bidPrices: [("86000", "1.5", 5)],
            askPrices: [("86100", "1.2", 4)]
        )
        mockService.simulateBookUpdate(bookData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.viewModel.spread, 100.0, accuracy: 0.01)
            
            let expectedMidPrice = (86000.0 + 86100.0) / 2.0
            XCTAssertEqual(self.viewModel.midPrice, expectedMidPrice, accuracy: 0.01)
            
            let expectedSpreadPercent = (100.0 / expectedMidPrice) * 100.0
            XCTAssertEqual(self.viewModel.spreadPercent, expectedSpreadPercent, accuracy: 0.001)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCumulativeTotals() {
        let expectation = XCTestExpectation(description: "Cumulative totals calculated")
        
        let bookData = MockWebSocketService.makeBookData(
            bidPrices: [("86000", "1.5", 5), ("85900", "2.0", 3), ("85800", "0.5", 1)],
            askPrices: [("86100", "1.0", 4)]
        )
        mockService.simulateBookUpdate(bookData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Bids cumulative: 1.5, 3.5, 4.0
            XCTAssertEqual(self.viewModel.bids[0].total, 1.5, accuracy: 0.001)
            XCTAssertEqual(self.viewModel.bids[1].total, 3.5, accuracy: 0.001)
            XCTAssertEqual(self.viewModel.bids[2].total, 4.0, accuracy: 0.001)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMidPriceDirection() {
        let expectation = XCTestExpectation(description: "Mid-price direction tracked")
        
        // First update
        mockService.simulateBookUpdate(MockWebSocketService.makeBookData(
            bidPrices: [("86000", "1.5", 5)],
            askPrices: [("86100", "1.2", 4)]
        ))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Second update with higher prices → direction should be UP
            self.mockService.simulateBookUpdate(MockWebSocketService.makeBookData(
                bidPrices: [("86200", "1.5", 5)],
                askPrices: [("86300", "1.2", 4)]
            ))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                XCTAssertEqual(self.viewModel.midPriceDirection, 1) // UP
                
                // Third update with lower prices → direction should be DOWN
                self.mockService.simulateBookUpdate(MockWebSocketService.makeBookData(
                    bidPrices: [("85800", "1.5", 5)],
                    askPrices: [("85900", "1.2", 4)]
                ))
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    XCTAssertEqual(self.viewModel.midPriceDirection, -1) // DOWN
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testMaxDisplayLevels() {
        let expectation = XCTestExpectation(description: "Max display levels enforced")
        
        // Create 20 bid levels
        let bids = (0..<20).map { i in
            ("\(86000 - i * 100)", "1.0", 1)
        }
        let bookData = MockWebSocketService.makeBookData(
            bidPrices: bids,
            askPrices: [("86100", "1.0", 1)]
        )
        mockService.simulateBookUpdate(bookData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertLessThanOrEqual(self.viewModel.bids.count, 15) // maxDisplayLevels
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
