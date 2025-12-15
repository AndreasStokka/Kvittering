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
    
    var onReceiptSaved: (() -> Void)?
    
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
            }
            .navigationTitle("Ny kvittering")
            .sheet(isPresented: $presentEditor) {
                NavigationStack {
                    EditReceiptView(sourceImage: selectedImage, ocrResult: ocrResult, onSaved: {
                        dismiss()
                        onReceiptSaved?()
                    })
                    .modelContext(modelContext)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(image: $selectedImage)
                    .onDisappear {
                        if selectedImage != nil && !isProcessingOCR {
                            processOCR()
                        }
                    }
            }
            .sheet(isPresented: $showScanner) {
                DocumentScanner(image: $selectedImage) { error in
                    scannerError = "Dokument-scanner feilet: \(error.localizedDescription). Prøv vanlig kamera i stedet."
                }
                .onDisappear {
                    if selectedImage != nil && !isProcessingOCR {
                        processOCR()
                    }
                }
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraPicker(image: $selectedImage) { error in
                    scannerError = "Kamera feilet: \(error.localizedDescription). I simulator, vennligst bruk 'Velg fra Bilder' i stedet."
                }
                .onDisappear {
                    if selectedImage != nil && !isProcessingOCR {
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
        
        isProcessingOCR = true
        ocrResult = nil
        ocrError = nil
        
        #if DEBUG
        NSLog("🚀 Starting OCR process...")
        #endif
        
        Task {
            do {
                let text = try await ocrService.recognizeText(from: image)
                let result = ocrService.parse(from: text)
                
                #if DEBUG
                NSLog("✅ OCR process completed successfully")
                #endif
                
                await MainActor.run {
                    ocrResult = result
                    isProcessingOCR = false
                    presentEditor = true
                }
            } catch {
                #if DEBUG
                NSLog("❌ OCR process failed: %@", error.localizedDescription)
                #endif
                await MainActor.run {
                    if let ocrErr = error as? OCRService.OCRError {
                        ocrError = ocrErr.localizedDescription
                    } else {
                        ocrError = "Kunne ikke lese tekst fra bildet. Du kan fortsatt legge inn kvitteringen manuelt."
                    }
                    isProcessingOCR = false
                }
            }
        }
    }
}
