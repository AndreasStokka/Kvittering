import SwiftUI
import SwiftData

@main
struct KvitteringApp: App {
    @State private var featureAccess = LocalFeatureAccess()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Receipt.self,
            LineItem.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .environment(featureAccess)
        }
    }
}
