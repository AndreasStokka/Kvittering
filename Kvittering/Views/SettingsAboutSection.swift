import SwiftUI

/// View for "Om appen"-seksjonen i innstillinger
struct SettingsAboutSection: View {
    var body: some View {
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
}



