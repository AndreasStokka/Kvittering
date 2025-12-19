import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showDeleteAlert = false
    @State private var showMailComposer = false

    var body: some View {
        NavigationStack {
            Form {
                // Seksjon for utseende/tema-valg
                // Brukeren kan velge mellom Lys, Mørk eller System (følger enhetens innstilling)
                Section {
                    Picker("Visning", selection: $themeManager.selectedTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            HStack {
                                Image(systemName: theme.icon)
                                Text(theme.displayName)
                            }
                            .tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Utseende")
                } footer: {
                    Text("Velg hvordan appen skal se ut. 'System' følger enhetens innstillinger.")
                }
                
                Section {
                    Toggle(isOn: $viewModel.saveToPhotoLibrary) {
                        Label("Lagre bilder til fotobibliotek", systemImage: "photo.on.rectangle")
                    }
                } header: {
                    Text("Kvitteringsbilder")
                } footer: {
                    Text("Når aktivert, lagres kvitteringsbilder også i telefonens fotobibliotek. Dette gjør at bildene blir inkludert i iCloud-backup.")
                }
                
                Section {
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Slett alle kvitteringer")
                        }
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("Denne handlingen kan ikke angres")
                }

                Section {
                    Button {
                        showMailComposer = true
                    } label: {
                        Label("Tips en venn", systemImage: "message.fill")
                    }
                } header: {
                    Text("Del appen")
                }

                Section {
                    NavigationLink {
                        ConsumerGuideView()
                    } label: {
                        Label("Forbrukerrettigheter", systemImage: "info.circle.fill")
                    }
                } header: {
                    Text("Informasjon")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(.blue)
                            Text("Personvern")
                                .font(.headline)
                        }
                        Text("Alle data lagres lokalt på enheten i denne versjonen. Det betyr at dine data er sikre, og brukes ikke av appleverandøren, men du må selv stå for backup.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "cloud.fill")
                                .foregroundStyle(.blue)
                            Text("Fremtidige funksjoner")
                                .font(.headline)
                        }
                        Text("I en senere versjon vil vi lansere skylagring og familiekonto, noe som mest sannsynlig vil koste noen få kroner.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Om appen")
                }
            }
            .navigationTitle("Innstillinger")
            .alert("Slett alle?", isPresented: $showDeleteAlert) {
                Button("Slett", role: .destructive) {
                    try? viewModel.deleteAll()
                }
                Button("Avbryt", role: .cancel) {}
            }
            .sheet(isPresented: $showMailComposer) {
                MessageComposeView(
                    recipients: [],
                    subject: "Sjekk ut Kvittering-appen!",
                    messageBody: "Hei! Jeg har funnet en genial app for å organisere kvitteringer. Den heter 'Kvittering' og hjelper deg med å holde oversikt over alle kvitteringene dine. Sjekk den ut!"
                )
            }
            .onAppear {
                viewModel.attach(context: modelContext)
            }
        }
    }
}

// Forhåndsvisning i lys modus
#Preview("Lys modus") {
    SettingsView()
        .modelContainer(for: [Receipt.self, LineItem.self], inMemory: true)
        .environmentObject(ThemeManager())
        .preferredColorScheme(.light)
}

// Forhåndsvisning i mørk modus
#Preview("Mørk modus") {
    SettingsView()
        .modelContainer(for: [Receipt.self, LineItem.self], inMemory: true)
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
}
