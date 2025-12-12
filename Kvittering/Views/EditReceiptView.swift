import SwiftUI
import SwiftData

struct EditReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: EditReceiptViewModel
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(receipt: Receipt? = nil, sourceImage: UIImage? = nil) {
        _viewModel = StateObject(wrappedValue: EditReceiptViewModel(context: ModelContext.preview, receipt: receipt))
        _sourceImage = State(initialValue: sourceImage)
    }

    @State private var sourceImage: UIImage?

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
                    .disabled(isSaving)
            }
        }
        .onAppear {
            viewModel.image = sourceImage
            viewModel.attachContext(modelContext)
        }
        .alert("Kunne ikke lagre", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                try viewModel.save()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
