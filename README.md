# FullStack Trade

A native iOS orderbook widget built with SwiftUI that displays real-time Level 2 order book data from Hyperliquid's WebSocket API.

## Features

- 📊 **Live Orderbook** — Real-time bids and asks with depth visualization
- 🪙 **Multi-Symbol** — Support for BTC and ETH trading pairs
- 🎯 **Adjustable Precision** — Configurable significant figures (2-5)
- 📱 **Native SwiftUI** — Built entirely with SwiftUI and modern iOS APIs
- 🏗️ **MVVM Architecture** — Clean separation of concerns
- 🔄 **Auto-Reconnect** — Resilient WebSocket connection with exponential backoff
- 🌙 **Dark Mode** — Professional trading-app aesthetic

## Architecture

```
FullStackTrade/
├── App/                    # App entry point
├── Models/                 # Data models (WebSocket messages, OrderBook)
├── Services/               # WebSocket service layer
├── ViewModels/             # Business logic and state management
├── Views/                  # SwiftUI views
└── Theme/                  # Colors and design tokens
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Clone this repository
2. Open `FullStackTrade.xcodeproj` in Xcode
3. Build and run on a simulator or device

## API

This app connects to the Hyperliquid WebSocket API:
- **Endpoint**: `wss://api.hyperliquid.xyz/ws`
- **Subscription**: L2 Book data with configurable precision

## License

Private — All rights reserved.
