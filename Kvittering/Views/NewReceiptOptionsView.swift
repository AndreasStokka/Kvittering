import SwiftUI
import PhotosUI
import VisionKit

struct NewReceiptOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showScanner = false
    @State private var showCameraPicker = false
    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var presentEditor = false
    @State private var isProcessingOCR = false
    @State private var ocrResult: OCRResult?
    @State private var ocrError: String?
    @State private var scannerError: String?
    
    private let ocrService = OCRService()

    var body: some View {
        NavigationStack {
            List {
                #if targetEnvironment(simulator)
                Button("Skann med kamera (begrenset i simulator)") { 
                    scannerError = "Dokument-scanner fungerer ikke pålitelig i simulator. Vennligst bruk 'Velg fra Bilder' for å teste med eksisterende bilder."
                }
                #else
                Button("Skann med kamera") { showScanner = true }
                #endif
                Button("Velg fra Bilder") { showPhotoPicker = true }
                Button("Legg inn kvittering manuelt") { presentEditor = true }
            }
            .navigationTitle("Ny kvittering")
            .sheet(isPresented: $presentEditor) {
                EditReceiptView(sourceImage: selectedImage, ocrResult: ocrResult)
                    .modelContext(modelContext)
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(image: $selectedImage)
                    .onDisappear {
                        if selectedImage != nil {
                            processOCR()
                        }
                    }
            }
            .sheet(isPresented: $showScanner) {
                DocumentScanner(image: $selectedImage) { error in
                    scannerError = "Dokument-scanner feilet: \(error.localizedDescription). Prøv vanlig kamera i stedet."
                }
                .onDisappear {
                    if selectedImage != nil {
                        processOCR()
                    }
                }
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraPicker(image: $selectedImage) { error in
                    scannerError = "Kamera feilet: \(error.localizedDescription). I simulator, vennligst bruk 'Velg fra Bilder' i stedet."
                }
                .onDisappear {
                    if selectedImage != nil {
                        processOCR()
                    }
                }
            }
            .overlay {
                if isProcessingOCR {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Behandler bilde...")
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .alert("OCR-feil", isPresented: Binding(get: { ocrError != nil }, set: { _ in ocrError = nil })) {
                Button("OK", role: .cancel) {
                    // Fortsett til editor selv om OCR feilet
                    presentEditor = true
                }
            } message: {
                Text(ocrError ?? "")
            }
            .alert("Kamera-feil", isPresented: Binding(get: { scannerError != nil }, set: { _ in scannerError = nil })) {
                Button("Bruk vanlig kamera", role: .none) {
                    showCameraPicker = true
                }
                Button("Avbryt", role: .cancel) {}
            } message: {
                Text(scannerError ?? "")
            }
        }
    }
    
    private func processOCR() {
        guard let image = selectedImage else { return }
        
        // #region agent log
        let logData: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "run1",
            "hypothesisId": "A",
            "location": "NewReceiptOptionsView.swift:71",
            "message": "Starter OCR-behandling",
            "data": ["hasImage": true],
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        if let logJson = try? JSONSerialization.data(withJSONObject: logData),
           let logString = String(data: logJson, encoding: .utf8) {
            try? logString.write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
        }
        // #endregion
        
        isProcessingOCR = true
        ocrResult = nil
        ocrError = nil
        
        Task {
            do {
                let text = try await ocrService.recognizeText(from: image)
                
                // #region agent log
                let logData2: [String: Any] = [
                    "sessionId": "debug-session",
                    "runId": "run1",
                    "hypothesisId": "A",
                    "location": "NewReceiptOptionsView.swift:85",
                    "message": "OCR tekst hentet",
                    "data": ["textLength": text.count],
                    "timestamp": Int(Date().timeIntervalSince1970 * 1000)
                ]
                if let logJson = try? JSONSerialization.data(withJSONObject: logData2),
                   let logString = String(data: logJson, encoding: .utf8),
                   let existingLog = try? String(contentsOfFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", encoding: .utf8) {
                    try? (existingLog + "\n" + logString).write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
                }
                // #endregion
                
                let result = ocrService.parse(from: text)
                
                // #region agent log
                let logData3: [String: Any] = [
                    "sessionId": "debug-session",
                    "runId": "run1",
                    "hypothesisId": "A",
                    "location": "NewReceiptOptionsView.swift:95",
                    "message": "OCR-resultat parsert",
                    "data": [
                        "hasStoreName": result.storeName != nil,
                        "hasDate": result.purchaseDate != nil,
                        "hasAmount": result.totalAmount != nil,
                        "lineItemsCount": result.lineItems.count
                    ],
                    "timestamp": Int(Date().timeIntervalSince1970 * 1000)
                ]
                if let logJson = try? JSONSerialization.data(withJSONObject: logData3),
                   let logString = String(data: logJson, encoding: .utf8),
                   let existingLog = try? String(contentsOfFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", encoding: .utf8) {
                    try? (existingLog + "\n" + logString).write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
                }
                // #endregion
                
                await MainActor.run {
                    ocrResult = result
                    isProcessingOCR = false
                    presentEditor = true
                }
            } catch {
                // #region agent log
                let logData4: [String: Any] = [
                    "sessionId": "debug-session",
                    "runId": "run1",
                    "hypothesisId": "B",
                    "location": "NewReceiptOptionsView.swift:110",
                    "message": "OCR feilet",
                    "data": ["error": error.localizedDescription],
                    "timestamp": Int(Date().timeIntervalSince1970 * 1000)
                ]
                if let logJson = try? JSONSerialization.data(withJSONObject: logData4),
                   let logString = String(data: logJson, encoding: .utf8),
                   let existingLog = try? String(contentsOfFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", encoding: .utf8) {
                    try? (existingLog + "\n" + logString).write(toFile: "/Users/andre/Documents/GitHub/Kvittering-1/.cursor/debug.log", atomically: true, encoding: .utf8)
                }
                // #endregion
                
                await MainActor.run {
                    ocrError = "Kunne ikke lese tekst fra bildet. Du kan fortsatt legge inn kvitteringen manuelt."
                    isProcessingOCR = false
                }
            }
        }
    }
}
