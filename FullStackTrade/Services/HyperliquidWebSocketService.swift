import Foundation
import Combine

// MARK: - WebSocket Service Protocol

protocol WebSocketServiceProtocol {
    var bookPublisher: AnyPublisher<WsBookData, Never> { get }
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> { get }
    func connect()
    func disconnect()
    func subscribe(coin: String, nSigFigs: Int?)
    func unsubscribe(coin: String, nSigFigs: Int?)
}

// MARK: - Hyperliquid WebSocket Service

final class HyperliquidWebSocketService: NSObject, WebSocketServiceProtocol {
    
    // MARK: - Constants
    
    private static let webSocketURL = URL(string: "wss://api.hyperliquid.xyz/ws")!
    private static let maxReconnectAttempts = 10
    private static let baseReconnectDelay: TimeInterval = 1.0
    
    // MARK: - Publishers
    
    private let bookSubject = PassthroughSubject<WsBookData, Never>()
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    
    var bookPublisher: AnyPublisher<WsBookData, Never> {
        bookSubject.eraseToAnyPublisher()
    }
    
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var reconnectAttempts = 0
    private var isIntentionalDisconnect = false
    private var currentSubscription: (coin: String, nSigFigs: Int?)?
    private let decoder = JSONDecoder()
    private var pingTimer: Timer?
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
    }
    
    deinit {
        isIntentionalDisconnect = true
        pingTimer?.invalidate()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard connectionStateSubject.value != .connected,
              connectionStateSubject.value != .connecting else { return }
        
        isIntentionalDisconnect = false
        connectionStateSubject.send(.connecting)
        
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
        
        webSocketTask = session?.webSocketTask(with: Self.webSocketURL)
        webSocketTask?.resume()
        
        receiveMessage()
        startPingTimer()
    }
    
    func disconnect() {
        isIntentionalDisconnect = true
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil
        connectionStateSubject.send(.disconnected)
    }
    
    // MARK: - Subscription Management
    
    func subscribe(coin: String, nSigFigs: Int?) {
        currentSubscription = (coin, nSigFigs)
        
        let subscription = WebSocketSubscription(type: "l2Book", coin: coin, nSigFigs: nSigFigs)
        let message = WebSocketMessage(method: "subscribe", subscription: subscription)
        
        sendMessage(message)
    }
    
    func unsubscribe(coin: String, nSigFigs: Int?) {
        let subscription = WebSocketSubscription(type: "l2Book", coin: coin, nSigFigs: nSigFigs)
        let message = WebSocketMessage(method: "unsubscribe", subscription: subscription)
        
        sendMessage(message)
    }
    
    // MARK: - Private Methods
    
    private func sendMessage<T: Encodable>(_ message: T) {
        do {
            let data = try JSONEncoder().encode(message)
            guard let jsonString = String(data: data, encoding: .utf8) else { return }
            
            webSocketTask?.send(.string(jsonString)) { [weak self] error in
                if let error = error {
                    print("[WebSocket] Send error: \(error.localizedDescription)")
                    self?.handleDisconnection()
                }
            }
        } catch {
            print("[WebSocket] Encoding error: \(error.localizedDescription)")
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleTextMessage(text)
                case .data(let data):
                    self.handleDataMessage(data)
                @unknown default:
                    break
                }
                // Continue listening
                self.receiveMessage()
                
            case .failure(let error):
                print("[WebSocket] Receive error: \(error.localizedDescription)")
                self.handleDisconnection()
            }
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        handleDataMessage(data)
    }
    
    private func handleDataMessage(_ data: Data) {
        // Try to parse as book data
        do {
            let response = try decoder.decode(WebSocketResponse.self, from: data)
            if response.channel == "l2Book" {
                DispatchQueue.main.async { [weak self] in
                    self?.bookSubject.send(response.data)
                }
            }
        } catch {
            // May be a subscription confirmation or other message type - ignore
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[WebSocket] Non-book message: \(jsonString.prefix(200))")
            }
        }
    }
    
    private func handleDisconnection() {
        guard !isIntentionalDisconnect else { return }
        
        connectionStateSubject.send(.disconnected)
        pingTimer?.invalidate()
        pingTimer = nil
        
        attemptReconnect()
    }
    
    private func attemptReconnect() {
        guard reconnectAttempts < Self.maxReconnectAttempts else {
            connectionStateSubject.send(.error("Max reconnect attempts reached"))
            return
        }
        
        reconnectAttempts += 1
        let delay = Self.baseReconnectDelay * pow(2.0, Double(reconnectAttempts - 1))
        let cappedDelay = min(delay, 30.0) // Cap at 30 seconds
        
        print("[WebSocket] Reconnecting in \(cappedDelay)s (attempt \(reconnectAttempts))")
        connectionStateSubject.send(.connecting)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + cappedDelay) { [weak self] in
            guard let self = self, !self.isIntentionalDisconnect else { return }
            
            self.webSocketTask?.cancel(with: .goingAway, reason: nil)
            self.webSocketTask = nil
            
            self.webSocketTask = self.session?.webSocketTask(with: Self.webSocketURL)
            self.webSocketTask?.resume()
            self.receiveMessage()
            self.startPingTimer()
        }
    }
    
    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if let error = error {
                    print("[WebSocket] Ping error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension HyperliquidWebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("[WebSocket] Connected")
        reconnectAttempts = 0
        connectionStateSubject.send(.connected)
        
        // Re-subscribe if we had an active subscription
        if let sub = currentSubscription {
            subscribe(coin: sub.coin, nSigFigs: sub.nSigFigs)
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("[WebSocket] Closed with code: \(closeCode)")
        if !isIntentionalDisconnect {
            handleDisconnection()
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("[WebSocket] Task error: \(error.localizedDescription)")
            if !isIntentionalDisconnect {
                handleDisconnection()
            }
        }
    }
}
