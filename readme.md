# PropLens — AI-Powered Property Search

PropLens is an AI-powered property search prototype for Gurgaon, India, built as part of the 360 Ghar Software Developer Intern assignment. It lets users describe what they are looking for in plain language and returns ranked, filtered property cards with AI-generated match reasons, investment insights, and personalised property summaries — all with no backend.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Web) |
| LLM API | OpenRouter — `google/gemma-3-27b-it:free` |
| State Management | Provider (`ChangeNotifier`) |
| Voice Input | `speech_to_text` package (Browser Speech API) |
| Data | Mock JSON — 10 properties across Gurgaon sectors |

---

## Getting Started

### Prerequisites
```bash
flutter --version  # Ensure Flutter SDK is installed
```

### Clone the Repository
```bash
git clone https://github.com/your-username/proplens.git
cd proplens
```

### Install Dependencies
```bash
flutter pub get
```

### Add Your API Key
This project passes the API key at build time using `--dart-define`.
No `.env` file is needed — this is the correct approach for Flutter web.
Get a free key at [openrouter.ai](https://openrouter.ai) — no credit card required.

### Run on Web
```bash
flutter run -d chrome --dart-define=OPENROUTER_API_KEY=your_key_here
```

### Run on Mobile
```bash
flutter run --dart-define=OPENROUTER_API_KEY=your_key_here
```

---

## Features

### 1. Natural Language Search
Type anything like *"2BHK in Sector 50 under 80 lakhs near a school"* and the app parses it into structured filters using Gemma 3. The model extracts BHK type, budget, locality, landmark, amenities, facing direction, and furnished status as a strict JSON object — no dropdowns, no form fields.

### 2. AI Overview Card
After every search, an AI Overview card appears at the top of results. It summarises the matched properties, identifies the best match with its price, and generates match reason badges like "Matches 3BHK requirement" and "Has Pool" — all from a live LLM call contextualised to the user's query.

### 3. Property Cards with Match Score
Each card displays BHK type, area in sq ft, locality, price in lakhs notation, amenity tags, and a match score (0–100%) calculated by combining hard filter matches with soft preference scoring.

### 4. Property Detail Page
Tapping a card opens a full detail view with:
- Hero image with price and match score badge
- Key details grid — BHK, area, baths, parking, floor, furnished status
- Amenities section with individual tags
- Nearby Places section
- Match Breakdown — lists exactly which criteria matched and why the score is what it is

### 5. Ask AI About This Property
Each property page has a live AI chat section with pre-built prompts:
- *"Is this overpriced?"*
- *"Good for rental investment?"*
- *"What are the drawbacks?"*
- *"Future appreciation?"*

Or type any custom question. The model receives both the full property attributes and the user's original search query, so every answer is personalised to what was searched — not generic advice.

### 6. Recent Searches Chips
A horizontally scrollable chip row below the search bar stores the last 5 queries in local state. Tapping a chip repopulates the search bar and fires the query instantly. Individual chips are dismissible via the × button. New searches prepend to the list and the oldest drops off at 5.

### 7. Filter Pills
A filter row with BHK Type, Budget, Locality, Possession, and Amenities pills. Each opens a bottom sheet picker with relevant options. Active filters turn solid green, show the selected value on the pill, and get passed to the LLM as structured context alongside the natural language query — both work together.

### 8. AI Property Advisor
A floating "Ask AI" button available on every screen opens a conversational advisor with awareness of the full current search session. Pre-built prompts include *"Which property is best for a family?"* and *"Compare the top 3 options."*

### 9. Bonus Feature — Voice Input
Tap the mic icon in the search bar to speak a query naturally. The browser Speech API transcribes it live and feeds it into the same query parser as typed input — no separate code path.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│           UI Layer (lib/screens/ & lib/widgets/)        │
│         Flutter Web + slide-in micro-animations         │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              State Layer (lib/providers/)               │
│          ChangeNotifier via Provider (AppProvider)      │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│            Services Layer (lib/services/)               │
│     LlmService · SearchService · VoiceService           │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│               Data Layer (lib/data/)                    │
│         Mock Properties · Models · Types                │
└─────────────────────────────────────────────────────────┘
```

### Data Flow
1. User submits a natural language query via text or voice
2. Active filter pill selections are merged with the typed query
3. `QueryParser` sends the combined input to OpenRouter and extracts a structured JSON object
4. `SearchService` scores each mock property — hard filters first (BHK, budget, locality), then soft scoring for amenities and landmarks — producing a normalised match score per property
5. LLM generates an AI Overview card summarising the result set and identifying the best match
6. `AppProvider` notifies listeners and property cards animate in with slide transitions
7. On card tap, a second LLM call generates a personalised property summary; a third handles the Ask AI chat — both cached per property per session to avoid redundant API calls

---

## Model Choice

**`google/gemma-3-27b-it:free`** via OpenRouter.

`mistral-7b-instruct:free` was tested first — it is the most commonly recommended free model. It was rejected for two reasons: it consistently ignored the `"no markdown fences"` instruction and wrapped JSON output in code blocks, and it hallucinated budget values when processing Indian number formats like "80 lakhs" or "1.5 crore." Every response required defensive stripping and retry logic.

Gemma 3 27B was switched to next. It produced clean, schema-conforming JSON on the first attempt, handled lakh and crore conversions correctly after explicit rules were added to the prompt, and maintained low enough latency for a real-time search experience on the free tier.

---

## Prompt Design Notes

### 1. Query Parsing Prompt (`query_parser.dart`)

```
You are a structured data extractor for an Indian real estate
search platform. Your sole task is to parse a user's natural
language property query and return a single, valid JSON object.

EXTRACTION RULES:
1. bhk (integer | null): Number of bedrooms. Extract from
   patterns like "2BHK", "2 bhk", "two bedroom", "double
   bedroom", "studio" → 1. If not mentioned, return null.

2. maxBudget (number | null): Maximum price in INR.
   - Convert "lakh/lac" → multiply by 100000
   - Convert "crore/cr" → multiply by 10000000
   - Strip all symbols (₹, Rs, commas). Return as plain number.
   - If a range is given (e.g. "40-60 lakh"), use the upper bound.
   - If not mentioned, return null.

3. location (string | null): Normalise to title case.
   If not mentioned, return null.

4. landmark (string | null): Nearby metro, school, hospital,
   mall, or tech park. Normalise to title case.

5. propertyType (string | null): One of — "apartment", "villa",
   "plot", "house", "pg", "commercial", "office".
   "flat" → "apartment", "independent house" → "house".

6. amenities (array of strings): Normalise each to lowercase.
   Return [] if none mentioned.

7. furnished (boolean | null): true = "furnished", false =
   "unfurnished", null = not mentioned.

OUTPUT RULES:
- Return ONLY the raw JSON object. No explanation, no markdown,
  no code fences.
- Never hallucinate values. If a field cannot be confidently
  extracted, use null or [].
```

**Why each rule was written this way:**

- `"Return ONLY the raw JSON object"` — without this explicit instruction, Gemma 3 defaulted to wrapping output in markdown fences on the first attempt, which broke JSON parsing downstream. The instruction had to be in the OUTPUT RULES section, not buried in the system prompt preamble, for the model to reliably follow it.

- `"Convert lakh/lac → multiply by 100000"` — the model had no reliable way to infer that "80 lakhs" means 8,000,000 without explicit arithmetic rules. Left unguided, it returned strings like "80L" or the number 80, neither of which worked for numeric range filtering.

- `"If a range is given, use the upper bound"` — using the lower bound excluded valid properties that fell between the stated range. Upper bound gives broader, more useful results and matches user intent more closely.

- `"Null safety on every field"` — unspecified parameters returning null means they are simply ignored in filtering rather than incorrectly excluding properties. This was essential for vague queries like "something affordable near a school" where most fields are absent.

---

### 2. Match Explainer Prompt (`llm_service.dart`)

```
You are a helpful real estate assistant for PropLens, a property
search platform in Gurgaon, India.

A user searched for: "{originalQuery}"
This property was matched to their search: {propertyAsJson}

Write a 2 to 3 line explanation of why this property suits the
user's search. Be specific — reference the user's exact
preferences and the property's real attributes. Use a friendly,
conversational tone. Write prices in lakhs notation: ₹75L not
₹7500000. Do not use bullet points. Write in plain sentences.
Respond with only the explanation. No heading. No extra
formatting.
```

**Why each rule was written this way:**

- `"Reference the user's exact preferences"` — without this instruction the model wrote generic summaries that could apply to any property ("Great location, good amenities"). The word "exact" forced it to pull from the actual query text.

- `"Write prices in lakhs notation"` — the model defaulted to raw integers (₹7500000) which are unreadable in an Indian real estate context. Explicit notation instruction fixed this immediately.

- `"No bullet points. Write in plain sentences."` — the model defaulted to bullet-point summaries. Plain sentences feel more like a knowledgeable friend explaining a property than a data printout.

---

### 3. What Didn't Work

**Plain text parsing with regex** — the first approach asked the model to describe extracted filters in plain English ("Budget: 80 lakhs, Location: Sector 50") and then parsed those with regex. This broke immediately on vague queries like *"something affordable near a good school"* where the model used inconsistent phrasing. Switched to strict JSON schema with typed fields and null safety.

**Mistral 7B** — tested first as it is the most commonly recommended free model on OpenRouter. Rejected because it consistently wrapped JSON output in markdown fences despite the explicit instruction not to, and it hallucinated budget values on Indian number formats — returning 80 instead of 8000000 for "80 lakhs." Switching to Gemma 3 27B resolved both issues.

**Single prompt for parsing and ranking** — attempted to combine query extraction and match scoring in one LLM call to reduce latency. The model mixed structured JSON with prose explanations and the output was unpredictable across different queries. Separated into two focused prompts with single responsibilities — parsing in `query_parser.dart`, explanation in `llm_service.dart`.

**No retry logic initially** — the first version crashed silently on network timeouts. Added a 3-attempt retry loop with exponential backoff and a local heuristic fallback so the UI stays functional even when the API is unreachable.

---

## Error Handling & Fallbacks

- **Retry loop** — `QueryParser` retries failed API calls up to 3 times before giving up
- **JSON sanitisation** — `_extractAndDecodeJson` strips markdown fences (` ```json ``` `) before parsing, handling cases where the model ignores the no-fences instruction
- **Local fallback** — if all retries fail, `LlmService.buildFallbackRecommendation` applies local heuristics to generate match reasons and basic analytics so the UI never shows a broken state
- **Summary caching** — AI property summaries are cached per property per session; tapping the same card twice does not make a second API call

---

## Project Structure

```
lib/
├── data/
│   └── mock_properties.dart       # 10 mock properties across Gurgaon sectors
├── models/
│   └── property.dart              # Property model and types
├── providers/
│   └── app_provider.dart          # Central state via ChangeNotifier
├── screens/
│   ├── home_screen.dart           # Search, chips, filter pills, cards
│   └── property_detail_screen.dart # Detail view, match breakdown, Ask AI
├── services/
│   ├── llm_service.dart           # AI overview, match explainer, Ask AI chat
│   ├── query_parser.dart          # Natural language → structured JSON
│   └── voice_service.dart         # Speech-to-text via browser API
└── widgets/
    ├── property_card.dart
    ├── filter_pills.dart
    ├── recent_searches.dart
    └── ai_overview_card.dart
```

---

## Submission

- **GitHub**: this repository
- **Loom Demo**: [add your link here]
- **Assignment**: 360 Ghar Software Developer Intern — June 2026
