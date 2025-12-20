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
                    
                    • Du har 5 års reklamasjonsrett på varer som er ment å vare vesentlig lenger enn 2 år, som mobiltelefon, PC eller hvitevarer.
                    • Du har 2 års reklamasjonsrett på andre varer
                    
                    Dette gjelder uansett hva produsenten sier om garanti. For eksempel har du 5 års reklamasjonsrett på iPhone og Mac, selv om Apple bare gir 1 års garanti.
                    """
                )
                
                // Returrett
                SectionView(
                    title: "Returrett",
                    icon: "arrow.uturn.backward",
                    content: """
                    Du har returrett når du kjøper noe utenfor vanlige butikker, for eksempel på nett:
                    
                    • Du har 14 dagers angrefrist
                    • Du kan returnere varen uten å si hvorfor
                    • Varen må være i samme stand som da du fikk den
                    
                    Merk: Returretten gjelder ikke hvis varen er spesiallaget for deg. Og: det er stort sett kun netthandel som har "returrett". 
                    """
                )
                
                // Bytterett
                SectionView(
                    title: "Bytterett",
                    icon: "arrow.triangle.2.circlepath",
                    content: """
                    Mange butikker tilbyr bytterett frivillig, i tillegg til det loven sier:
                    
                    • Butikken bestemmer selv hvor lang byttefrist du får
                    • Sjekk hva som gjelder der du handler
                    • Ta vare på kvitteringen hvis du vil bytte
                    """
                )
                
                // Garanti vs reklamasjonsrett
                SectionView(
                    title: "Garanti vs Reklamasjonsrett",
                    icon: "doc.text.magnifyingglass",
                    content: """
                    Garanti og reklamasjonsrett er ikke det samme:
                    
                    • Garanti er noe produsenten kan velge å gi
                    • Reklamasjonsrett er bestemt i loven og kan ikke tas fra deg
                    • Du har alltid reklamasjonsrett, også hvis det finnes en garanti
                    • Du har reklamasjonsrett også når du kjøper brukte varer fra forhandler
                    """
                )
                
                // Praktiske tips
                SectionView(
                    title: "Praktiske tips",
                    icon: "lightbulb.fill",
                    content: """
                    For å ta vare på rettighetene dine:
                    
                    • Ta vare på kvitteringen (bruk gjerne appen!)
                    • Ta bilder av feil og mangler
                    • Ta kontakt med forhandleren først hvis du vil reklamere
                    • Du kan kreve å få ny vare, få tilbake penger eller heve kjøpet
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

