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
            // #region agent log
            let logData: [String: Any] = [
                "sessionId": "debug-session",
                "runId": "run1",
                "hypothesisId": "C",
                "location": "EditReceiptView.swift:67",
                "message": "EditReceiptView onAppear",
                "data": [
                    "hasModelContext": true,
                    "hasSourceImage": sourceImage != nil,
                    "hasOcrResult": ocrResult != nil
                ],
                "timestamp": Int(Date().timeIntervalSince1970 * 1000)
            ]
            if let logJson = try? JSONSerialization.data(withJSONObject: logData),
               let logString = String(data: logJson, encoding: .utf8) {
                if let existingLog = try? String(contentsOfFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", encoding: .utf8) {
                    try? (existingLog + "\n" + logString).write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
                } else {
                    try? logString.write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
                }
            }
            // #endregion
            
            viewModel.image = sourceImage
            viewModel.attachContext(modelContext)
            
            // #region agent log
            let logData2: [String: Any] = [
                "sessionId": "debug-session",
                "runId": "run1",
                "hypothesisId": "C",
                "location": "EditReceiptView.swift:85",
                "message": "Etter attachContext",
                "data": ["attachContextCalled": true],
                "timestamp": Int(Date().timeIntervalSince1970 * 1000)
            ]
            if let logJson = try? JSONSerialization.data(withJSONObject: logData2),
               let logString = String(data: logJson, encoding: .utf8),
               let existingLog = try? String(contentsOfFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", encoding: .utf8) {
                try? (existingLog + "\n" + logString).write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
            }
            // #endregion
            
            // Bruk OCR-resultat hvis tilgjengelig
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
        // #region agent log
        let logData: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "run1",
            "hypothesisId": "D",
            "location": "EditReceiptView.swift:86",
            "message": "save() kalt",
            "data": [
                "isValid": isValid,
                "storeName": viewModel.storeName,
                "totalAmount": "\(viewModel.totalAmount)"
            ],
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        if let logJson = try? JSONSerialization.data(withJSONObject: logData),
           let logString = String(data: logJson, encoding: .utf8) {
            if let existingLog = try? String(contentsOfFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", encoding: .utf8) {
                try? (existingLog + "\n" + logString).write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
            } else {
                try? logString.write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
            }
        }
        // #endregion
        
        guard isValid else {
            errorMessage = "Vennligst fyll ut butikknavn og beløp"
            return
        }
        
        isSaving = true
        Task {
            do {
                try viewModel.save()
                
                // #region agent log
                let logData2: [String: Any] = [
                    "sessionId": "debug-session",
                    "runId": "run1",
                    "hypothesisId": "D",
                    "location": "EditReceiptView.swift:115",
                    "message": "Lagring vellykket",
                    "data": [:],
                    "timestamp": Int(Date().timeIntervalSince1970 * 1000)
                ]
                if let logJson = try? JSONSerialization.data(withJSONObject: logData2),
                   let logString = String(data: logJson, encoding: .utf8),
                   let existingLog = try? String(contentsOfFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", encoding: .utf8) {
                    try? (existingLog + "\n" + logString).write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
                }
                // #endregion
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                // #region agent log
                let logData3: [String: Any] = [
                    "sessionId": "debug-session",
                    "runId": "run1",
                    "hypothesisId": "D",
                    "location": "EditReceiptView.swift:130",
                    "message": "Lagring feilet",
                    "data": ["error": error.localizedDescription],
                    "timestamp": Int(Date().timeIntervalSince1970 * 1000)
                ]
                if let logJson = try? JSONSerialization.data(withJSONObject: logData3),
                   let logString = String(data: logJson, encoding: .utf8),
                   let existingLog = try? String(contentsOfFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", encoding: .utf8) {
                    try? (existingLog + "\n" + logString).write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
                }
                // #endregion
                
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
