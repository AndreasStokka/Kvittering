import SwiftUI
import SwiftData

struct ReceiptListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ReceiptListViewModel()

    var body: some View {
        NavigationStack {
            List {
                ReceiptListFiltersView(viewModel: viewModel)
                ReceiptListContent(receipts: viewModel.receipts)
            }
            .listStyle(.insetGrouped)
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
