import SwiftUI
import SwiftData

struct EditReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: EditReceiptViewModel
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(receipt: Receipt? = nil, sourceImage: UIImage? = nil, ocrResult: OCRResult? = nil) {
        _viewModel = StateObject(wrappedValue: EditReceiptViewModel(receipt: receipt))
        _sourceImage = State(initialValue: sourceImage)
        _ocrResult = State(initialValue: ocrResult)
    }

    @State private var sourceImage: UIImage?
    @State private var ocrResult: OCRResult?

    var body: some View {
        Form {
            Section("Butikk og dato") {
                TextField("Butikk", text: $viewModel.storeName)
                DatePicker("Dato", selection: $viewModel.purchaseDate, displayedComponents: .date)
            }

            Section("Beløp og kategori") {
                TextField("Beløp", value: $viewModel.totalAmount, format: .number)
                    .keyboardType(.decimalPad)
                Picker("Kategori", selection: $viewModel.category) {
                    ForEach(Category.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
            }

            Section("Garanti") {
                Toggle("Har garanti", isOn: $viewModel.hasWarranty)
                Stepper("Garantitid (år): \(viewModel.warrantyYears)", value: $viewModel.warrantyYears, in: 0...10)
            }

            Section("Notat") {
                TextField("Notat", text: $viewModel.note, axis: .vertical)
            }

            Section("Bilde") {
                if let image = sourceImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                } else {
                    Text("Ingen billede valgt")
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
        !viewModel.storeName.trimmingCharacters(in: .whitespaces).isEmpty && viewModel.totalAmount > 0
    }
    
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
