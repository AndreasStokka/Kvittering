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
                    Text("Kvittering")
                        .font(.largeTitle.bold())

                    Button {
                        showNewSheet = true
                    } label: {
                        Label("Skann kvittering", systemImage: "doc.text.viewfinder")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }

                    if !viewModel.recentReceipts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Siste kvitteringer")
                                    .font(.headline)
                                Spacer()
                                Button {
                                    selectedTab = 1 // Switch to "Mine kvitteringer" tab
                                } label: {
                                    Text("Se alle")
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                }
                            }
                            
                            ForEach(viewModel.recentReceipts) { receipt in
                                NavigationLink(value: receipt) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(receipt.storeName)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Text(receipt.purchaseDate, style: .date)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(formatAmount(receipt.totalAmount))
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Siste kvitteringer")
                                .font(.headline)
                            Text("Ingen kvitteringer ennå")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        selectedTab = 1 // Switch to "Mine kvitteringer" tab
                    } label: {
                        Label("Mine kvitteringer", systemImage: "list.bullet")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .cornerRadius(12)
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
        // Sjekk for NaN og ugyldige verdier
        if amount.isNaN || amount.isInfinite {
            return "kr 0,00"
        }
        return "kr \(amount as NSDecimalNumber)"
    }
}
