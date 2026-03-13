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
                    VStack(spacing: 0) {
                        // Asks (top half)
                        asksSection(height: (geometry.size.height - 44) / 2)
                        
                        // Spread bar
                        spreadBar
                        
                        // Bids (bottom half)
                        bidsSection(height: (geometry.size.height - 44) / 2)
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
    }
    
    // MARK: - Asks Section
    
    private func asksSection(height: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.asks) { level in
                    PriceLevelRow(
                        level: level,
                        side: .ask,
                        maxTotal: viewModel.maxTotalAsks
                    )
                }
            }
        }
        .frame(height: height)
        .defaultScrollAnchor(.bottom)
    }
    
    // MARK: - Bids Section
    
    private func bidsSection(height: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.bids) { level in
                    PriceLevelRow(
                        level: level,
                        side: .bid,
                        maxTotal: viewModel.maxTotalBids
                    )
                }
            }
        }
        .frame(height: height)
    }
    
    // MARK: - Spread Bar
    
    private var spreadBar: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption2)
                Text("Spread")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.textTertiary)
            
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
    }
}

// MARK: - Preview

#Preview {
    OrderBookView()
        .preferredColorScheme(.dark)
}
