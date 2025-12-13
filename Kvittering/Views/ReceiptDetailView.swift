import SwiftUI
import SwiftData

struct ReceiptDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReceiptDetailViewModel
    @State private var showShare = false
    @State private var showEdit = false
    @State private var showDeleteAlert = false

    init(receipt: Receipt) {
        _viewModel = StateObject(wrappedValue: ReceiptDetailViewModel(receipt: receipt))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let image = viewModel.image() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                }

                Text(viewModel.receipt.storeName)
                    .font(.title2.bold())
                Text(viewModel.receipt.purchaseDate, style: .date)
                Text("kr \(viewModel.receipt.totalAmount as NSDecimalNumber)")
                Text(viewModel.receipt.category)
                Text(viewModel.warrantyStatusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !viewModel.receipt.lineItems.isEmpty {
                    Divider()
                    Text("Varelinjer").font(.headline)
                    ForEach(viewModel.receipt.lineItems, id: \.id) { item in
                        HStack {
                            Text(item.descriptionText)
                            Spacer()
                            Text("\(item.quantity as NSDecimalNumber)x")
                            Text("kr \(item.lineTotal as NSDecimalNumber)")
                        }
                    }
                }

                if let note = viewModel.receipt.note, !note.isEmpty {
                    Divider()
                    Text("Notat")
                        .font(.headline)
                    Text(note)
                }
            }
            .padding()
        }
        .navigationTitle("Detaljer")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Del") {
                    viewModel.prepareShare()
                    showShare = true
                }
                Button("Rediger") { showEdit = true }
                Button(role: .destructive) { showDeleteAlert = true } label: { Image(systemName: "trash") }
            }
        }
        .sheet(isPresented: $showShare) {
            ActivityView(activityItems: viewModel.shareItems)
        }
        .sheet(isPresented: $showEdit) {
            EditReceiptView(receipt: viewModel.receipt)
        }
        .alert("Slett kvittering?", isPresented: $showDeleteAlert) {
            Button("Slett", role: .destructive) {
                try? viewModel.delete()
                dismiss()
            }
            Button("Avbryt", role: .cancel) {}
        }
        .onAppear {
            viewModel.attach(context: modelContext)
            viewModel.prepareShare()
        }
    }
}
