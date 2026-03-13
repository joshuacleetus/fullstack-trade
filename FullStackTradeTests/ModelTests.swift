import XCTest
@testable import FullStack_Trade

final class PriceLevelTests: XCTestCase {
    
    // MARK: - ID Tests
    
    func testIdIsBasedOnPrice() {
        let level = PriceLevel(price: 86000.5, size: 1.0, orderCount: 3, total: 1.0)
        XCTAssertEqual(level.id, 86000.5)
    }
    
    func testLevelsWithSamePriceHaveSameId() {
        let level1 = PriceLevel(price: 86000, size: 1.0, orderCount: 3, total: 1.0)
        let level2 = PriceLevel(price: 86000, size: 2.0, orderCount: 5, total: 3.0)
        XCTAssertEqual(level1.id, level2.id)
    }
    
    // MARK: - Price Formatting Tests
    
    func testFormattedPriceAbove1000() {
        let level = PriceLevel(price: 86420.5, size: 1.0, orderCount: 1, total: 1.0)
        XCTAssertEqual(level.formattedPrice, "86420.5")
    }
    
    func testFormattedPriceAbove100() {
        let level = PriceLevel(price: 420.69, size: 1.0, orderCount: 1, total: 1.0)
        XCTAssertEqual(level.formattedPrice, "420.69")
    }
    
    func testFormattedPriceAbove1() {
        let level = PriceLevel(price: 3.1415, size: 1.0, orderCount: 1, total: 1.0)
        XCTAssertEqual(level.formattedPrice, "3.1415")
    }
    
    func testFormattedPriceBelow1() {
        let level = PriceLevel(price: 0.123456, size: 1.0, orderCount: 1, total: 1.0)
        XCTAssertEqual(level.formattedPrice, "0.123456")
    }
    
    // MARK: - Size Formatting Tests
    
    func testFormattedSizeLarge() {
        let level = PriceLevel(price: 1.0, size: 1500.75, orderCount: 1, total: 1.0)
        XCTAssertEqual(level.formattedSize, "1500.8") // >= 1000 → 1 decimal
    }
    
    func testFormattedSizeMedium() {
        let level = PriceLevel(price: 1.0, size: 250.33, orderCount: 1, total: 1.0)
        XCTAssertEqual(level.formattedSize, "250.33") // >= 100 → 2 decimals
    }
    
    func testFormattedSizeSmall() {
        let level = PriceLevel(price: 1.0, size: 1.2345, orderCount: 1, total: 1.0)
        XCTAssertEqual(level.formattedSize, "1.2345") // >= 1 → 4 decimals
    }
    
    func testFormattedSizeTiny() {
        let level = PriceLevel(price: 1.0, size: 0.005678, orderCount: 1, total: 1.0)
        XCTAssertEqual(level.formattedSize, "0.005678") // < 1 → 6 decimals
    }
    
    // MARK: - Total Formatting Tests
    
    func testFormattedTotalLarge() {
        let level = PriceLevel(price: 1.0, size: 1.0, orderCount: 1, total: 2500.7)
        XCTAssertEqual(level.formattedTotal, "2500.7")
    }
    
    func testFormattedTotalSmall() {
        let level = PriceLevel(price: 1.0, size: 1.0, orderCount: 1, total: 0.001234)
        XCTAssertEqual(level.formattedTotal, "0.001234")
    }
    
    // MARK: - Equatable Tests
    
    func testEqualLevels() {
        let level1 = PriceLevel(price: 86000, size: 1.5, orderCount: 3, total: 1.5)
        let level2 = PriceLevel(price: 86000, size: 1.5, orderCount: 3, total: 1.5)
        XCTAssertEqual(level1, level2)
    }
    
    func testUnequalLevels() {
        let level1 = PriceLevel(price: 86000, size: 1.5, orderCount: 3, total: 1.5)
        let level2 = PriceLevel(price: 86100, size: 1.5, orderCount: 3, total: 1.5)
        XCTAssertNotEqual(level1, level2)
    }
}

// MARK: - TradingCoin Tests

final class TradingCoinTests: XCTestCase {
    
    func testAllCases() {
        XCTAssertEqual(TradingCoin.allCases.count, 2)
        XCTAssertTrue(TradingCoin.allCases.contains(.btc))
        XCTAssertTrue(TradingCoin.allCases.contains(.eth))
    }
    
    func testRawValues() {
        XCTAssertEqual(TradingCoin.btc.rawValue, "BTC")
        XCTAssertEqual(TradingCoin.eth.rawValue, "ETH")
    }
    
    func testDisplayNames() {
        XCTAssertEqual(TradingCoin.btc.displayName, "BTC")
        XCTAssertEqual(TradingCoin.eth.displayName, "ETH")
    }
    
    func testIcons() {
        XCTAssertEqual(TradingCoin.btc.icon, "bitcoinsign.circle.fill")
        XCTAssertEqual(TradingCoin.eth.icon, "diamond.fill")
    }
}

// MARK: - PrecisionOption Tests

final class PrecisionOptionTests: XCTestCase {
    
    func testAllCases() {
        XCTAssertEqual(PrecisionOption.allCases.count, 4)
    }
    
    func testRawValues() {
        XCTAssertEqual(PrecisionOption.two.rawValue, 2)
        XCTAssertEqual(PrecisionOption.three.rawValue, 3)
        XCTAssertEqual(PrecisionOption.four.rawValue, 4)
        XCTAssertEqual(PrecisionOption.five.rawValue, 5)
    }
    
    func testDisplayLabels() {
        XCTAssertEqual(PrecisionOption.two.displayLabel, "2 sig")
        XCTAssertEqual(PrecisionOption.five.displayLabel, "5 sig")
    }
}

// MARK: - ConnectionState Tests

final class ConnectionStateTests: XCTestCase {
    
    func testDisplayText() {
        XCTAssertEqual(ConnectionState.disconnected.displayText, "Disconnected")
        XCTAssertEqual(ConnectionState.connecting.displayText, "Connecting...")
        XCTAssertEqual(ConnectionState.connected.displayText, "Live")
        XCTAssertEqual(ConnectionState.error("timeout").displayText, "Error: timeout")
    }
    
    func testEquatable() {
        XCTAssertEqual(ConnectionState.connected, ConnectionState.connected)
        XCTAssertNotEqual(ConnectionState.connected, ConnectionState.disconnected)
        XCTAssertEqual(ConnectionState.error("a"), ConnectionState.error("a"))
        XCTAssertNotEqual(ConnectionState.error("a"), ConnectionState.error("b"))
    }
}
