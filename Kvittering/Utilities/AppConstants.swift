import Foundation

/// Sentrale konstanter for appen
enum AppConstants {
    /// Logger subsystem - bruker faktisk bundle identifier for å sikre
    /// at loggene kan filtreres riktig i Console.app.
    /// Fallback til "com.example.Kvittering" hvis bundle identifier ikke er tilgjengelig.
    static let loggerSubsystem = Bundle.main.bundleIdentifier ?? "com.example.Kvittering"
}

