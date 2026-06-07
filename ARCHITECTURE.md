# 360 Ghar | AI Property Search — Architecture Document

## Project Overview

Smart property search UI that leverages AI to parse natural language queries and return
intelligently ranked property cards with AI-generated match explanations.

**Stack**: Flutter + Provider + OpenRouter LLM + Mock Dart Data  
**Deployment**: GitHub Pages / Firebase Hosting (frontend only)  
**Duration**: 2–3 days  
**No backend required** — all LLM calls made directly from Flutter to OpenRouter.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│               UI Layer (lib/widgets/)                   │
│         Flutter Widgets + flutter_animate               │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│           State Layer (lib/providers/)                  │
│        Single ChangeNotifier via Provider               │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│           Services Layer (lib/services/)                │
│     LLM calls (http) · Filtering · Voice input          │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              Data Layer (lib/data/)                     │
│   Mock properties · OpenRouter API · SharedPreferences  │
└─────────────────────────────────────────────────────────┘
```

---

## File Structure

```
360_ghar/
├── lib/
│   ├── main.dart                     # runApp + MultiProvider setup
│   ├── app.dart                      # MaterialApp, theme, routes
│   │
│   ├── providers/
│   │   └── app_provider.dart         # Single ChangeNotifier — all app state
│   │
│   ├── widgets/
│   │   ├── search_bar.dart           # TextField + mic IconButton
│   │   ├── property_grid.dart        # GridView.builder + shimmer loading
│   │   ├── property_card.dart        # Card: image, price, BHK, MatchBadge
│   │   ├── property_modal.dart       # Bottom sheet: detail + live AI summary
│   │   └── match_badge.dart          # Chip row: "Great sunlight · Near DPS"
│   │
│   ├── services/
│   │   ├── llm_service.dart          # parseQuery() + explainMatch() via http
│   │   ├── search_service.dart       # filterAndRank() + buildMatchReasons()
│   │   └── voice_service.dart        # speech_to_text wrapper (bonus feature)
│   │
│   ├── data/
│   │   ├── properties.dart           # List<Property> mockProperties — 12 entries
│   │   └── types.dart                # Property, ParsedQuery, MatchResult models
│   │
│   └── utils/
│       ├── constants.dart            # API key, model name, base URL
│       ├── price_formatter.dart      # formatLakhs(int rupees) → "₹75L"
│       ├── match_scoring.dart        # scoreProperty() → 0.0 to 1.0
│       └── debounce.dart             # Debouncer class using Timer
│
├── pubspec.yaml
├── .gitignore                        # must include constants.dart
├── constants.example.dart            # placeholder for reviewers
├── README.md
├── ARCHITECTURE.md                   # this file
└── PROMPT_DESIGN_NOTES.md
```

---

## Technology Stack

| Layer            | Technology                             | Why |
|---               |---                                     |---|
| Framework        | Flutter (Dart)                         | Cross-platform, fast UI, rich widget ecosystem |
| State management | Provider 6 (ChangeNotifier)            | Simple, readable, no boilerplate — reviewers can follow it instantly |
| HTTP client      | http ^1.2.1                             | Lightweight, sufficient for direct API calls |
| LLM API          | OpenRouter — google/gemma-3-27b-it:free | Largest free-tier model, reliable JSON output, no credit card needed |
| Voice input      | speech_to_text ^6.6.2       | Browser Speech API equivalent for Flutter, bonus feature |
| Loading skeleton | shimmer ^3.0.0              | Polished loading state on property cards |
| Local storage    | shared_preferences ^2.2.3   | Persist search history on device |
| Animations       | flutter_animate ^4.5.0      | One-liner card entry animations |
| Deployment       |  GitHub Pages               | Zero-config Flutter web deploy |

---

## pubspec.yaml Dependencies

```yaml
name: ghar_360
description: AI Property Search — 360 Ghar intern assignment

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  http: ^1.2.1
  speech_to_text: ^6.6.2
  shimmer: ^3.0.0
  shared_preferences: ^2.2.3
  flutter_animate: ^4.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## Detailed Component Breakdown

### 1. main.dart

```dart
// Wrap app in MultiProvider at root.
// Register AppProvider here.
// Call WidgetsFlutterBinding.ensureInitialized() before runApp.
```

### 2. providers/app_provider.dart

State this ChangeNotifier holds:

```dart
String query = '';
ParsedQuery? parsedFilters;
List<Property> results = [];
bool isLoading = false;
String? error;
Property? selectedProperty;
List<String> searchHistory = [];   // loaded from SharedPreferences
```

Key methods:

```dart
Future<void> search(String query)   // debounce → parseQuery → filterAndRank → notify
void selectProperty(Property p)     // sets selectedProperty → triggers modal
void clearError()
Future<void> loadHistory()
Future<void> saveToHistory(String q)
```

### 3. widgets/search_bar.dart

- `TextField` with `onChanged` → calls `provider.search()` after 300ms debounce
- `IconButton` with mic icon → calls `VoiceService.startListening()`
- Shows recent searches as `ListTile` suggestions below the field when focused

### 4. widgets/property_grid.dart

- `Consumer<AppProvider>` wrapping a `GridView.builder`
- When `isLoading == true`: show `Shimmer` skeleton cards
- When `results.isEmpty` after load: show "No properties found" with suggestion text
- Cards animate in using `flutter_animate`: `.fadeIn(duration: 300.ms).slideY(begin: 0.08)`

### 5. widgets/property_card.dart

Each card displays:
- 360° placeholder image (use a solid color block with a camera icon — keep it clean)
- BHK type + area: "2 BHK · 1,200 sq ft"
- Location: "Sector 50, Gurgaon"
- Price: "₹75L" (formatted via `price_formatter.dart`)
- `MatchBadge` widget with reason chips
- `matchScore` shown as a subtle percentage or colored border (higher score = stronger teal border)

On tap → `provider.selectProperty(property)` → opens `PropertyModal`

### 6. widgets/match_badge.dart

```dart
// Renders a horizontal Wrap of Chip widgets
// e.g. ["Great sunlight", "Near DPS School", "Within budget"]
// Chip color: teal background, white text
// Max 3 chips per card to keep it clean
```

### 7. widgets/property_modal.dart

- `showModalBottomSheet` triggered when `selectedProperty` is set
- Shows full property details at top
- Below details: a dedicated section "Why this matches your search"
- On open: immediately calls `LLMService.explainMatch(query, property)`
- While loading: shimmer placeholder text (2–3 lines wide)
- On response: animated fade-in of the AI-generated summary text

### 8. services/llm_service.dart

Two methods, both POST to OpenRouter:

```dart
Future<ParsedQuery> parseQuery(String userQuery)
Future<String> explainMatch(String originalQuery, Property property)
```

OpenRouter request shape:

```dart
{
  "model": "google/gemma-3-27b-it:free",
  "messages": [
    { "role": "system", "content": systemPrompt },
    { "role": "user", "content": userQuery }
  ]
}
```

Headers required:

```dart
{
  "Authorization": "Bearer $apiKey",
  "Content-Type": "application/json",
  "HTTP-Referer": "https://360ghar.com",   // required by OpenRouter
  "X-Title": "360 Ghar Property Search"   // shows in OpenRouter dashboard
}
```

### 9. services/search_service.dart

```dart
List<Property> filterAndRank(List<Property> all, ParsedQuery filters)
List<String> buildMatchReasons(Property p, ParsedQuery filters)
double scoreProperty(Property p, ParsedQuery filters)
```

Scoring weights:

```
Location match    → 40%
Price in range    → 30%
Amenity match     → 20%
Preference match  → 10%
```

`buildMatchReasons()` maps filter fields to human strings:
- sunlight in amenities → "Great natural sunlight"
- nearbySchools not empty + schools in preferences → "Near DPS School"
- price ≤ parsedFilters.max → "Within your ₹80L budget"

### 10. services/voice_service.dart

```dart
// Uses speech_to_text package
// startListening() → returns Stream<String> of partial results
// stopListening()
// Feed final result into SearchBar's TextEditingController
```

### 11. data/types.dart

```dart
class Property {
  final String id;
  final int bhk;
  final int area;              // sq ft
  final String location;       // "Sector 50, Gurgaon"
  final int sector;
  final int price;             // in rupees
  final List<String> amenities;
  final String furnishing;     // unfurnished / semi / furnished
  final int ageYears;
  final int floor;
  final int totalFloors;
  final List<String> nearbySchools;
  final List<String> nearbyHospitals;
  final int parking;
  double? matchScore;          // computed at runtime
  List<String>? matchReasons;  // computed at runtime
}

class ParsedQuery {
  final int? bhk;
  final List<String> locations;
  final List<int> sectors;
  final int? priceMin;
  final int? priceMax;
  final List<String> amenities;
  final List<String> preferences;
}

class MatchResult {
  final Property property;
  final double score;
  final List<String> reasons;
}
```

### 12. data/properties.dart

12 mock properties covering:
- Sectors: 50, 52, 53, 57, 65, 83
- BHK: 1BHK × 3, 2BHK × 6, 3BHK × 3
- Price: ₹45L to ₹1.4Cr
- Varied amenities: sunlight, pool, gym, park, metro proximity
- Nearby schools: DPS, GD Goenka, Pathways, Shriram

---

## LLM Prompt Engineering

### Prompt 1 — Query Parser (used in parseQuery())

```
You are a real estate assistant for 360 Ghar, a property platform in Gurgaon, India.

Parse the user's property search query into structured JSON.

Return ONLY valid JSON. No markdown. No code blocks. No explanation. Nothing else.

{
  "bhk": <number or null>,
  "locations": <string array or []>,
  "sectors": <number array or []>,
  "priceMin": <number in rupees or null>,
  "priceMax": <number in rupees or null>,
  "amenities": <string array or []>,
  "preferences": <string array or []>
}

Rules:
- If price is in lakhs, multiply by 100000. "80 lakhs" = 8000000.
- "DLF" maps to sector 26. "Cyber City" maps to sector 25.
- Extract all mentioned amenities: sunlight, gym, pool, park, school, hospital, metro.
- Return empty arrays for fields not mentioned. Never return null for arrays.
- Do not add fields not listed above.
```

### Prompt 2 — Match Explainer (used in explainMatch())

```
You are a helpful real estate assistant for 360 Ghar, a property platform in Gurgaon, India.

A user searched for: "{originalQuery}"

This property was matched to their search:
{propertyAsJson}

Write a 2 to 3 line explanation of why this property suits the user's search.
Be specific — reference the user's exact preferences and the property's real attributes.
Use a friendly, conversational tone.
Write prices in lakhs notation: ₹75L not ₹7500000.
Do not use bullet points. Write in plain sentences.
Respond with only the explanation. No heading. No extra formatting.
```

---

## Data Flow

```
User types query
       │
       ▼
300ms debounce (Debouncer in AppProvider)
       │
       ▼
LLMService.parseQuery()  ──→  OpenRouter API
       │                      returns ParsedQuery JSON
       ▼
SearchService.filterAndRank()
  - scoreProperty() per property
  - buildMatchReasons() per property
  - sort by matchScore descending
       │
       ▼
AppProvider.notifyListeners()
  results = rankedList
  isLoading = false
       │
       ▼
PropertyGrid rebuilds
  PropertyCard × N with MatchBadge
       │
  user taps card
       │
       ▼
PropertyModal opens
  LLMService.explainMatch()  ──→  OpenRouter API
       │                           returns summary string
       ▼
  AI summary renders in modal
       │
  query saved to SharedPreferences history
```

---

## Error Handling

```
LLM call fails
├── Network error     → show SnackBar "Check your connection"
├── JSON parse error  → show SnackBar "Could not understand query, try again"
├── Rate limit (429)  → show SnackBar "Too many requests, wait a moment"
└── Timeout           → show SnackBar "Search timed out, try a shorter query"

No results after filtering
└── Show empty state widget with tip: "Try removing the price limit"
```

---

## Bonus Feature — Voice Input

- Package: `speech_to_text ^6.6.2`
- Mic button in `SearchBar` widget
- On tap: start listening, stream partial text into the TextField live
- On silence/stop: finalize text and trigger search automatically
- Fallback: if permission denied, show a SnackBar explaining microphone access

---

## Security Note (for README)

> This is a frontend-only prototype. The OpenRouter API key is stored in `constants.dart`
> which is excluded from version control via `.gitignore`. In production, all LLM calls
> would route through a backend service to protect the API key.
> To run locally, copy `constants.example.dart` to `constants.dart` and add your key.

---

## Setup Instructions

```bash
# 1. Clone the repo
git clone https://github.com/your-username/360-ghar-search.git
cd 360-ghar-search

# 2. Install dependencies
flutter pub get

# 3. Add your API key
cp constants.example.dart lib/utils/constants.dart
# Edit constants.dart and paste your OpenRouter key

# 4. Run the app
flutter run -d chrome          # web
flutter run                    # mobile

# 5. Build for web deployment
flutter build web
firebase deploy                # or push to GitHub Pages
```

---

## Day-by-Day Plan

**Day 1** — Setup + UI shell
- Flutter project, pubspec, folder structure
- Write all 12 mock properties in properties.dart
- Write all Dart types in types.dart
- Build PropertyCard, PropertyGrid, MatchBadge, SearchBar as static widgets
- App should look good with hardcoded data by end of day

**Day 2** — AI integration + state
- Write LLMService with both prompts
- Write SearchService with scoring and reason generation
- Write AppProvider connecting everything
- Wire SearchBar → Provider → Grid end to end
- Add PropertyModal with live AI summary
- Add voice input via VoiceService

**Day 3** — Polish + submission
- Add shimmer skeletons, error states, empty states
- Add flutter_animate entry animations on cards
- Write PROMPT_DESIGN_NOTES.md
- Write README with setup instructions
- Record Loom walkthrough (2–3 min)
- Deploy to Firebase Hosting or GitHub Pages

---

## Evaluation Checklist

- [ ] Natural language parsing works across varied query styles
- [ ] Property cards show meaningful match reasons (not just filter labels)
- [ ] AI summary on card tap is personalised and references the original query
- [ ] Voice input works end to end (bonus)
- [ ] UI is polished — shimmer loading, animations, empty states
- [ ] Code is clean — one provider, three services, no spaghetti
- [ ] constants.dart is gitignored, example file provided
- [ ] README covers setup, model choice, architecture note
- [ ] PROMPT_DESIGN_NOTES.md explains prompt decisions and what failed
- [ ] Loom video shows full flow in 2–3 minutes
