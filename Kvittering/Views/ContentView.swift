import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(LocalFeatureAccess.self) private var featureAccess
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Hjem", systemImage: "house.fill") }
                .tag(0)
            ReceiptListView()
                .tabItem { Label("Mine kvitteringer", systemImage: "list.bullet") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Innstillinger", systemImage: "gearshape.fill") }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Receipt.self, LineItem.self], inMemory: true)
        .environment(LocalFeatureAccess())
}
