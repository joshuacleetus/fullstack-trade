import SwiftUI

struct OrderBookView: View {
    @State private var viewModel = OrderBookViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Controls
                controlsBar
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Column headers
                columnHeaders
                
                // Order book content
                GeometryReader { geometry in
                    let sectionHeight = max(0, (geometry.size.height - 44) / 2)
                    VStack(spacing: 0) {
                        // Asks (top half)
                        asksSection(height: sectionHeight)
                        
                        // Spread bar
                        spreadBar
                        
                        // Bids (bottom half)
                        bidsSection(height: sectionHeight)
                    }
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .foregroundColor(.accentTeal)
                            .font(.headline)
                        Text("FullStack Trade")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    connectionIndicator
                }
            }
            .toolbarBackground(Color.bgSecondary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
    
    // MARK: - Controls Bar
    
    private var controlsBar: some View {
        VStack(spacing: 12) {
            // Coin Selector
            HStack(spacing: 0) {
                ForEach(TradingCoin.allCases) { coin in
                    CoinTab(
                        coin: coin,
                        isSelected: viewModel.selectedCoin == coin
                    ) {
                        viewModel.selectCoin(coin)
                    }
                }
            }
            .background(Color.bgTertiary)
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .accessibilityIdentifier("coinSelector")
            
            // Precision Selector
            HStack(spacing: 0) {
                ForEach(PrecisionOption.allCases) { precision in
                    PrecisionTab(
                        precision: precision,
                        isSelected: viewModel.selectedPrecision == precision
                    ) {
                        viewModel.selectPrecision(precision)
                    }
                }
            }
            .background(Color.bgTertiary)
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .accessibilityIdentifier("precisionSelector")
        }
        .padding(.vertical, 12)
        .background(Color.bgSecondary)
    }
    
    // MARK: - Column Headers
    
    private var columnHeaders: some View {
        HStack {
            Text("Price")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Size")
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text("#")
                .frame(width: 36, alignment: .center)
            Text("Total")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.textTertiary)
        .textCase(.uppercase)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.bgSecondary)
        .accessibilityIdentifier("columnHeaders")
    }
    
    // MARK: - Asks Section
    
    private func asksSection(height: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.asks) { level in
                    PriceLevelRow(
                        level: level,
                        side: .ask,
                        maxTotal: viewModel.maxTotalAsks,
                        isFlashing: viewModel.flashingPrices.contains(level.price)
                    )
                }
            }
        }
        .frame(height: height)
        .defaultScrollAnchor(.bottom)
        .accessibilityIdentifier("asksSection")
    }
    
    // MARK: - Bids Section
    
    private func bidsSection(height: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.bids) { level in
                    PriceLevelRow(
                        level: level,
                        side: .bid,
                        maxTotal: viewModel.maxTotalBids,
                        isFlashing: viewModel.flashingPrices.contains(level.price)
                    )
                }
            }
        }
        .frame(height: height)
        .accessibilityIdentifier("bidsSection")
    }
    
    // MARK: - Spread Bar
    
    private var spreadBar: some View {
        HStack {
            HStack(spacing: 4) {
                // Mid-price direction arrow
                Image(systemName: midPriceArrowIcon)
                    .font(.caption2)
                    .foregroundColor(midPriceArrowColor)
                Text("Spread")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.textTertiary)
            
            Spacer()
            
            if viewModel.midPrice > 0 {
                // Mid-price display
                Text(formatMidPrice(viewModel.midPrice))
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(midPriceArrowColor)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: viewModel.midPrice)
            }
            
            Spacer()
            
            if viewModel.spread > 0 {
                HStack(spacing: 8) {
                    Text(formatSpread(viewModel.spread))
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("(\(String(format: "%.3f", viewModel.spreadPercent))%)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.bgTertiary)
        .accessibilityIdentifier("spreadBar")
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.white.opacity(0.05)),
            alignment: .top
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.white.opacity(0.05)),
            alignment: .bottom
        )
    }
    
    // MARK: - Mid-Price Direction Helpers
    
    private var midPriceArrowIcon: String {
        switch viewModel.midPriceDirection {
        case 1: return "arrowtriangle.up.fill"
        case -1: return "arrowtriangle.down.fill"
        default: return "arrow.up.arrow.down"
        }
    }
    
    private var midPriceArrowColor: Color {
        switch viewModel.midPriceDirection {
        case 1: return .askGreen
        case -1: return .bidRed
        default: return .white
        }
    }
    
    // MARK: - Connection Indicator
    
    private var connectionIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(connectionColor)
                .frame(width: 8, height: 8)
                .shadow(color: connectionColor.opacity(0.6), radius: 3)
            
            Text(viewModel.connectionState.displayText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.bgTertiary)
        .cornerRadius(12)
        .accessibilityIdentifier("connectionIndicator")
    }
    
    private var connectionColor: Color {
        switch viewModel.connectionState {
        case .connected: return .askGreen
        case .connecting: return .yellow
        case .disconnected, .error: return .bidRed
        }
    }
    
    private func formatSpread(_ spread: Double) -> String {
        if spread >= 1 {
            return String(format: "%.2f", spread)
        } else {
            return String(format: "%.4f", spread)
        }
    }
    
    private func formatMidPrice(_ price: Double) -> String {
        if price >= 1000 {
            return String(format: "%.1f", price)
        } else if price >= 100 {
            return String(format: "%.2f", price)
        } else {
            return String(format: "%.4f", price)
        }
    }
}

// MARK: - Coin Tab

struct CoinTab: View {
    let coin: TradingCoin
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: coin.icon)
                    .font(.subheadline)
                Text(coin.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? Color.accentTeal.opacity(0.2)
                    : Color.clear
            )
            .overlay(
                isSelected
                    ? RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentTeal.opacity(0.4), lineWidth: 1)
                    : nil
            )
        }
        .cornerRadius(10)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .accessibilityLabel(coin.displayName)
        .accessibilityIdentifier("coinTab_\(coin.rawValue)")
    }
}

// MARK: - Precision Tab

struct PrecisionTab: View {
    let precision: PrecisionOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(precision.displayLabel)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundColor(isSelected ? .white : .textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? Color.white.opacity(0.1)
                        : Color.clear
                )
        }
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .accessibilityLabel(precision.displayLabel)
        .accessibilityIdentifier("precisionTab_\(precision.rawValue)")
    }
}

// MARK: - Preview

#Preview {
    OrderBookView()
        .preferredColorScheme(.dark)
}
