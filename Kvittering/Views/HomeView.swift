import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel()
    @State private var showNewSheet = false
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Button {
                        showNewSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.title3)
                            Text("Skann kvittering")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor.opacity(0.85))
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }

                    if !viewModel.recentReceipts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Siste kvitteringer")
                                    .font(.title3.bold())
                                Spacer()
                                Button {
                                    selectedTab = 1 // Switch to "Mine kvitteringer" tab
                                } label: {
                                    Text("Se alle")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            ForEach(viewModel.recentReceipts) { receipt in
                                NavigationLink(value: receipt) {
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
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary.opacity(0.5))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Siste kvitteringer")
                                    .font(.title3.bold())
                                Text("Ingen kvitteringer ennå")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding()
            }
            .navigationDestination(for: Receipt.self) { receipt in
                ReceiptDetailView(receipt: receipt)
            }
            .sheet(isPresented: $showNewSheet) {
                NewReceiptOptionsView(onReceiptSaved: {
                    viewModel.refresh()
                    selectedTab = 0 // Stay on home tab
                })
                .modelContext(modelContext)
            }
            .onAppear {
                viewModel.attach(context: modelContext)
            }
        }
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        return AmountFormatter.format(amount)
    }
    
    private func formatDate(_ date: Date) -> String {
        return ReceiptDateFormatter.format(date)
    }
}

// Forhåndsvisning i lys modus
#Preview("Lys modus") {
    HomeView(selectedTab: .constant(0))
        .modelContainer(for: [Receipt.self, LineItem.self], inMemory: true)
        .environmentObject(ThemeManager())
        .preferredColorScheme(.light)
}

// Forhåndsvisning i mørk modus
#Preview("Mørk modus") {
    HomeView(selectedTab: .constant(0))
        .modelContainer(for: [Receipt.self, LineItem.self], inMemory: true)
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
}
