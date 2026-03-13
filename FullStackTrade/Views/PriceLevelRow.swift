import SwiftUI

enum OrderSide {
    case bid
    case ask
    
    var barColor: Color {
        switch self {
        case .bid: return .askGreen
        case .ask: return .bidRed
        }
    }
    
    var priceColor: Color {
        switch self {
        case .bid: return .askGreen
        case .ask: return .bidRed
        }
    }
}

struct PriceLevelRow: View {
    let level: PriceLevel
    let side: OrderSide
    let maxTotal: Double
    
    private var depthPercent: CGFloat {
        guard maxTotal > 0 else { return 0 }
        return CGFloat(level.total / maxTotal)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: side == .bid ? .trailing : .trailing) {
                // Depth bar background
                Rectangle()
                    .fill(side.barColor.opacity(0.12))
                    .frame(width: geometry.size.width * depthPercent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                // Content
                HStack(spacing: 0) {
                    // Price
                    Text(level.formattedPrice)
                        .foregroundColor(side.priceColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Size
                    Text(level.formattedSize)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    // Total (cumulative)
                    Text(level.formattedTotal)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .padding(.horizontal, 16)
            }
        }
        .frame(height: 28)
    }
}

#Preview {
    VStack(spacing: 0) {
        PriceLevelRow(
            level: PriceLevel(price: 68420.5, size: 1.234, orderCount: 5, total: 3.567),
            side: .ask,
            maxTotal: 10.0
        )
        PriceLevelRow(
            level: PriceLevel(price: 68415.0, size: 2.100, orderCount: 3, total: 2.100),
            side: .bid,
            maxTotal: 10.0
        )
    }
    .background(Color.bgPrimary)
    .preferredColorScheme(.dark)
}
