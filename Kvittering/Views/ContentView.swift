import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(LocalFeatureAccess.self) private var featureAccess
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Hjem", systemImage: "house.fill") }
            ReceiptListView()
                .tabItem { Label("Mine kvitteringer", systemImage: "list.bullet") }
            SettingsView()
                .tabItem { Label("Innstillinger", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Receipt.self, LineItem.self], inMemory: true)
        .environment(LocalFeatureAccess())
}
