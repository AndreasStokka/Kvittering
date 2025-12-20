import SwiftUI
import SwiftData

/// View for å vise innholdet i kvitteringslisten (empty state eller liste)
struct ReceiptListContent: View {
    let receipts: [Receipt]
    
    private func formatAmount(_ amount: Decimal) -> String {
        return AmountFormatter.format(amount)
    }
    
    private func formatDate(_ date: Date) -> String {
        return ReceiptDateFormatter.format(date)
    }
    
    var body: some View {
        Section {
            if receipts.isEmpty {
                EmptyReceiptsView()
            } else {
                ForEach(receipts, id: \.id) { receipt in
                    NavigationLink(value: receipt) {
                        ReceiptRowView(receipt: receipt, formatAmount: formatAmount, formatDate: formatDate)
                    }
                    .listRowSeparator(.visible)
                }
            }
        } header: {
            Text("Mine kvitteringer (\(receipts.count))")
        }
    }
}

/// View for tom liste-state
private struct EmptyReceiptsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("Ingen kvitteringer funnet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

/// View for en enkelt kvitteringsrad
private struct ReceiptRowView: View {
    let receipt: Receipt
    let formatAmount: (Decimal) -> String
    let formatDate: (Date) -> String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: CategoryIconHelper.icon(for: receipt.category))
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Color(.systemGray5))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 3) {
                Text(receipt.storeName)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                Text(formatDate(receipt.purchaseDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                let category = Category.migrate(receipt.category)
                Text(category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(formatAmount(receipt.totalAmount))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 8)
    }
}




