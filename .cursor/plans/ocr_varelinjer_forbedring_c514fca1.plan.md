---
name: OCR varelinjer forbedring
overview: Forbedre OCR-kvalitet på varelinjer med bedre parsing, omfattende testing, og UI for visning og redigering av varelinjer (skjult bak en knapp).
todos:
  - id: improve-ocr-parsing
    content: Forbedre parseLineItemsFromLines i OCRService.swift med bedre regex-mønstre, håndtering av flere formater (tab-separert, kolon-separert), og forbedret kvantitets-parsing
    status: pending
  - id: improve-line-item-detection
    content: Forbedre detectLineItems i OCRService.swift for bedre identifisering av varelinjer-region og håndtering av multi-line produktnavn
    status: pending
  - id: add-validation
    content: "Legg til validering i OCR-parsing: sjekk at summen av varelinjer matcher totalbeløp, filtrer ut urealistiske priser, og valider produktnavn"
    status: pending
  - id: extend-line-item-tests
    content: Utvide LineItemsTests.swift med flere edge cases (multi-line navn, tab-separert, desimaltall i kvantitet), real-world-scenarier, og valideringstester
    status: pending
  - id: add-test-helpers
    content: Utvide TestHelpers.swift med flere eksempel-kvitteringer fra forskjellige butikker og edge case-eksempler
    status: pending
  - id: create-line-item-edit-view
    content: Opprett LineItemEditView.swift for redigering av enkelt varelinje med TextFields for produktnavn, kvantitet og enhetspris
    status: pending
  - id: create-ocr-details-view
    content: Opprett OCRDetailsView.swift for visning av rå OCR-tekst og parsing-resultater (skjult bak en knapp)
    status: pending
  - id: update-edit-receipt-viewmodel
    content: Oppdater EditReceiptViewModel.swift med metoder for å legge til, oppdatere og slette varelinjer, samt state for OCR-detaljer
    status: pending
  - id: update-edit-receipt-view
    content: Oppdater EditReceiptView.swift med seksjon for varelinjer, redigeringsmulighet, og knapp for å vise OCR-detaljer
    status: pending
  - id: update-receipt-detail-view
    content: Oppdater ReceiptDetailView.swift med redigeringsmulighet for varelinjer og knapp for å vise OCR-detaljer
    status: pending
---

# Plan: Forbedre OCR-kvalitet på varelinjer med testing og UI

## Oversikt

Planen fokuserer på tre hovedområder:

1. **Forbedre OCR-parsing** for varelinjer med bedre regex-mønstre, håndtering av edge cases, og validering
2. **Utvide testing** med flere edge cases, real-world-scenarier, og validering av parsing-kvalitet
3. **Legge til UI** for å vise og redigere varelinjer (skjult bak en knapp) med mulighet til å se rå OCR-tekst

## 1. Forbedre OCR-parsing for varelinjer

### 1.1 Forbedre `parseLineItemsFromLines` i `OCRService.swift`

- **Utvide regex-mønstre** for å håndtere flere formater:
- Produktnavn med mellomrom + pris: `"Melk 1L 25,90"`
- Kvantitet først: `"2x Brød 19,50"` eller `"2 Brød 19,50"`
- Tab-separerte verdier: `"Produkt\t25,90"`
- Kolon-separerte: `"Produkt: 25,90"`
- Beløp med stjerne eller annen markering: `"Produkt *25,90"`
- **Forbedre håndtering av kvantitet**:
- Støtte for `2x`, `2 x`, `2 stk`, `2 st`, `2 stk.`
- Håndtere desimaltall i kvantitet (f.eks. `0.5 kg`)
- **Bedre filtrering av ugyldige linjer**:
- Hopp over linjer med kun tall (produktnumre)
- Hopp over linjer med for mange tall
- Hopp over linjer som matcher dato- eller klokkeslett-mønstre
- Hopp over linjer med kun spesialtegn
- **Validering og validering**:
- Sjekk at summen av varelinjer ikke overstiger totalbeløp (med liten toleranse for avrunding)
- Filtrer ut varelinjer med urealistiske priser (f.eks. > 10x totalbeløp)
- Sjekk at produktnavn har minimum antall bokstaver

### 1.2 Forbedre `detectLineItems` i `OCRService.swift`

- **Bedre identifisering av varelinjer-region**:
- Hvis dato/total ikke finnes, prøv å finne varelinjer basert på mønstre
- Bruk heuristikk for å identifisere start/slutt på varelinjer-seksjon
- **Håndtere multi-line varelinjer**:
- Noen kvitteringer har produktnavn på flere linjer
- Kombiner linjer som ser ut til å tilhøre samme vare

### 1.3 Legge til confidence scoring (valgfritt)

- Gi hver varelinje en confidence-score basert på:
- Hvor godt mønsteret matcher
- Om prisen er realistisk
- Om produktnavnet ser ut til å være gyldig
- Dette kan brukes senere for å prioritere visning eller forbedringer

## 2. Utvide testing

### 2.1 Utvide `LineItemsTests.swift`

- **Flere edge cases**:
- Test med produktnavn på flere linjer
- Test med tab-separerte verdier
- Test med kolon-separerte verdier
- Test med desimaltall i kvantitet
- Test med svært lange produktnavn
- Test med svært korte produktnavn (1-2 bokstaver)
- Test med spesialtegn i produktnavn
- **Real-world-scenarier**:
- Test med faktiske kvitteringer fra forskjellige butikker (REMA, Kiwi, Sport 1, etc.)
- Test med kvitteringer med rabatter og MVA
- Test med kvitteringer med produktnumre og strekkoder
- **Valideringstester**:
- Test at summen av varelinjer matcher totalbeløp (med toleranse)
- Test at urealistiske priser filtreres ut
- Test at produktnumre ikke blir tolket som priser
- **Performance-tester**:
- Test med kvitteringer med mange varelinjer (50+)
- Test parsing-tid for store kvitteringer

### 2.2 Legge til testdata i `TestHelpers.swift`

- Legg til flere eksempel-kvitteringer med varierende formater
- Legg til edge case-eksempler
- Legg til real-world-eksempler fra forskjellige butikker

## 3. UI for visning og redigering av varelinjer

### 3.1 Legge til visning av varelinjer i `EditReceiptView.swift`

- **Legg til en seksjon for varelinjer**:
- Vis varelinjer i en liste med mulighet for redigering
- Vis produktnavn, kvantitet, enhetspris og linjetotal
- Legg til knapper for å legge til, redigere og slette varelinjer
- **Legg til en "Vis OCR-detaljer" knapp** (skjult bak en "Debug" eller "Detaljer" knapp):
- Vis rå OCR-tekst (`OCRResult.rawText`)
- Vis hvilke linjer som ble tolket som varelinjer
- Vis confidence-scores hvis implementert
- Dette skal være skjult bak en knapp (f.eks. "Vis OCR-detaljer" eller "Debug")

### 3.2 Oppdatere `EditReceiptViewModel.swift`

- **Legg til metoder for å håndtere varelinjer**:
- `addLineItem(_:)` - Legg til ny varelinje
- `updateLineItem(at:with:)` - Oppdater eksisterende varelinje
- `deleteLineItem(at:)` - Slett varelinje
- `recalculateTotal()` - Rekalkuler totalbeløp basert på varelinjer (valgfritt)
- **Legg til state for OCR-detaljer**:
- `@Published var showOCRDetails: Bool = false`
- `@Published var rawOCRText: String?`

### 3.3 Oppdatere `ReceiptDetailView.swift`

- **Legg til redigeringsmulighet for varelinjer**:
- Når brukeren trykker på en varelinje, vis en redigeringsdialog
- Tillat redigering av produktnavn, kvantitet og enhetspris
- Automatisk oppdatering av linjetotal
- **Legg til "Vis OCR-detaljer" knapp**:
- Skjult bak en "Detaljer" eller "Debug" knapp
- Vis rå OCR-tekst og parsing-resultater

### 3.4 Opprette `LineItemEditView.swift` (ny fil)

- **Komponent for redigering av enkelt varelinje**:
- TextField for produktnavn
- TextField for kvantitet (med validering)
- TextField for enhetspris (med validering)
- Automatisk beregning av linjetotal
- Lagre/Avbryt-knapper

### 3.5 Opprette `OCRDetailsView.swift` (ny fil)

- **Komponent for visning av OCR-detaljer**:
- Vis rå OCR-tekst i en scrollbar tekstvisning
- Vis parsing-resultater (hvilke linjer ble tolket som hva)
- Vis confidence-scores hvis implementert
- Kopier-knapp for rå tekst

## 4. Implementeringsrekkefølge

1. **Fase 1: Forbedre OCR-parsing**

- Oppdater `parseLineItemsFromLines` med bedre regex-mønstre
- Forbedre håndtering av edge cases
- Legg til validering

2. **Fase 2: Utvide testing**

- Legg til nye tester for edge cases
- Legg til real-world-tester
- Legg til valideringstester

3. **Fase 3: UI for visning**

- Legg til visning av varelinjer i `EditReceiptView`
- Legg til "Vis OCR-detaljer" knapp
- Opprett `OCRDetailsView`

4. **Fase 4: UI for redigering**

- Opprett `LineItemEditView`
- Legg til redigeringsfunksjonalitet i `EditReceiptViewModel`
- Integrer redigering i `EditReceiptView`

5. **Fase 5: Oppdatere ReceiptDetailView**

- Legg til redigeringsmulighet i detaljvisningen
- Legg til "Vis OCR-detaljer" knapp

## 5. Filstruktur

```javascript
Kvittering/
├── Services/
│   └── OCRService.swift (oppdatert)
├── ViewModels/
│   └── EditReceiptViewModel.swift (oppdatert)
├── Views/
│   ├── EditReceiptView.swift (oppdatert)
│   ├── ReceiptDetailView.swift (oppdatert)
│   ├── LineItemEditView.swift (ny)
│   └── OCRDetailsView.swift (ny)
└── Models/
    └── Receipt.swift (ingen endringer nødvendig)

KvitteringTests/
├── Services/
│   └── LineItemsTests.swift (utvidet)
└── Helpers/
    └── TestHelpers.swift (utvidet)
```



## 6. Viktige detaljer

- **Norsk lokaliserte formater**: Alle priser skal håndtere både norsk (komma) og engelsk (punktum) format
- **Validering**: Alle varelinjer skal valideres mot totalbeløp og realistiske verdier
- **Brukeropplevelse**: OCR-detaljer skal være skjult bak en knapp for å ikke forstyrre normal bruk
- **Redigering**: Brukere skal kunne redigere varelinjer både under opprettelse og etter lagring