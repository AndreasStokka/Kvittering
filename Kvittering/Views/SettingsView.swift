import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SettingsViewModel(context: ModelContext.preview)
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Text("Slett alle kvitteringer")
                    }
                }

                Section("Om appen") {
                    Text("Alle data lagres lokalt på enheten i denne versjonen.")
                }
            }
            .navigationTitle("Innstillinger")
            .alert("Slett alle?", isPresented: $showDeleteAlert) {
                Button("Slett", role: .destructive) {
                    try? viewModel.deleteAll()
                }
                Button("Avbryt", role: .cancel) {}
            }
            .onAppear {
                viewModel.attach(context: modelContext)
            }
        }
    }
}
