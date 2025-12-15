# Kvittering

En iOS-app for å organisere og administrere kvitteringer. Appen bruker OCR (Optical Character Recognition) for å automatisk ekstraktere informasjon fra kvitteringer ved hjelp av kamera eller bilde.

## Funksjoner

### 📸 OCR-skanning
- Automatisk tekstgjenkjenning fra kvitteringsbilder
- Støtte for både kamera og bildegalleri
- Dokument-skanner for optimal bildekvalitet
- Ekstraherer butikknavn, dato, totalbeløp og linjeposter

### 📋 Organisering
- Kategorisering av kvitteringer (Mat, Klær, Elektronikk, Sport, Transport, Annet)
- Automatisk kategoriforslag basert på butikknavn
- Lagring av kvitteringsbilder
- Notater og merknader på kvitteringer

### 🔄 Retur- og bytterett
- Sporing av retur- og bytterett for hver kvittering
- Varsling om returfrister
- Informasjon om forbrukerrettigheter

### 📊 Oversikt
- Liste over alle kvitteringer
- Søk og filtrering
- Visning av siste kvitteringer på hjem-skjermen
- Detaljvisning med alle linjeposter

### 📚 Forbrukerrettigheter
- Guide om garanti og reklamasjonsrett
- Informasjon om angrerett (14 dager)
- Lenker til relevante kilder (Forbrukerrådet, Lovdata, Forbrukertilsynet)

## Krav

- iOS 17.0 eller nyere
- Xcode 15.0 eller nyere
- Swift 5.9 eller nyere

## Teknologier

- **SwiftUI** - Brukergrensesnitt
- **SwiftData** - Datapersistens
- **Vision Framework** - OCR-tekstgjenkjenning
- **UIKit** - Integrasjon med kamera og bildehåndtering

## Prosjektstruktur

```
Kvittering/
├── Models/
│   └── Receipt.swift          # Datamodeller for kvitteringer og linjeposter
├── Services/
│   ├── OCRService.swift       # OCR-tekstgjenkjenning og parsing
│   ├── CategoryService.swift  # Automatisk kategorisering
│   ├── ReceiptRepository.swift # Databaselagring
│   ├── ImageStore.swift       # Bildehåndtering
│   └── FeatureAccess.swift    # Funksjonstilgang
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── ReceiptListViewModel.swift
│   ├── ReceiptDetailViewModel.swift
│   └── EditReceiptViewModel.swift
├── Views/
│   ├── ContentView.swift      # Hovednavigasjon
│   ├── HomeView.swift         # Hjem-skjerm
│   ├── ReceiptListView.swift # Liste over kvitteringer
│   ├── ReceiptDetailView.swift # Detaljvisning
│   ├── EditReceiptView.swift  # Redigering
│   ├── NewReceiptOptionsView.swift # Ny kvittering
│   ├── SettingsView.swift     # Innstillinger
│   └── ConsumerGuideView.swift # Forbrukerrettigheter
├── Utilities/
│   ├── DocumentScanner.swift  # Dokument-skanner
│   ├── CameraPicker.swift     # Kameraintegrasjon
│   ├── PhotoPicker.swift      # Bildegalleri
│   ├── AmountsFormatter.swift # Beløpsformatering
│   └── ActivityView.swift     # Deling
└── Resources/
    └── store_categories.json  # Butikk-kategori mapping
```

## Installasjon

1. Klon repositoriet:
```bash
git clone https://github.com/[ditt-brukernavn]/Kvittering-1.git
cd Kvittering-1
```

2. Åpne prosjektet i Xcode:
```bash
open Kvittering.xcodeproj
```

3. Bygg og kjør prosjektet (⌘R)

## Bruk

### Legge til en ny kvittering

1. Trykk på "Skann kvittering" på hjem-skjermen
2. Velg mellom:
   - **Kamera** - Ta et bilde direkte
   - **Bildegalleri** - Velg fra eksisterende bilder
   - **Dokument-skanner** - Bruk iOS dokument-skanner for optimal kvalitet
3. Appen vil automatisk ekstraktere informasjon fra kvitteringen
4. Gjør eventuelle justeringer og lagre

### Kategorisering

Appen forsøker automatisk å kategorisere kvitteringer basert på butikknavn. Du kan alltid endre kategorien manuelt.

### Retur- og bytterett

For hver kvittering kan du registrere:
- Om butikken har returrett og hvor mange dager
- Om butikken har bytterett og hvor mange dager

Dette hjelper deg med å holde oversikt over returfrister.

## Testing

Prosjektet inneholder en omfattende testsuite:

```bash
# Kjør alle tester
⌘U i Xcode

# Eller via kommandolinjen:
xcodebuild test -scheme Kvittering -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Testdekning

- `OCRServiceTests` - OCR-funksjonalitet
- `CategoryServiceTests` - Kategorisering
- `ReceiptRepositoryTests` - Datapersistens
- `AmountFormatterTests` - Beløpsformatering
- `LineItemsTests` - Linjepost-ekstraksjon

## OCR-funksjonalitet

Appen bruker Vision Framework for on-device tekstgjenkjenning. Dette betyr:
- ✅ Ingen data sendes til tredjepart
- ✅ Fungerer offline
- ✅ Støtter norsk tekst (nb-NO, nn-NO)
- ✅ Fallback til engelsk for blandede kvitteringer

### Støttede formater

- **Datoer**: `dd.MM.yyyy`, `yyyy-MM-dd`
- **Beløp**: Norsk format (`2 379,15`) og engelsk format (`2 379.15`)
- **Butikknavn**: Automatisk deteksjon av kjente norske butikker
- **Linjeposter**: Automatisk ekstraksjon av produktnavn, mengde og pris

## Arkitektur

Appen følger MVVM-arkitektur (Model-View-ViewModel):

- **Models**: SwiftData-modeller for datapersistens
- **Views**: SwiftUI-views for brukergrensesnitt
- **ViewModels**: Forretningslogikk og state management
- **Services**: Tjenester for OCR, kategorisering, og datalagring

## Lisens

[Legg til din lisens her]

## Bidrag

Bidrag er velkomne! Vennligst opprett en issue eller pull request.

## Kontakt

[Legg til kontaktinformasjon her]
