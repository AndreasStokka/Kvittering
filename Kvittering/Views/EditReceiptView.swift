import SwiftUI
import SwiftData

struct EditReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: EditReceiptViewModel
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var onSaved: (() -> Void)?

    init(receipt: Receipt? = nil, sourceImage: UIImage? = nil, ocrResult: OCRResult? = nil, onSaved: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: EditReceiptViewModel(receipt: receipt))
        _sourceImage = State(initialValue: sourceImage)
        _ocrResult = State(initialValue: ocrResult)
        self.onSaved = onSaved
    }

    @State private var sourceImage: UIImage?
    @State private var ocrResult: OCRResult?

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "storefront")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    TextField("Butikk", text: $viewModel.storeName)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    DatePicker("Dato", selection: $viewModel.purchaseDate, displayedComponents: .date)
                }
            } header: {
                Text("Butikk og dato")
            }

            Section {
                HStack {
                    Image(systemName: "creditcard")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    TextField("Beløp", text: Binding(
                        get: { viewModel.totalAmountString },
                        set: { newValue in
                            viewModel.totalAmountString = newValue
                            viewModel.updateAmountFromString(newValue)
                        }
                    ))
                        .keyboardType(.decimalPad)
                }
                
                HStack {
                    Image(systemName: "tag")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Picker("Kategori", selection: $viewModel.category) {
                        ForEach(Category.allCases) { category in
                            HStack {
                                Image(systemName: CategoryIconHelper.icon(for: category))
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
            } header: {
                Text("Beløp og kategori")
            }

            Section {
                TextField("Notat", text: $viewModel.note, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Notat")
            }

            if sourceImage != nil {
                Section {
                    if let image = sourceImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                    }
                } header: {
                    Text("Kvitteringsbilde")
                }
            }
        }
        .navigationTitle("Lagre kvittering")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Avbryt") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Lagre") { save() }
                    .disabled(isSaving || !isValid)
            }
        }
        .onAppear {
            viewModel.image = sourceImage
            viewModel.attachContext(modelContext)
            
            if let ocrResult = ocrResult {
                viewModel.applyOCR(result: ocrResult)
            }
        }
        .alert("Kunne ikke lagre", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var isValid: Bool {
        let amount = viewModel.totalAmount
        // Sjekk for NaN og ugyldige verdier
        guard !amount.isNaN && !amount.isInfinite && amount > 0 else {
            return false
        }
        return !viewModel.storeName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    /// Norsk tallformatter for beløp med tusenskilletegn
    private static let norwegianNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "nb_NO")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        return formatter
    }()
    
    private func save() {
        guard isValid else {
            errorMessage = "Vennligst fyll ut butikknavn og beløp"
            return
        }
        
        isSaving = true
        Task {
            do {
                try viewModel.save()
                await MainActor.run {
                    dismiss()
                    onSaved?()
                }
            } catch {
                await MainActor.run {
                    if let nsError = error as NSError? {
                        errorMessage = nsError.localizedDescription
                    } else {
                        errorMessage = "Kunne ikke lagre kvitteringen: \(error.localizedDescription)"
                    }
                }
            }
            await MainActor.run {
                isSaving = false
            }
        }
    }
    
}
