import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: OrderBookEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 4) {
                Text("₿")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.67, blue: 0.05))
                Text("BTC")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.92, green: 0.93, blue: 0.95))
                
                Spacer()
                
                // Live dot
                Circle()
                    .fill(Color(red: 0.05, green: 0.82, blue: 0.55))
                    .frame(width: 6, height: 6)
            }
            
            Spacer()
            
            // Mid price
            Text(entry.btcData.formattedMidPrice)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.92, green: 0.93, blue: 0.95))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            
            // Spread
            HStack(spacing: 4) {
                Text("Spread")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(red: 0.42, green: 0.44, blue: 0.50))
                Text(entry.btcData.formattedSpreadPercent)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.20, green: 0.78, blue: 0.90))
            }
            
            Spacer()
            
            // Bid / Ask
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BID")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color(red: 0.05, green: 0.82, blue: 0.55).opacity(0.7))
                    Text(entry.btcData.formattedBid)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.05, green: 0.82, blue: 0.55))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("ASK")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color(red: 0.95, green: 0.28, blue: 0.35).opacity(0.7))
                    Text(entry.btcData.formattedAsk)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.95, green: 0.28, blue: 0.35))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(red: 0.06, green: 0.07, blue: 0.10)
        }
    }
}
