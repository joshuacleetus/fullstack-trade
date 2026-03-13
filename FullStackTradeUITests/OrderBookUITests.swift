import XCTest

final class OrderBookUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Launch Tests
    
    func testAppLaunches() {
        XCTAssertTrue(app.staticTexts["FullStack Trade"].waitForExistence(timeout: 5))
    }
    
    // MARK: - Coin Selector Tests
    
    func testBTCTabExists() {
        // SwiftUI buttons are matched by their label text
        XCTAssertTrue(app.buttons["BTC"].waitForExistence(timeout: 5))
    }
    
    func testETHTabExists() {
        XCTAssertTrue(app.buttons["ETH"].waitForExistence(timeout: 5))
    }
    
    func testCanSwitchToETH() {
        let ethButton = app.buttons["ETH"]
        XCTAssertTrue(ethButton.waitForExistence(timeout: 5))
        ethButton.tap()
        
        // App title should still be visible
        XCTAssertTrue(app.staticTexts["FullStack Trade"].exists)
    }
    
    func testCanSwitchBetweenCoins() {
        let ethButton = app.buttons["ETH"]
        let btcButton = app.buttons["BTC"]
        
        XCTAssertTrue(ethButton.waitForExistence(timeout: 5))
        ethButton.tap()
        sleep(1)
        btcButton.tap()
        
        XCTAssertTrue(app.staticTexts["FullStack Trade"].exists)
    }
    
    // MARK: - Precision Selector Tests
    
    func testPrecisionTabsExist() {
        XCTAssertTrue(app.buttons["2 sig"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["3 sig"].exists)
        XCTAssertTrue(app.buttons["4 sig"].exists)
        XCTAssertTrue(app.buttons["5 sig"].exists)
    }
    
    func testCanSwitchPrecision() {
        let tab5 = app.buttons["5 sig"]
        XCTAssertTrue(tab5.waitForExistence(timeout: 5))
        tab5.tap()
        XCTAssertTrue(app.staticTexts["FullStack Trade"].exists)
    }
    
    func testCanCycleThroughPrecisions() {
        XCTAssertTrue(app.buttons["3 sig"].waitForExistence(timeout: 5))
        
        app.buttons["3 sig"].tap()
        _ = app.buttons["4 sig"].waitForExistence(timeout: 2)
        app.buttons["4 sig"].tap()
        _ = app.buttons["5 sig"].waitForExistence(timeout: 2)
        app.buttons["5 sig"].tap()
        _ = app.buttons["2 sig"].waitForExistence(timeout: 2)
        app.buttons["2 sig"].tap()
        
        XCTAssertTrue(app.staticTexts["FullStack Trade"].exists)
    }
    
    // MARK: - Column Headers Tests
    
    func testColumnHeaderLabels() {
        // Headers use .textCase(.uppercase)
        XCTAssertTrue(app.staticTexts["PRICE"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["SIZE"].exists)
        XCTAssertTrue(app.staticTexts["#"].exists)
        XCTAssertTrue(app.staticTexts["TOTAL"].exists)
    }
    
    // MARK: - Spread Bar Tests
    
    func testSpreadLabelExists() {
        XCTAssertTrue(app.staticTexts["Spread"].waitForExistence(timeout: 5))
    }
    
    // MARK: - Connection Tests
    
    func testConnectionIndicatorShowsStatus() {
        let live = app.staticTexts["Live"]
        let connecting = app.staticTexts["Connecting..."]
        let exists = live.waitForExistence(timeout: 10) || connecting.exists
        XCTAssertTrue(exists, "Should show Live or Connecting...")
    }
    
    func testEventuallyConnectsLive() {
        let live = app.staticTexts["Live"]
        XCTAssertTrue(live.waitForExistence(timeout: 15), "Should connect to WebSocket")
    }
    
    // MARK: - Interaction Flow Tests
    
    func testFullInteractionFlow() {
        // 1. App launches
        XCTAssertTrue(app.staticTexts["FullStack Trade"].waitForExistence(timeout: 5))
        
        // 2. Switch to ETH
        app.buttons["ETH"].tap()
        sleep(2)
        
        // 3. Change precision to 5 sig
        app.buttons["5 sig"].tap()
        sleep(2)
        
        // 4. Change to 3 sig
        app.buttons["3 sig"].tap()
        sleep(2)
        
        // 5. Switch back to BTC
        app.buttons["BTC"].tap()
        sleep(2)
        
        // 6. App should be stable
        XCTAssertTrue(app.staticTexts["PRICE"].exists)
        XCTAssertTrue(app.staticTexts["Spread"].exists)
        XCTAssertTrue(app.staticTexts["FullStack Trade"].exists)
    }
    
    func testRapidCoinSwitching() {
        XCTAssertTrue(app.buttons["BTC"].waitForExistence(timeout: 5))
        
        for _ in 0..<5 {
            app.buttons["ETH"].tap()
            _ = app.buttons["ETH"].waitForExistence(timeout: 1)
            app.buttons["BTC"].tap()
            _ = app.buttons["BTC"].waitForExistence(timeout: 1)
        }
        
        XCTAssertTrue(app.staticTexts["FullStack Trade"].exists)
    }
    
    func testRapidPrecisionSwitching() {
        XCTAssertTrue(app.buttons["2 sig"].waitForExistence(timeout: 5))
        
        let tabs = ["3 sig", "4 sig", "5 sig", "2 sig"]
        for _ in 0..<3 {
            for tab in tabs {
                app.buttons[tab].tap()
                _ = app.buttons[tab].waitForExistence(timeout: 1)
            }
        }
        
        XCTAssertTrue(app.staticTexts["FullStack Trade"].exists)
    }
}
