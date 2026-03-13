import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: OrderBookEntry
    
    var body: some View {
        HStack(spacing: 0) {
            // BTC Column
            coinColumn(data: entry.btcData, symbol: "₿", symbolColor: Color(red: 0.95, green: 0.67, blue: 0.05))
            
            // Divider
            Rectangle()
                .fill(Color(red: 0.20, green: 0.21, blue: 0.25))
                .frame(width: 1)
                .padding(.vertical, 8)
            
            // ETH Column
            coinColumn(data: entry.ethData, symbol: "Ξ", symbolColor: Color(red: 0.45, green: 0.55, blue: 0.95))
        }
        .containerBackground(for: .widget) {
            Color(red: 0.06, green: 0.07, blue: 0.10)
        }
    }
    
    @ViewBuilder
    private func coinColumn(data: CoinSnapshot, symbol: String, symbolColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack(spacing: 4) {
                Text(symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(symbolColor)
                Text(data.coin)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.92, green: 0.93, blue: 0.95))
                
                Spacer()
                
                Circle()
                    .fill(Color(red: 0.05, green: 0.82, blue: 0.55))
                    .frame(width: 5, height: 5)
            }
            
            Spacer()
            
            // Mid price
            Text(data.formattedMidPrice)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.92, green: 0.93, blue: 0.95))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            
            // Spread
            HStack(spacing: 3) {
                Text("Spread")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color(red: 0.42, green: 0.44, blue: 0.50))
                Text(data.formattedSpreadPercent)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.20, green: 0.78, blue: 0.90))
            }
            
            Spacer()
            
            // Bid / Ask row
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("BID")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Color(red: 0.05, green: 0.82, blue: 0.55).opacity(0.7))
                    Text(data.formattedBid)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.05, green: 0.82, blue: 0.55))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    Text("ASK")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Color(red: 0.95, green: 0.28, blue: 0.35).opacity(0.7))
                    Text(data.formattedAsk)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.95, green: 0.28, blue: 0.35))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
    }
}
