# Kvittering

[![CI](https://github.com/AndreasStokka/Kvittering/actions/workflows/objective-c-xcode.yml/badge.svg)](https://github.com/AndreasStokka/Kvittering/actions/workflows/objective-c-xcode.yml)

Kvittering er en iOS-app som hjelper deg å holde orden på kvitteringene dine. Appen bruker optisk tegngjenkjenning (OCR) for å hente ut informasjon automatisk, rett fra bilde eller kamera.

## Funksjoner

### 📸 Skann kvitteringer med tekstgjenkjenning (OCR)
- Automatisk tekstgjenkjenning fra bilder av kvitteringer
- Støtte for både kamera og bildegalleri
- Bruk dokument-skanner for best mulig bildekvalitet
- Henter ut butikknavn, dato, totalbeløp og linjeposter 


### 📋 Organisering
- Sorter kvitteringer i kategorier som Mat, Klær, Elektronikk, Sport, Bygg og Annet
- Appen foreslår automatisk kategori basert på butikknavn
- Lagre bilder av kvitteringene
- Legg til notater og merknader


### 📊 Oversikt
- Se alle kvitteringer i en liste
- Søk og filtrer etter det du leter etter
- Rask tilgang til de siste kvitteringene fra hjem-skjermen
- Se detaljert informasjon om hver kvittering

### 📚 Forbrukerrettigheter
- Guide om garanti og reklamasjonsrett
- Informasjon om angrerett (14 dager)
- Lenker til Forbrukerrådet, Lovdata og Forbrukertilsynet


## Krav
- iOS 17.0 eller nyere
- Xcode 15.0 eller nyere
- Swift 5.9 eller nyere

## Teknologier

- **SwiftUI** - Brukergrensesnitt
- **SwiftData** - Lagring av data
- **Vision Framework** - OCR-tekstgjenkjenning
- **UIKit** - Kobling til kamera og bilder

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
│   ├── EditReceiptViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── ContentView.swift           # Hovednavigasjon
│   ├── HomeView.swift              # Hjem-skjerm
│   ├── ReceiptListView.swift       # Liste over kvitteringer
│   ├── ReceiptListContent.swift    # Innhold i kvitteringsliste
│   ├── ReceiptListFiltersView.swift # Filtre for kvitteringsliste
│   ├── ReceiptDetailView.swift     # Detaljvisning
│   ├── EditReceiptView.swift       # Redigering
│   ├── NewReceiptOptionsView.swift # Ny kvittering
│   ├── SettingsView.swift          # Innstillinger
│   ├── SettingsAboutSection.swift  # Om-seksjon i innstillinger
│   └── ConsumerGuideView.swift     # Forbrukerrettigheter
├── Utilities/
│   ├── DocumentScanner.swift       # Dokument-skanner
│   ├── PhotoPicker.swift           # Bildegalleri
│   ├── AmountsFormatter.swift      # Beløpsformatering
│   ├── ActivityView.swift          # Deling
│   ├── MessageComposeView.swift    # SMS-komposisjon
│   ├── TextNormalizer.swift        # Tekstnormalisering
│   └── ThemeManager.swift          # Tema-håndtering
└── Resources/
    └── store_categories.json  # Butikk-kategori mapping
```

## Bruk

### Legge til en ny kvittering

1. Trykk på "Ny kvittering" på hjem-skjermen
2. Velg mellom:
   - **Kamera (dokument-skanner)** - Ta et bilde direkte
   - **Bildegalleri** - Velg fra eksisterende bilder
3. Appen henter ut info fra bildet
4. Du kan gjøre eventuelle justeringer og lagre

ter.

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
- `LineItemsTests` - Linjepost-ekstraksjon (kommer i en senere versjon, men testing og justering er påbegynt for optimal funksjonalitet)

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

## CI/CD

Prosjektet bruker GitHub Actions for kontinuerlig integrasjon:

- ✅ **Build**: Automatisk bygging ved push til `main` eller pull requests
- ✅ **Test**: Kjøring av alle enhetstester på iOS Simulator - alle tester går gjennom
- ✅ **Analyze**: Statisk kodeanalyse med Xcode

Workflow-filen finnes i `.github/workflows/objective-c-xcode.yml`.

Se CI-status i badge øverst i README.

## Arkitektur

Appen følger MVVM-prinsippet (Model-View-ViewModel):

- Models: Datamodeller med SwiftData
- Views: SwiftUI-skjermbilder
- ViewModels: Logikk og tilstand
- Services: OCR, kategorisering og datalagring
- Utilities: Gjenbrukbare komponenter

