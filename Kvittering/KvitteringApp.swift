import SwiftUI
import SwiftData
import os.log

@main
struct KvitteringApp: App {
    @StateObject private var themeManager = ThemeManager()
    @State private var featureAccess = LocalFeatureAccess()
    private static let logger = Logger(subsystem: "com.example.Kvittering", category: "KvitteringApp")

    var sharedModelContainer: ModelContainer {
        let schema = Schema([
            Receipt.self,
            LineItem.self
        ])
        
        // Eksplisitt database-URL for å sikre konsistent lagring
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // Fallback til in-memory database hvis documents directory ikke finnes (skal ikke skje)
            fatalError("Could not access documents directory")
        }
        let databaseURL = documentsPath.appendingPathComponent("Kvittering.sqlite")
        
        let config = ModelConfiguration(
            schema: schema,
            url: databaseURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        
        do {
            // Prøv å opprette container med eksisterende database
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Hvis opprettelse feiler, prøv å håndtere det mer elegant
            // Dette kan skje hvis skjemaet har endret seg betydelig
            Self.logger.error("⚠️ Kunne ikke opprette ModelContainer: \(error.localizedDescription)")
            Self.logger.info("⚠️ Prøver å opprette ny database...")
            
            // Prøv å slette den gamle databasen hvis den er korrupt
            do {
                try? FileManager.default.removeItem(at: databaseURL)
                let newConfig = ModelConfiguration(
                    schema: schema,
                    url: databaseURL,
                    allowsSave: true,
                    cloudKitDatabase: .none
                )
                return try ModelContainer(for: schema, configurations: [newConfig])
            } catch {
                // Hvis alt feiler, bruk standard konfigurasjon som fallback
                Self.logger.warning("⚠️ Fallback til standard konfigurasjon")
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                do {
                    return try ModelContainer(for: schema, configurations: [fallbackConfig])
                } catch {
                    // Hvis også dette feiler, krasj appen (dette bør ikke skje)
                    fatalError("Kunne ikke opprette ModelContainer: \(error.localizedDescription)")
                }
            }
        }
    }

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
