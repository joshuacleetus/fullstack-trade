import Foundation
import Combine
@testable import FullStack_Trade

/// Mock WebSocket service for unit testing
final class MockWebSocketService: WebSocketServiceProtocol {
    
    // MARK: - Publishers
    
    private let bookSubject = PassthroughSubject<WsBookData, Never>()
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    
    var bookPublisher: AnyPublisher<WsBookData, Never> {
        bookSubject.eraseToAnyPublisher()
    }
    
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Call Tracking
    
    var connectCallCount = 0
    var disconnectCallCount = 0
    var subscriptions: [(coin: String, nSigFigs: Int?)] = []
    var unsubscriptions: [(coin: String, nSigFigs: Int?)] = []
    
    // MARK: - Protocol Methods
    
    func connect() {
        connectCallCount += 1
    }
    
    func disconnect() {
        disconnectCallCount += 1
    }
    
    func subscribe(coin: String, nSigFigs: Int?) {
        subscriptions.append((coin, nSigFigs))
    }
    
    func unsubscribe(coin: String, nSigFigs: Int?) {
        unsubscriptions.append((coin, nSigFigs))
    }
    
    // MARK: - Test Helpers
    
    func simulateConnected() {
        connectionStateSubject.send(.connected)
    }
    
    func simulateDisconnected() {
        connectionStateSubject.send(.disconnected)
    }
    
    func simulateError(_ message: String) {
        connectionStateSubject.send(.error(message))
    }
    
    func simulateBookUpdate(_ data: WsBookData) {
        bookSubject.send(data)
    }
    
    /// Creates a realistic book data snapshot for testing
    static func makeBookData(
        bidPrices: [(String, String, Int)] = [("86000", "1.5", 5), ("85900", "2.0", 3)],
        askPrices: [(String, String, Int)] = [("86100", "1.2", 4), ("86200", "0.8", 2)],
        time: Int = 1700000000000
    ) -> WsBookData {
        let bids = bidPrices.map { WsLevel(px: $0.0, sz: $0.1, n: $0.2) }
        let asks = askPrices.map { WsLevel(px: $0.0, sz: $0.1, n: $0.2) }
        return WsBookData(coin: "BTC", levels: [bids, asks], time: time)
    }
}
