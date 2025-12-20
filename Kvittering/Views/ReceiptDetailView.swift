import SwiftUI
import SwiftData

struct ReceiptDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReceiptDetailViewModel
    @State private var showShare = false
    @State private var showEdit = false
    @State private var showDeleteAlert = false
    @State private var showConsumerGuide = false
    @State private var deleteError: String?

    init(receipt: Receipt) {
        _viewModel = StateObject(wrappedValue: ReceiptDetailViewModel(receipt: receipt))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let image = viewModel.image() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                }

                // Main info card
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.receipt.storeName)
                            .font(.title.bold())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text(formatDate(viewModel.receipt.purchaseDate))
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            
                            let category = Category.migrate(viewModel.receipt.category)
                            Label(category.rawValue, systemImage: CategoryIconHelper.icon(for: category))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Totalt beløp")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(formatAmount(viewModel.receipt.totalAmount))
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Warranty info card
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shield.checkerboard")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor.opacity(0.8))
                            Text("Reklamasjonsrett og Garanti")
                                .font(.headline)
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.secondary)
                            Text(viewModel.timeElapsedText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("I Norge har du sterke rettigheter når du kjøper noe.                            Selv om mange produsenter, som Apple,bare gir 1 års garanti, har du likevel ofte 5 års reklamasjonsrett. Det gjelder for ting som skal vare vesentlig lenger enn 2 år, som for eksempel mobiltelefoner, PC-er og hvitevarer.                            For andre varer som ikke er ment å vare så lenge, gjelder 2 års reklamasjonsrett.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                showConsumerGuide = true
                            } label: {
                                HStack {
                                    Text("Les mer om forbrukerrettigheter")
                                    Image(systemName: "arrow.right.circle.fill")
                                }
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.accentColor.opacity(0.8))
                            }
                        }
                    }
                }
                .groupBoxStyle(.automatic)

                // TODO: Enable in v1.1 - LineItems UI deaktivert i v1.0
                // LineItems tolkes fortsatt i OCR og logges til konsollen, men vises ikke i UI
                // Bakgrunnslogikken i OCRService og Receipt-modellen er intakt for fremtidig bruk
                // if !viewModel.validLineItems.isEmpty {
                //     VStack(alignment: .leading, spacing: 12) {
                //         Text("Varelinjer")
                //             .font(.headline)
                //         
                //         ForEach(viewModel.validLineItems, id: \.id) { item in
                //             HStack {
                //                 VStack(alignment: .leading, spacing: 4) {
                //                     Text(item.descriptionText)
                //                         .font(.body)
                //                     Text("\(formatQuantity(item.quantity))x")
                //                         .font(.caption)
                //                         .foregroundStyle(.secondary)
                //                 }
                //                 Spacer()
                //                 Text(formatAmount(item.lineTotal))
                //                     .font(.headline)
                //             }
                //             .padding(.vertical, 8)
                //             .padding(.horizontal, 12)
                //             .background(Color(.systemGray6))
                //             .cornerRadius(8)
                //         }
                //     }
                //     .padding()
                //     .background(Color(.systemBackground))
                //     .cornerRadius(12)
                // }

                if let note = viewModel.receipt.note, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notat")
                            .font(.headline)
                        Text(note)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
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
            NavigationStack {
                EditReceiptView(receipt: viewModel.receipt)
                    .modelContext(modelContext)
            }
        }
        .alert("Slett kvittering?", isPresented: $showDeleteAlert) {
            Button("Slett", role: .destructive) {
                do {
                    try viewModel.delete()
                    dismiss()
                } catch {
                    deleteError = error.localizedDescription
                }
            }
            Button("Avbryt", role: .cancel) {}
        }
        .alert("Kunne ikke slette", isPresented: Binding(get: { deleteError != nil }, set: { _ in deleteError = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteError ?? "")
        }
        .sheet(isPresented: $showConsumerGuide) {
            NavigationStack {
                ConsumerGuideView()
            }
        }
        .onAppear {
            viewModel.attach(context: modelContext)
            viewModel.prepareShare()
        }
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        return AmountFormatter.format(amount)
    }
    
    private func formatDate(_ date: Date) -> String {
        return ReceiptDateFormatter.format(date)
    }
    
    private func formatQuantity(_ quantity: Decimal) -> String {
        // Valider quantity før formatering
        if quantity.isNaN || quantity.isInfinite {
            return "1"
        }
        let nsDecimal = NSDecimalNumber(decimal: quantity)
        let doubleValue = nsDecimal.doubleValue
        // Valider doubleValue før formatering
        if doubleValue.isNaN || doubleValue.isInfinite {
            return "1"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: nsDecimal) ?? "1"
    }
}
