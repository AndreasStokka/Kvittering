import SwiftUI
import SwiftData

struct ReceiptListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ReceiptListViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Søk butikk", text: $viewModel.searchText)
                        .onChange(of: viewModel.searchText) { _, _ in viewModel.load() }
                    Picker("Kategori", selection: Binding(
                        get: { viewModel.selectedCategory },
                        set: { viewModel.selectedCategory = $0; viewModel.load() }
                    )) {
                        Text("Alle kategorier").tag(Category?.none)
                        ForEach(Category.allCases) { category in
                            Text(category.rawValue).tag(Category?.some(category))
                        }
                    }
                }

                Section("Mine kvitteringer") {
                    ForEach(viewModel.receipts, id: \.id) { receipt in
                        NavigationLink(value: receipt) {
                            VStack(alignment: .leading) {
                                Text(receipt.storeName)
                                    .font(.headline)
                                Text(receipt.purchaseDate, style: .date)
                                    .font(.subheadline)
                                Text("kr \(receipt.totalAmount as NSDecimalNumber)")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: Receipt.self) { receipt in
                ReceiptDetailView(receipt: receipt)
            }
            .navigationTitle("Mine kvitteringer")
            .onAppear {
                viewModel.attach(context: modelContext)
            }
        }
    }
}
