import SwiftUI

/// Tema-typer som brukeren kan velge mellom
enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    /// Visningsnavn for brukergrensesnittet
    var displayName: String {
        switch self {
        case .light:
            return "Lys"
        case .dark:
            return "Mørk"
        case .system:
            return "System"
        }
    }
    
    /// SF Symbol ikon for hver tema-type
    var icon: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
}

/// Manager for app-tema som lagrer brukerens valg i AppStorage
/// Dette sikrer at valget persisteres mellom app-oppstart
class ThemeManager: ObservableObject {
    /// Lagret tema-valg som automatisk synkroniseres med UserDefaults
    @AppStorage("selectedAppTheme") var selectedTheme: AppTheme = .system {
        didSet {
            // Oppdater colorScheme når tema endres
            updateColorScheme()
        }
    }
    
    /// Nåværende ColorScheme som skal brukes i appen
    @Published var colorScheme: ColorScheme?
    
    init() {
        updateColorScheme()
    }
    
    /// Oppdaterer colorScheme basert på valgt tema
    /// Hvis system er valgt, returnerer nil slik at systemet bestemmer
    private func updateColorScheme() {
        switch selectedTheme {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            colorScheme = nil // La systemet bestemme
        }
    }
}

