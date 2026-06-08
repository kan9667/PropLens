# PropLens — AI-Powered Property Search

PropLens (formerly 360 Ghar) is an intelligent real estate search platform for Gurgaon, India. It leverages artificial intelligence to parse natural language queries, run structured multi-factor filters, and return intelligently ranked property cards with personalized AI-generated match summaries and structured analytics.

## Getting Started

Follow these setup instructions to run the application locally on your system.

### 1. Prerequisites
Ensure you have the Flutter SDK installed on your system. You can verify your installation by running:
```bash
flutter --version
```

### 2. Clone the Repository
Clone the project directory and navigate to the root:
```bash
cd ghar_360
```

### 3. Install Dependencies
Run the command to install the required packages:
```bash
flutter pub get
```

### 4. Setup API Key
Create a `.env` file at the root of the project to add your OpenRouter API key:
```env
OPENROUTER_API_KEY=your_openrouter_api_key_here
```
*(Make sure `.env` is listed in your `.gitignore` to protect your credentials).*

### 5. Run the Application
Start the development server for web or local simulators:
```bash
# Run on web
flutter run -d chrome

# Run on an active simulator or mobile device
flutter run
```

---

## Technical Architecture Overview

PropLens is built with a clean, decoupled layered architecture separating the presentation, business logic, services, and data layers.

```
┌─────────────────────────────────────────────────────────┐
│               UI Layer (lib/screens/ & lib/widgets/)    │
│           Flutter Presentation + micro-animations       │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│           State Layer (lib/providers/)                  │
│       ChangeNotifier via Provider (AppProvider)         │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│           Services Layer (lib/services/)                │
│    LLM Service · Search Service · Voice Input Service   │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              Data Layer (lib/data/)                     │
│       Mock Properties DB · Data Models / Types          │
└─────────────────────────────────────────────────────────┘
```

### Data Flow
1. **User Search**: The user submits a natural language search query (or taps a Recent Search chip / selects Filter pills).
2. **Query Extraction**: `AppProvider` calls `QueryParser` (in `llm_service.dart`) which queries OpenRouter's LLM to extract structured fields (BHK, maximum budget, locality, amenities, etc.) as a JSON object.
3. **Structured Matching**: `SearchService` processes the query. It matches hard requirements (such as active filters or explicit BHK/budget queries) and grades soft preferences (e.g. amenities or landmark queries) to output a normalized `matchScore` between `0.0` and `1.0`.
4. **LLM Insights & Analytics**: The LLM compiles an AI Overview explaining the best match and custom analytic sections (family friendliness, investment value, rental yield estimate, and appreciation prospects) using the structured search context.
5. **UI Rebuild**: `AppProvider` notifies listeners, causing the main screen and cards to rebuild with animated slide-in transitions.

---

## OpenRouter Model Selection

We use **google/gemma-3-27b-it** through OpenRouter as the primary model. 

### Why Gemma 3 27B IT?
- **Highly Accurate JSON Output**: Gemma 3's instruction-tuning ensures strict schema conformity, minimizing decoding failures when generating structured real estate parameters.
- **Speed & Latency**: It maintains low latency, keeping search query parsing and conversational summaries responsive.
- **Cost-Efficiency**: It provides state-of-the-art capability comparable to larger models while staying lightweight and free-tier accessible.

---

## Prompt Design Notes

Our platform relies on LLM prompts to transform messy user descriptions into structured databases and parse complex matching reasons.

### 1. Query Parsing Prompt (from `query_parser.dart`)
The LLM is initialized with the following system prompt:
```
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
...
OUTPUT RULES:
- Return ONLY the raw JSON object. No explanation, no markdown, no code fences.
- All string values must be properly escaped.
- Never hallucinate values. If a field cannot be confidently extracted, use null or [].
```

### 2. Error Handling and Fallbacks
- **Retry Mechanism**: The `QueryParser` uses a robust retry loop (up to 3 times) to automatically recover from network time-outs or malformed JSON payloads.
- **Strict Format Decoding**: If the LLM wraps its output in markdown code fences (````json ... ````), `_extractAndDecodeJson` strips the fences and extracts the clean JSON string.
- **Safe Fallback Recommendation**: In the event of persistent LLM failure, `LlmService` falls back to `buildFallbackRecommendation`, which uses local heuristics to generate structured pros, cons, and rental estimates.

---

## Bonus Features

1. **Recent Searches Chips**: Shows a horizontal row of interactive chips below the search bar. Tap to automatically populate the input and search, and tap the "X" button to dismiss individual queries. Searches are managed dynamically in local state.
2. **Horizontal Filter Pills Row**: Real-time filters (BHK Type, Budget, Locality, Possession, Amenities) that render custom bottom-sheet pickers. Selecting a filter updates the pill label, modifies the active color state, and combines with the search bar text as context.
3. **Voice Input (Speech-to-Text)**: Users can click the microphone icon in the search bar to record natural language speech. The speech is transcribed live and automatically triggers query parsing on completion.
