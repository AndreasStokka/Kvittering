# Code Review: OCR og Data Prefill Forbedringer

## 🔴 Kritiske problemer

### 1. Ingen normalisering av butikknavn
**Problem:**
- Butikknavn lagres direkte fra OCR uten normalisering
- Ingen kapitalisering (stor bokstav i starten)
- Ingen korreksjon av norske bokstaver (ÆØÅ)
- Eksempel: "Sport 1 Forde" burde bli "Sport 1 Førde"

**Lokasjon:**
- `OCRService.detectStoreName()` returnerer rå tekst
- `EditReceiptViewModel.applyOCR()` setter direkte uten normalisering
- `EditReceiptViewModel.save()` lagrer uten transformasjon

**Løsning:**
Opprett en `TextNormalizer` utility-klasse som:
- Kapitaliserer første bokstav i hvert ord
- Korrigerer norske bokstaver basert på kjente butikknavn
- Bruker `store_categories.json` som referanse for korrekte navn

### 2. Ingen post-processing av OCR-tekst
**Problem:**
- OCR-tekst brukes direkte uten korreksjon
- Vanlige OCR-feil korrigeres ikke (f.eks. "0" vs "O", "1" vs "I")
- Norske bokstaver gjenkjennes ikke alltid korrekt

**Lokasjon:**
- `OCRService.recognizeText()` returnerer rå tekst
- `OCRService.parse()` bruker rå tekst direkte

**Løsning:**
Legg til post-processing som:
- Korrigerer vanlige OCR-feil i butikknavn
- Bruker fuzzy matching mot kjente butikknavn
- Korrigerer norske bokstaver basert på kontekst

### 3. Varelinjer mangler normalisering
**Problem:**
- Produktnavn lagres direkte fra OCR
- Ingen kapitalisering eller normalisering
- OCR-feil i produktnavn korrigeres ikke

**Lokasjon:**
- `OCRService.parseLineItemsFromLines()` setter `descriptionText` direkte
- Ingen normalisering før lagring

**Løsning:**
- Normaliser produktnavn (kapitaliser første bokstav)
- Korriger vanlige OCR-feil i produktnavn

## ⚠️ Viktige forbedringer

### 4. OCR-modell evaluering
**Nåværende:**
- Vision Framework (Apple's on-device OCR)
- Støtter norsk (nb-NO, nn-NO)
- Gratis og on-device (ingen data sendes ut)

**Alternativer å vurdere:**
1. **Vision Framework med forbedret konfigurasjon:**
   - Øk `recognitionLevel` til `.accurate` (allerede gjort)
   - Legg til flere språk-variasjoner
   - Bruk `usesLanguageCorrection = true` (allerede gjort)

2. **Tesseract OCR (gratis, open source):**
   - Kan gi bedre resultater for norsk tekst
   - Krever mer setup og kan være tregere
   - Støtter trenede modeller for norsk

3. **Hybrid tilnærming:**
   - Bruk Vision Framework som primær
   - Fallback til Tesseract for vanskelige bilder
   - Post-process med fuzzy matching

**Anbefaling:**
Behold Vision Framework, men legg til:
- Bedre post-processing
- Fuzzy matching mot kjente butikknavn
- Korreksjon av norske bokstaver

### 5. Butikknavn-matching kan forbedres
**Problem:**
- `detectStoreName()` bruker enkel `contains()` matching
- Matcher ikke varianter som "Sport 1 Førde" vs "Sport 1 Forde"
- Returnerer hele linjen, ikke bare butikknavnet

**Løsning:**
- Bruk fuzzy matching mot `store_categories.json`
- Ekstraher kun butikknavnet fra linjen
- Korriger norske bokstaver basert på match

### 6. Varelinje-parsing kan forbedres
**Problem:**
- Regex-patterns er ganske grunnleggende
- Håndterer ikke alle kvitteringsformater
- Mangler støtte for komplekse formater (f.eks. rabatter, MVA)

**Løsning:**
- Utvid regex-patterns for flere formater
- Legg til støtte for rabatter og MVA
- Forbedre mengde-deteksjon (f.eks. "2x", "2 stk", "2 pcs")

## 📋 Konkrete forbedringsforslag

### Foreslått implementasjon:

1. **Opprett `TextNormalizer` utility:**
   ```swift
   struct TextNormalizer {
       static func normalizeStoreName(_ text: String) -> String
       static func normalizeProductName(_ text: String) -> String
       static func correctNorwegianCharacters(_ text: String) -> String
       static func capitalizeWords(_ text: String) -> String
   }
   ```

2. **Opprett `StoreNameMatcher` service:**
   ```swift
   class StoreNameMatcher {
       func matchAndCorrect(_ text: String) -> String?
       // Bruker store_categories.json for fuzzy matching
       // Korrigerer norske bokstaver basert på match
   }
   ```

3. **Forbedre `OCRService`:**
   - Legg til post-processing av OCR-tekst
   - Bruk `StoreNameMatcher` for butikknavn
   - Normaliser alle tekst-felter før returnering

4. **Forbedre `EditReceiptViewModel`:**
   - Normaliser `storeName` før lagring
   - Normaliser produktnavn i `lineItems` før lagring

## 🎯 Prioriterte oppgaver

### Høy prioritet:
1. ✅ Opprett `TextNormalizer` utility
2. ✅ Opprett `StoreNameMatcher` service
3. ✅ Integrer normalisering i `OCRService.detectStoreName()`
4. ✅ Normaliser butikknavn i `EditReceiptViewModel.save()`

### Medium prioritet:
5. Normaliser produktnavn i varelinjer
6. Forbedre varelinje-parsing med flere regex-patterns
7. Legg til støtte for rabatter og MVA i varelinjer

### Lav prioritet:
8. Evaluere Tesseract OCR som alternativ/fallback
9. Legg til caching av normaliserte butikknavn
10. Forbedre OCR-konfigurasjon med flere språk-variasjoner

## 📊 Forventet forbedring

Etter implementering:
- ✅ Butikknavn vil alltid starte med stor bokstav
- ✅ Norske bokstaver korrigeres automatisk (f.eks. "Førde" ikke "Forde")
- ✅ Bedre matching av butikknavn med fuzzy matching
- ✅ Mer konsistent data-kvalitet
- ✅ Bedre brukeropplevelse med mindre manuell korreksjon








