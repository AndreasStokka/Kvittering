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

// Forhåndsvisning i lys modus
#Preview("Lys modus") {
    ContentView()
        .modelContainer(for: [Receipt.self, LineItem.self], inMemory: true)
        .environment(LocalFeatureAccess())
        .environmentObject(ThemeManager())
        .preferredColorScheme(.light)
}

// Forhåndsvisning i mørk modus
#Preview("Mørk modus") {
    ContentView()
        .modelContainer(for: [Receipt.self, LineItem.self], inMemory: true)
        .environment(LocalFeatureAccess())
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
}

