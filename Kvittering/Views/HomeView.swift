import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel()
    @State private var showNewSheet = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Kvittering")
                    .font(.largeTitle.bold())

                Button {
                    showNewSheet = true
                } label: {
                    Label("Skann kvittering", systemImage: "doc.text.viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Oversikt")
                        .font(.headline)
                    Text("Antall kvitteringer: \(viewModel.receiptCount)")
                    if !viewModel.lastCategorySummary.isEmpty {
                        ForEach(viewModel.lastCategorySummary.sorted(by: { $0.key < $1.key }), id: \.key) { entry in
                            Text("\(entry.key): \(entry.value)")
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .sheet(isPresented: $showNewSheet) {
                NewReceiptOptionsView()
                    .modelContext(modelContext)
            }
            .onAppear {
                viewModel.attach(context: modelContext)
            }
        }
    }
}
