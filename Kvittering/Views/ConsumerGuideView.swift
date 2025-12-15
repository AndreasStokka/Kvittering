import SwiftUI

struct ConsumerGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Garanti vs. Reklamasjonsrett
                Section {
                    Text("Garanti og reklamasjonsrett")
                        .font(.title2.bold())

                    Text("Det er viktig å skille mellom garanti og reklamasjonsrett, da disse gir ulike rettigheter:")
                        .font(.headline)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Garanti")
                            .font(.headline)
                        Text("Garanti er en frivillig tilleggsytelse som selger eller produsent kan tilby. Garantien kan gi deg bedre rettigheter enn loven, men kan aldri begrense rettighetene du allerede har etter reklamasjonsreglene. Vilkår, varighet og omfang varierer.")
                            .font(.body)

                        Text("Reklamasjonsrett")
                            .font(.headline)
                            .padding(.top, 8)
                        Text("Reklamasjonsrett er en lovfestet rettighet etter forbrukerkjøpsloven. Den gjelder automatisk ved kjøp fra næringsdrivende, og selger kan ikke avtale seg bort fra denne.")
                            .font(.body)
                    }
                    .padding(.vertical, 8)
                }

                Divider()

                // Reklamasjonsrett detaljer
                Section {
                    Text("Reklamasjonsrett – hvor lenge gjelder den?")
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 12) {
                        Text("2 års reklamasjonsfrist")
                            .font(.headline)
                        Text("For varer som er ment å vare i inntil to år, har du reklamasjonsrett i 2 år fra du mottok varen.")
                            .font(.body)

                        Text("5 års reklamasjonsfrist")
                            .font(.headline)
                            .padding(.top, 8)
                        Text("For varer som er ment å vare vesentlig lengre enn to år, er reklamasjonsfristen 5 år.")
                            .font(.body)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Eksempler kan være:")
                            Text("• Mobiltelefoner og annet avansert elektronisk utstyr")
                            Text("• Hvitevarer")
                            Text("• Møbler")
                        }
                        .font(.body)
                        .padding(.leading, 8)
                        .padding(.top, 4)

                        Text("Reklamasjon gjelder dersom varen har en mangel. En mangel kan være en produksjonsfeil, at varen ikke fungerer som forventet, eller at den ikke samsvarer med det som ble avtalt eller markedsført.")
                            .font(.body)
                            .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }

                Divider()

                // Retur, bytte og angrerett
                Section {
                    Text("Retur, bytterett og angrerett")
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Angrerett – 14 dager")
                            .font(.headline)
                        Text("Ved kjøp på nett, telefon eller andre former for fjernsalg har du som hovedregel 14 dagers angrerett. Angrefristen løper fra dagen du mottar varen. Dette gjelder ikke kjøp i fysisk butikk.")
                            .font(.body)

                        Text("Bytterett og retur i butikk")
                            .font(.headline)
                            .padding(.top, 8)
                        Text("Bytterett og retur ved kjøp i fysisk butikk er ikke lovpålagt. Dersom butikken tilbyr dette, er det en frivillig ordning, og butikken bestemmer vilkårene selv.")
                            .font(.body)
                    }
                    .padding(.vertical, 8)
                }

                Divider()

                // Ressurser
                Section {
                    Text("Nyttige kilder")
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 12) {
                        Link("Forbrukerrådet – dine rettigheter", destination: URL(string: "https://www.forbrukerradet.no/forside/klageguide/")!)
                        Link("Lovdata – forbrukerkjøpsloven", destination: URL(string: "https://lovdata.no/lov/2002-06-21-34")!)
                        Link("Forbrukertilsynet – angrerett", destination: URL(string: "https://www.forbrukertilsynet.no/vi-jobber-med/angrerett")!)

                        Text("Disse kildene gir oppdatert og pålitelig informasjon om dine rettigheter som forbruker.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
        }
        .navigationTitle("Forbrukerrettigheter")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        ConsumerGuideView()
    }
}



