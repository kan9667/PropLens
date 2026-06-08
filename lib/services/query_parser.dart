import 'dart:convert';
import 'llm_service.dart';

class ParsedQuery {
  final int? bhk;
  final double? maxBudget;
  final String? location;
  final String? landmark;
  final String? propertyType;
  final String? facing;
  final List<String> amenities;
  final bool? furnished;

  const ParsedQuery({
    this.bhk,
    this.maxBudget,
    this.location,
    this.landmark,
    this.propertyType,
    this.facing,
    this.amenities = const [],
    this.furnished,
  });

  factory ParsedQuery.fromJson(Map<String, dynamic> json) {
    return ParsedQuery(
      bhk: json['bhk'] as int?,
      maxBudget: (json['maxBudget'] as num?)?.toDouble(),
      location: json['location'] as String?,
      landmark: json['landmark'] as String?,
      propertyType: json['propertyType'] as String?,
      facing: json['facing'] as String?,
      amenities: List<String>.from(json['amenities'] ?? []),
      furnished: json['furnished'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'bhk': bhk,
        'maxBudget': maxBudget,
        'location': location,
        'landmark': landmark,
        'propertyType': propertyType,
        'facing': facing,
        'amenities': amenities,
        'furnished': furnished,
      };

  bool get isEmpty =>
    bhk == null &&
    maxBudget == null &&
    location == null &&
    landmark == null &&
    propertyType == null &&
    facing == null &&
    amenities.isEmpty &&
    furnished == null;

  @override
  String toString() => 'ParsedQuery(${toJson()})';
}

class QueryParseException implements Exception {
  final String message;
  final String? rawResponse;
  const QueryParseException(this.message, {this.rawResponse});

  @override
  String toString() => 'QueryParseException: $message';
}

class QueryParser {
  static const int _maxRetries = 2;

  static const String _systemPrompt = '''
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
''';

  static String _buildUserPrompt(String query) => '''
Parse this real estate query and return the JSON:

"$query"
''';

  /// Parses a natural language real estate query into a [ParsedQuery].
  /// Throws [QueryParseException] if parsing fails after retries.
  static Future<ParsedQuery> parse(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw const QueryParseException('Query must not be empty.');
    }

    Exception? lastError;

    for (int attempt = 1; attempt <= _maxRetries + 1; attempt++) {
      try {
        final response = await LlmService.ask(
          _buildUserPrompt(trimmed),
          systemPrompt: _systemPrompt,
        );

        final json = _extractAndDecodeJson(response);
        final parsed = ParsedQuery.fromJson(json);

        if (parsed.isEmpty) {
          throw const QueryParseException(
            'No recognisable real estate fields were found in the query.',
          );
        }

        return parsed;
      } on QueryParseException {
        rethrow;
      } on FormatException catch (e) {
        lastError = QueryParseException(
          'Invalid JSON returned by LLM on attempt $attempt: ${e.message}',
        );
      } catch (e) {
        lastError = QueryParseException(
          'Unexpected error on attempt $attempt: $e',
        );
      }
    }

    throw lastError ?? const QueryParseException('Unknown parsing error.');
  }

  /// Strips markdown code fences if the model wraps JSON in them,
  /// then decodes the JSON.
  static Map<String, dynamic> _extractAndDecodeJson(String raw) {
    var cleaned = raw.trim();

    // Strip ```json ... ``` or ``` ... ``` fences
    final fencePattern = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$');
    final match = fencePattern.firstMatch(cleaned);
    if (match != null) {
      cleaned = match.group(1)!.trim();
    }

    final decoded = jsonDecode(cleaned);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Top-level JSON value must be an object.');
    }
    return decoded;
  }
}