# Ghar 360

Ghar 360 is a Flutter real-estate search prototype for Gurgaon properties. It lets users describe what they want in natural language, converts that request into structured search filters with an OpenRouter-hosted LLM, ranks mock property listings locally, and presents AI-assisted summaries, match scores, property details, comparison tools, voice input, and buyer-focused advisory answers.

## Tech Stack

- **Framework:** Flutter
- **Language:** Dart
- **LLM provider:** OpenRouter Chat Completions API
- **LLM model:** `google/gemma-3-27b-it:free`
- **State management:** `provider`
- **Local data:** in-memory mock property list in `lib/data/properties.dart`
- **Persistence:** `shared_preferences` for recently viewed property IDs
- **Voice input:** `speech_to_text`
- **HTTP:** `http`
- **UI/loading packages:** `shimmer`, `cached_network_image`, `flutter_animate`, `cupertino_icons`
- **Testing:** `flutter_test`, `flutter_lints`

Packages used in `pubspec.yaml`:

```yaml
provider: ^6.1.2
http: ^1.6.0
speech_to_text: ^6.6.2
shimmer: ^3.0.0
shared_preferences: ^2.2.3
flutter_animate: ^4.5.0
cupertino_icons: ^1.0.8
cached_network_image: ^3.4.1
flutter_lints: ^6.0.0
```

## Getting Started

### Prerequisites

- Flutter SDK installed and available on your `PATH`
- Dart SDK through Flutter
- A browser for web testing
- An OpenRouter API key

### Clone instructions

The project/repo name is `ghar_360`.

```bash
git clone https://github.com/<your-username>/ghar_360.git
cd ghar_360
```

### Install dependencies

```bash
flutter pub get
```

### Pass the API key

This project reads the OpenRouter key with `String.fromEnvironment('OPENROUTER_API_KEY')` in `lib/services/llm_service.dart`, so pass it with `--dart-define`.

Do **not** use `.env` for the GitHub submission.

```bash
flutter run -d chrome --dart-define=OPENROUTER_API_KEY=your_openrouter_api_key_here
```

### Run on web

```bash
flutter run -d chrome --dart-define=OPENROUTER_API_KEY=your_openrouter_api_key_here
```

For a release web build:

```bash
flutter build web --dart-define=OPENROUTER_API_KEY=your_openrouter_api_key_here
```

## Features

### Natural language search

The hero search bar in `lib/widgets/hero_search_widget.dart` accepts queries such as `2 BHK in Gurugram under ₹80L`, `Villa with pool near DPS school`, and `Furnished flat near Cyber City`. When submitted, `HomeScreen._triggerSearch` calls `AppProvider.updateQuery`, which sends the text to `QueryParser.parse`. The parser asks the LLM to return structured JSON fields such as `bhk`, `maxBudget`, `location`, `landmark`, `propertyType`, `facing`, `amenities`, and `furnished`.

### AI Overview card

After search results are computed, `AppProvider.generateAiOverview` calls `LlmService.generateOverview`. The UI renders this through `AiOverviewWidget`, showing:

- number of matching properties
- short AI summary
- best match title, price, and match score
- quick insight chips
- expandable full analysis sections such as Best Match, Runner-Up, Pros, Cons, Investment Score, Rental Yield, Family Suitability, Future Appreciation, Nearby Schools, and Nearby Hospitals

### Property cards with match score

`PropertyGrid` renders `PropertyCard` widgets from `provider.results`. Each card shows:

- property image
- BHK and area
- location
- price in lakhs
- top amenities
- favorite button
- comparison checkbox
- match percentage badge when `property.matchScore` is available

The match score is calculated locally in `SearchService.search` after the LLM has parsed the user's query.

### Property detail page

Tapping a property card navigates to `/property`, which loads `PropertyDetailsScreen`. The detail page includes:

- large image header using `CachedNetworkImage`
- favorite and share actions
- price and title header card
- key details: BHK, area, baths, parking, floor, furnishing
- expandable Amenities section
- expandable Nearby Places section
- expandable Match Breakdown section when a match score exists
- sticky bottom actions for scheduling a visit and making an offer

### Ask AI About This Property

`PropertyDetailsScreen` includes an `Ask AI About This Property` section. Users can type a question or tap chips such as:

- `Is this overpriced?`
- `Good for rental investment?`
- `What are the drawbacks?`
- `Future appreciation?`

The screen calls `LlmService.analyzeProperty`, sending the selected property's details plus the user's question to the LLM. If the call fails, the UI receives a clear failure message instead of crashing.

### Recent searches chips

`HeroSearchWidget` maintains a local `_recentSearches` list. It starts with sample chips such as `2BHK Sector 50`, `Under 80L`, `3BHK near metro`, `Ready to move`, and `Sector 57 villa`. New searches are inserted at the front, duplicates are removed case-insensitively, and the list is capped at 5 items.

### Filter pills

The hero section includes filter pills implemented in `HeroSearchWidget._buildFiltersRow`. Available filters are:

- BHK Type: `1BHK`, `2BHK`, `3BHK`, `4BHK+`
- Budget: `Under 50L`, `50–80L`, `80L–1Cr`, `Above 1Cr`
- Locality: `Sector 50`, `Sector 57`, `DLF Phase 1`, `Golf Course Road`, `Sohna Road`
- Possession: `Ready to Move`, `Within 1 Year`, `Under Construction`
- Amenities: `Near Metro`, `Near School`, `Gated Society`, `With Parking`, `East Facing`

Filter values are stored in `AppProvider.activeFilters` and applied by `SearchService._matchesFilters`.

### Voice input

Voice input is implemented by `VoiceService` with the `speech_to_text` package. It is used in the hero search bar and the AI Property Advisor. The service:

- initializes speech recognition once
- requests microphone permission
- prefers `en_IN` when available
- listens for up to 12 seconds
- supports partial results
- converts speech errors into friendly messages such as microphone permission, network, or unavailable-device warnings

### AI Property Advisor

`PropertyAdvisorWidget` is a conversational advisor panel on the home page. It can answer questions about the top matching properties, including suggestion chips such as:

- `Which property is best for a family?`
- `Which one is closest to schools?`
- `I need a property with good amenities.`
- `Which property gives the best value for money?`
- `Compare the top 3 options.`

The widget calls `AppProvider.askAdvisor`, which delegates to `PropertyAdvisorService.askAdvisor`. That service sends the top 5 current results as compact JSON and asks the model for a practical Indian home-buyer recommendation.

### All Properties browse mode

The desktop app bar includes a `Properties` action. Clicking it calls `AppProvider.resetToAllProperties`, clears active search state, and shows the All Properties section. On the home page this section initially shows 3 listings and expands in-place when the user clicks `View all ... properties`.

### Property comparison

Each `PropertyCard` includes a comparison checkbox. `ComparisonProvider` stores up to 3 selected properties. Once at least 2 are selected, a floating `Compare` action appears and opens `ComparisonScreen`, which renders a side-by-side comparison table for image, price, BHK, area, furnishing, amenities, nearby schools, nearby hospitals, parking, and building age.

### Favorites

`AppProvider` keeps a `Set<String>` of favorite property IDs. `PropertyCard` and `PropertyDetailsScreen` both use this state to toggle heart icons.

### Recently viewed storage

`RecentlyViewedService` stores viewed property IDs in `SharedPreferences` under `recently_viewed_properties`. It removes duplicates, pushes the latest view to the front, and caps the list at 20 IDs. The current code records views when `PropertyDetailsScreen` opens.

### Floating AI Advisor shortcut

`AiAdvisorFab` is a persistent bottom-left floating action button. It uses `AdvisorNavigation` to scroll the home screen to the AI Property Advisor section.

### Loading, shimmer, and fallback UI

The app uses shimmer/loading UI in property grids, image loading, and AI overview states. `AiOverviewWidget` also provides a retry button when AI analysis is unavailable.

## Architecture

```text
UI Layer
├── lib/screens/
│   ├── home_screen.dart
│   ├── property_details_screen.dart
│   └── comparison_screen.dart
├── lib/widgets/
│   ├── hero_search_widget.dart
│   ├── property_grid.dart
│   ├── property_card.dart
│   ├── ai_overview_widget.dart
│   ├── property_advisor.dart
│   └── ai_advisor_fab.dart
│
State Layer
├── lib/providers/
│   ├── app_provider.dart
│   └── comparison_provider.dart
│
Service Layer
├── lib/services/
│   ├── llm_service.dart
│   ├── query_parser.dart
│   ├── search_service.dart
│   ├── property_advisor_service.dart
│   ├── voice_service.dart
│   └── recently_viewed_service.dart
│
Data / Model Layer
├── lib/data/
│   ├── properties.dart
│   ├── mock_properties.dart
│   └── types.dart
│
Core / Utilities
├── lib/core/
│   ├── app_colors.dart
│   └── app_theme.dart
├── lib/utils/
│   ├── debounce.dart
│   ├── match_scoring.dart
│   ├── price_formatter.dart
│   └── theme.dart
└── lib/navigation/
    └── advisor_navigation.dart
```

Layer flow:

```text
User interface
  ↓
Provider state
  ↓
LLM / search / voice / persistence services
  ↓
Typed models and mock property data
```

## Data Flow

1. The user enters a query in `HeroSearchWidget` and submits it by pressing Search, pressing Enter, tapping a recent-search chip, tapping a popular-search chip, or completing voice input.
2. `HeroSearchWidget` calls the `onSearchTriggered` callback provided by `HomeScreen`.
3. `HomeScreen._triggerSearch` stores the text in `_listingSearchController`, marks the property list as expanded for search mode, and calls `context.read<AppProvider>().updateQuery(queryText)`.
4. `AppProvider.updateQuery` saves the raw query, clears old AI advisor/overview output, and returns all mock properties immediately if both the query and active filters are empty.
5. For a non-empty text query, `AppProvider.updateQuery` calls `QueryParser.parse(newQuery)`.
6. `QueryParser.parse` builds a user prompt and sends it with the structured extraction system prompt to `LlmService.ask`.
7. `LlmService.ask` posts to `https://openrouter.ai/api/v1/chat/completions` with model `google/gemma-3-27b-it:free` and the API key from `--dart-define=OPENROUTER_API_KEY=...`.
8. `QueryParser` receives the LLM response, strips markdown code fences if present, decodes JSON, and converts it into `ParsedQuery`.
9. `AppProvider.updateQuery` passes the `ParsedQuery`, `mockProperties`, and active filter map to `SearchService.search`.
10. `SearchService.search` applies hard filters for BHK, budget, and location, soft scores landmarks, amenities, and furnishing, normalizes the score against the query's possible score, adds match reasons, and sorts results by best score first.
11. `AppProvider` stores the ranked list in `results`, calls `generateAiOverview` in the background, clears loading state, and notifies listeners.
12. `HomeScreen` rebuilds because it watches `AppProvider`.
13. `AiOverviewWidget` appears above results for searched/filtered states and shows loading, fallback, or loaded AI overview content.
14. `PropertyGrid` reads `provider.results` and renders `PropertyCard` widgets.
15. Each `PropertyCard` displays property data and the local match percentage if `matchScore` exists.

## Model Choice

The project uses `google/gemma-3-27b-it:free` through OpenRouter. This is visible in `lib/services/llm_service.dart`, and the same model is documented in `constants.example.dart` and `ARCHITECTURE.md`.

Gemma 3 27B was chosen for this prototype because the app needs a model that can do two jobs reliably:

- return strict JSON for natural-language query parsing
- write concise real-estate summaries and advisor answers in Indian market context

The existing project notes in `ARCHITECTURE.md` describe the free OpenRouter model as the largest free-tier model used by the project, selected for reliable JSON output and no-credit-card/free-tier accessibility. That matters for a GitHub/demo submission because evaluators can run the app without paid model setup, while still getting enough reasoning ability for structured extraction, search summaries, and buyer-style recommendations.

The code also includes local deterministic ranking in `SearchService`, so the LLM is not responsible for every result decision. Gemma parses intent and writes summaries; the app itself filters, scores, and sorts properties.

## Prompt Design Notes

### Actual query parsing system prompt

From `lib/services/query_parser.dart`:

```text
You are a structured data extractor for an Indian real estate search platform.
Your sole task is to parse a user's natural language property query and return a single, valid JSON object.

EXTRACTION RULES:
1.  **bhk** (integer | null): Number of bedrooms. Extract from patterns like "2BHK", "2 bhk", "two bedroom", "double bedroom", "studio" → 1. If not mentioned, return null.
2.  **maxBudget** (number | null): Maximum price in INR (Indian Rupees). 
    - Convert "lakh/lac" → multiply by 100000 (e.g., "50 lakh" → 5000000)
    - Convert "crore/cr" → multiply by 10000000 (e.g., "1.5 crore" → 15000000)
    - Strip all symbols (₹, Rs, commas). Return as a plain number.
    - If a range is given (e.g., "40-60 lakh"), use the upper bound.
    - If not mentioned, return null.
3.  **location** (string | null): The area, neighbourhood, city, or district. Normalise to title case (e.g., "koramangala" → "Koramangala"). If not mentioned, return null.
4.  **landmark** (string | null): A specific nearby landmark such as a metro station, school, hospital, mall, or tech park. Normalise to title case. If not mentioned, return null.
5.  **propertyType** (string | null): One of — "apartment", "villa", "plot", "house", "pg", "commercial", "office". Infer from context (e.g., "flat" → "apartment", "independent house" → "house"). If ambiguous or not mentioned, return null.
6.  **facing** (string | null): Cardinal direction the property faces — "north", "south", "east", "west", "north-east", etc. If not mentioned, return null.
7.  **amenities** (array of strings): List of desired amenities. Normalise each to lowercase. Examples: "gym", "swimming pool", "parking", "lift", "security", "power backup", "clubhouse", "garden". Return [] if none mentioned.
8.  **furnished** (boolean | null): true = "furnished" / "fully furnished", false = "unfurnished" / "bare shell", null = not mentioned.

OUTPUT RULES:
- Return ONLY the raw JSON object. No explanation, no markdown, no code fences.
- All string values must be properly escaped.
- Never hallucinate values. If a field cannot be confidently extracted, use null or [].
```

The user prompt paired with it is:

```text
Parse this real estate query and return the JSON:

"$query"
```

### Actual property summary / AI Overview system prompt

From `LlmService.generateOverview` in `lib/services/llm_service.dart`:

```text
You are an AI Overview assistant. Write a highly concise 2-sentence summary comparing these properties and showing why they match. Do not include markdown.
```

The user prompt paired with it is built as:

```text
Provide a brief summary card overview of the best properties that match this search query: "$query".${filtersContext.isNotEmpty ? "\n$filtersContext" : ""}
Here are the top properties to choose from: ${jsonEncode(propertiesSummary)}.
```

### Actual full recommendation system prompt

From `LlmService.generateFullRecommendation`:

```text
You are an expert Indian real estate advisor. Analyze these properties and the user's query. Return a structured recommendation with these exact sections separated by headers:
BEST_MATCH | RUNNER_UP | PROS | CONS | INVESTMENT | RENTAL_YIELD | FAMILY | APPRECIATION | SCHOOLS | HOSPITALS
Be specific, use Indian market context, mention actual numbers.
Keep each section under 80 words.
```

The user prompt paired with it is:

```text
User query: $query
${filtersContext.isNotEmpty ? "$filtersContext\n" : ""}Properties: ${jsonEncode(topThree)}
Provide the full analysis.
```

### Actual specific-property advisor system prompt

From `LlmService.analyzeProperty`:

```text
You are Ghar360's expert AI Property Advisor. The user is asking a question about a specific property. Answer the question comprehensively but concisely based on the property details provided. Keep your answer under 100 words and be specific to Indian real estate market details.
```

### Actual multi-property advisor system prompt

From `PropertyAdvisorService.askAdvisor`:

```text
You are an expert Indian real estate advisor. Answer in plain English only.

Rules:
1. Keep the full answer under 100 words.
2. No markdown, asterisks, hashtags, bullet symbols, or emojis.
3. Use short sentences and line breaks between ideas.
4. Name properties by BHK, price in Lakhs, and location (not raw IDs).
5. State one best pick, one alternative if relevant, and one honest drawback.
6. Be direct and practical for a home buyer in India.
```

### Prompt design decisions

- **"Structured data extractor" role:** The query parser is not asked to be a chat assistant. It is assigned a narrow extraction role so its output can feed `ParsedQuery.fromJson` without extra interpretation.
- **"Single, valid JSON object":** The parser response is decoded directly with `jsonDecode`, so the prompt must reduce prose, arrays of candidates, or explanations.
- **Explicit field schema:** The app's search layer only understands `bhk`, `maxBudget`, `location`, `landmark`, `propertyType`, `facing`, `amenities`, and `furnished`. Listing the fields keeps the model aligned with the Dart model.
- **Indian budget conversion rules:** The property data stores prices as INR integers. The prompt converts lakh/lac and crore/cr into raw rupee numbers so `SearchService` can compare `property.price <= query.maxBudget`.
- **Range upper bound rule:** If a user says `40-60 lakh`, the app needs a single maximum budget. Using the upper bound makes the query compatible with `maxBudget`.
- **Title-case locations:** Search compares lowercased strings, but normalized locations make match reasons and logs cleaner.
- **Lowercase amenities:** Amenities in mock data are lowercase (`gym`, `pool`, `metro`, `park`, etc.), so lowercasing improves matching.
- **Null and empty array rules:** `SearchService` treats non-null fields as active constraints. Returning `null` or `[]` prevents accidental filtering when the user did not specify a field.
- **No hallucination rule:** The app uses parsed fields to exclude properties. A hallucinated BHK, location, or budget could remove valid results, so the prompt explicitly says to use null/empty values when unsure.
- **No markdown/code fences:** The parser attempts to decode raw JSON. The code still strips code fences defensively, but the prompt tries to prevent them first.
- **Concise 2-sentence overview:** The overview card is compact and appears above the grid. The system prompt keeps it short enough for the UI and forbids markdown.
- **Exact full-analysis headers:** `LlmService._parseFullRecommendation` searches for known section names. The prompt lists headers exactly so the parser can split the LLM response into UI sections.
- **Indian market context:** Property questions in this app involve Gurgaon/Gurugram prices, rental yields, schools, hospitals, parking, and family suitability. The prompts ask for Indian real-estate context so answers are not generic.
- **Word limits:** The overview, full recommendation, property-level advisor, and multi-property advisor all have length limits because they render inside cards and panels.
- **Plain-English/no-markdown advisor prompt:** `PropertyAdvisorService.formatAdvisorAnswer` strips markdown and emoji noise, but the prompt also forbids them so the response starts closer to the intended UI style.
- **Name by BHK, price, and location rather than raw ID:** Raw IDs are useful internally, but home buyers understand `3 BHK at ₹125L in DLF Phase 1` better than `Property ID 2`.
- **One best pick, one alternative, one drawback:** The advisor is designed to be practical, not just positive. This rule forces a recommendation, a backup option, and an honest limitation.

### What was tried first that did not work

The git history shows the first OpenRouter service at commit `40e2dbc` only sent a user message through `LlmService.ask(String prompt)` and did not support a system prompt. Later code added `systemPrompt` support, strict query-parser instructions, retries, and JSON cleanup. This indicates the project moved away from generic prompting because structured search needed more deterministic model behavior.

The current parser also includes `_extractAndDecodeJson`, which strips ```json code fences before decoding. That fallback exists because the model may wrap JSON in markdown even when the prompt says not to. In other words, "return JSON" alone was not treated as reliable enough; the final design combines explicit prompt rules with response sanitization.

The advisor service includes `formatAdvisorAnswer`, which removes bold markdown, inline code marks, headings, bullets, numbering, and emojis. That cleanup is a clue from the implemented fallback logic: plain-English advisor answers can still arrive with formatting artifacts, so the final version both forbids markdown in the prompt and strips it after the call.

The first search ranking service in commit `cd66918` focused on parsed-query scoring. The current version adds `activeFilters` and `_matchesFilters`, showing that free-text parsing alone was expanded with deterministic UI filter pills for predictable user-controlled narrowing.

### Why Gemma 3 was chosen over other free models

The codebase and project notes point to `google/gemma-3-27b-it:free` because it gives the prototype a free OpenRouter model with enough capacity for structured extraction and real-estate explanation. The parser needs reliable JSON, while the advisor needs buyer-friendly reasoning. A smaller or less instruction-following free model would be more likely to break JSON shape, ignore rupee conversion rules, or produce noisy prose. The local search layer reduces risk by keeping final filtering/scoring deterministic, but Gemma 3 27B is still used where language understanding is needed.

## Error Handling & Fallbacks

- **Missing API key:** `LlmService.ask` throws `Exception('Missing API Key')` if `OPENROUTER_API_KEY` is not provided through `--dart-define`.
- **OpenRouter non-200 response:** `LlmService.ask` throws `Exception('API Error: ${response.body}')`.
- **Empty search query:** `AppProvider.updateQuery` resets results to all `mockProperties`, clears match scores/reasons, and returns without calling the LLM.
- **Query parser retries:** `QueryParser.parse` retries up to 3 total attempts (`_maxRetries = 2` plus the first attempt).
- **Markdown-wrapped JSON:** `QueryParser._extractAndDecodeJson` strips ```json or plain ``` fences before `jsonDecode`.
- **Invalid parser output:** If decoded output is not a JSON object, a `FormatException` is raised. If every parsed field is empty, `QueryParseException('No recognisable real estate fields were found in the query.')` is raised.
- **Search error:** `AppProvider.updateQuery` catches search/parsing exceptions, logs `Search Error`, sets `results = []`, and marks `aiOverviewState = AiState.error`.
- **No matching properties:** `LlmService.generateOverview` returns a local `AiOverview` with `No property matches`, `N/A`, score `0.0`, and guidance to adjust budget/location/amenities.
- **Overview generation failure:** `LlmService.generateOverview` catches failures and builds a plain fallback sentence using result count, best title, best price, and match score.
- **Full recommendation failure:** `LlmService.generateFullRecommendation` catches errors, logs them with `debugPrint`, and returns `buildFallbackRecommendation`.
- **Fallback recommendation:** `buildFallbackRecommendation` locally creates sections for `BEST_MATCH`, `PROS`, `CONS`, `INVESTMENT`, `RENTAL_YIELD`, `FAMILY`, `APPRECIATION`, and optional `RUNNER_UP`, `SCHOOLS`, `HOSPITALS`.
- **Recommendation merge:** `mergeRecommendations` fills missing LLM sections with fallback sections so the expanded overview can still render useful content.
- **Property-specific AI failure:** `LlmService.analyzeProperty` returns `Sorry, I couldn't analyze this property at the moment: $e`.
- **Multi-property advisor failure:** `PropertyAdvisorService.askAdvisor` returns `Unable to reach the advisor right now. Please try again in a moment.`
- **Advisor with no results:** `PropertyAdvisorService.askAdvisor` returns `Please search for properties first before asking the Advisor.`
- **Voice initialization failure:** `VoiceService.init` catches initialization errors, logs them, and returns `false`.
- **Voice permission/device/network errors:** `VoiceService` maps raw speech errors to friendly UI messages such as microphone permission required, internet required, speech unavailable, or voice input failed.
- **Image loading failure:** `PropertyCard` and `PropertyDetailsScreen` render broken-image placeholders when network images fail.
- **Comparison cap:** `ComparisonProvider.toggleSelection` limits selected comparison properties to 3.

## Project Structure

```text
ghar_360/
├── README.md
├── ARCHITECTURE.md
├── PROMPT_DESIGN_NOTES.md
├── LOOM_SCRIPT.md
├── constants.example.dart
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── ghar_360.iml
├── lib/
│   ├── app.dart
│   ├── main.dart
│   ├── core/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   ├── data/
│   │   ├── mock_properties.dart
│   │   ├── properties.dart
│   │   └── types.dart
│   ├── navigation/
│   │   └── advisor_navigation.dart
│   ├── providers/
│   │   ├── app_provider.dart
│   │   └── comparison_provider.dart
│   ├── screens/
│   │   ├── comparison_screen.dart
│   │   ├── home_screen.dart
│   │   └── property_details_screen.dart
│   ├── services/
│   │   ├── llm_service.dart
│   │   ├── property_advisor_service.dart
│   │   ├── query_parser.dart
│   │   ├── recently_viewed_service.dart
│   │   ├── search_service.dart
│   │   └── voice_service.dart
│   ├── utils/
│   │   ├── debounce.dart
│   │   ├── match_scoring.dart
│   │   ├── price_formatter.dart
│   │   └── theme.dart
│   └── widgets/
│       ├── ai_advisor_fab.dart
│       ├── ai_overview_widget.dart
│       ├── app_logo.dart
│       ├── hero_search_widget.dart
│       ├── match_badge.dart
│       ├── property_advisor.dart
│       ├── property_card.dart
│       ├── property_grid.dart
│       ├── property_image_cube.dart
│       ├── property_model.dart
│       └── search_bar.dart
├── test/
│   └── widget_test.dart
├── web/
│   ├── favicon.png
│   ├── index.html
│   ├── manifest.json
│   └── icons/
│       ├── Icon-192.png
│       ├── Icon-512.png
│       ├── Icon-maskable-192.png
│       └── Icon-maskable-512.png
├── android/
│   ├── app/
│   ├── build.gradle.kts
│   ├── gradle.properties
│   └── settings.gradle.kts
├── ios/
│   ├── Flutter/
│   ├── Podfile
│   ├── Runner/
│   ├── Runner.xcodeproj/
│   ├── Runner.xcworkspace/
│   └── RunnerTests/
├── macos/
│   ├── Flutter/
│   ├── Podfile
│   ├── Runner/
│   ├── Runner.xcodeproj/
│   ├── Runner.xcworkspace/
│   └── RunnerTests/
├── linux/
│   ├── CMakeLists.txt
│   ├── flutter/
│   └── runner/
└── windows/
    ├── CMakeLists.txt
    ├── flutter/
    └── runner/
```
