import Foundation

// MARK: - Outgoing Messages

struct WebSocketMessage: Encodable {
    let method: String
    let subscription: WebSocketSubscription
}

struct WebSocketSubscription: Codable {
    let type: String
    let coin: String
    let nSigFigs: Int?
    
    enum CodingKeys: String, CodingKey {
        case type, coin, nSigFigs
    }
}

// MARK: - Incoming Messages

struct WebSocketResponse: Decodable {
    let channel: String
    let data: WsBookData
}

struct WsBookData: Decodable {
    let coin: String
    let levels: [[WsLevel]]
    let time: Int
}

struct WsLevel: Decodable {
    let px: String
    let sz: String
    let n: Int
}
