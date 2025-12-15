import SwiftUI
import SwiftData

@main
struct KvitteringApp: App {
    @StateObject private var themeManager = ThemeManager()
    @State private var featureAccess = LocalFeatureAccess()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Receipt.self,
            LineItem.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Kunne ikke opprette ModelContainer: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .environment(featureAccess)
                .environmentObject(themeManager)
                // Bruk valgt tema for å sikre konsistent visning på simulator og fysisk enhet
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
