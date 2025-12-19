import SwiftUI

struct ConsumerGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    Text("Forbrukerrettigheter i Norge")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 8)
                
                // Reklamasjonsrett
                SectionView(
                    title: "Reklamasjonsrett",
                    icon: "shield.checkered",
                    content: """
                    I Norge gir Forbrukerkjøpsloven deg sterke rettigheter:
                    
                    • 5 års reklamasjonsrett på varer som er ment å vare vesentlig lenger enn 2 år (f.eks. mobil, PC, hvitevarer)
                    • 2 års reklamasjonsrett på andre varer
                    
                    Dette gjelder uavhengig av hva produsenten oppgir som garanti. Selv om Apple kun oppgir 1 års garanti, har du 5 års reklamasjonsrett på iPhone og Mac.
                    """
                )
                
                // Returrett
                SectionView(
                    title: "Returrett",
                    icon: "arrow.uturn.backward",
                    content: """
                    Returrett gjelder for kjøp gjort utenfor butikklokaler (f.eks. nettbutikker):
                    
                    • 14 dagers angrefrist for kjøp på nett
                    • Du kan returnere varen uten å oppgi grunn
                    • Varen må være i samme stand som ved levering
                    
                    Merk: Returrett gjelder ikke for varer som er tilpasset eller laget spesielt for deg.
                    """
                )
                
                // Bytterett
                SectionView(
                    title: "Bytterett",
                    icon: "arrow.triangle.2.circlepath",
                    content: """
                    Mange butikker tilbyr frivillig bytterett utover det loven krever:
                    
                    • Butikken kan tilby kortere eller lengre byttefrist
                    • Sjekk butikkens vilkår for bytterett
                    • Husk å bevare kvitteringen for å benytte bytterett
                    """
                )
                
                // Garanti vs reklamasjonsrett
                SectionView(
                    title: "Garanti vs Reklamasjonsrett",
                    icon: "doc.text.magnifyingglass",
                    content: """
                    Det er viktig å skille mellom garanti og reklamasjonsrett:
                    
                    • Garanti er frivillig og gis av produsenten
                    • Reklamasjonsrett er lovfestet og kan ikke fraskrives
                    • Du har alltid reklamasjonsrett, uavhengig av garanti
                    • Reklamasjonsretten gjelder også brukt kjøp fra forhandler
                    """
                )
                
                // Praktiske tips
                SectionView(
                    title: "Praktiske tips",
                    icon: "lightbulb.fill",
                    content: """
                    For å sikre dine rettigheter:
                    
                    • Behold alltid kvitteringen (bruk denne appen!)
                    • Dokumenter feil og mangler med bilder
                    • Kontakt forhandler først ved reklamasjon
                    • Du kan kreve omlevering, prisavslag eller heving av kjøpet
                    """
                )
                
                // Footer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mer informasjon")
                        .font(.headline)
                    if let forbrukertilsynetURL = URL(string: "https://www.forbrukertilsynet.no") {
                        Link("Forbrukertilsynet", destination: forbrukertilsynetURL)
                            .font(.subheadline)
                    }
                    if let lovdataURL = URL(string: "https://lovdata.no/dokument/NL/lov/1988-05-13-27") {
                        Link("Forbrukerkjøpsloven", destination: lovdataURL)
                            .font(.subheadline)
                    }
                }
                .padding(.top, 8)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Forbrukerrettigheter")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SectionView: View {
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.headline)
            }
            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        ConsumerGuideView()
    }
}

