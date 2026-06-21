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

  static String _buildUserPrompt(String query) =>
      '''
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

    final fallback = _parseLocally(trimmed);
    if (!fallback.isEmpty) {
      return fallback;
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

  static ParsedQuery _parseLocally(String query) {
    final lower = query.toLowerCase();

    int? bhk;
    final digitBhk = RegExp(r'(\d+)\s*(?:bhk|bed|bedroom)').firstMatch(lower);
    if (digitBhk != null) {
      bhk = int.tryParse(digitBhk.group(1)!);
    } else if (lower.contains('studio')) {
      bhk = 1;
    } else if (lower.contains('one bedroom') ||
        lower.contains('single bedroom')) {
      bhk = 1;
    } else if (lower.contains('two bedroom') ||
        lower.contains('double bedroom')) {
      bhk = 2;
    } else if (lower.contains('three bedroom')) {
      bhk = 3;
    } else if (lower.contains('four bedroom')) {
      bhk = 4;
    }

    double? maxBudget;
    final rangeBudget = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:-|to)\s*(\d+(?:\.\d+)?)\s*(lakh|lac|cr|crore)',
    ).firstMatch(lower);
    final simpleBudget = RegExp(
      r'(?:under|below|upto|up to|less than)?\s*(?:rs\.?|₹)?\s*(\d+(?:\.\d+)?)\s*(lakh|lac|cr|crore)',
    ).firstMatch(lower);
    if (rangeBudget != null) {
      final value = double.tryParse(rangeBudget.group(2)!);
      maxBudget = _convertBudget(value, rangeBudget.group(3)!);
    } else if (simpleBudget != null) {
      final value = double.tryParse(simpleBudget.group(1)!);
      maxBudget = _convertBudget(value, simpleBudget.group(2)!);
    }

    String? location;
    final sector = RegExp(r'sector\s*(\d+)').firstMatch(lower);
    if (sector != null) {
      location = 'Sector ${sector.group(1)}';
    } else if (lower.contains('dlf phase 1')) {
      location = 'DLF Phase 1';
    } else if (lower.contains('golf course road')) {
      location = 'Golf Course Road';
    } else if (lower.contains('sohna road')) {
      location = 'Sohna Road';
    } else if (lower.contains('gurgaon') || lower.contains('gurugram')) {
      location = 'Gurgaon';
    }

    String? landmark;
    const landmarkCandidates = [
      'dps',
      'gd goenka',
      'pathways',
      'shriram',
      'medanta',
      'artemis',
      'fortis',
      'cyber city',
    ];
    for (final item in landmarkCandidates) {
      if (lower.contains(item)) {
        landmark = _titleCase(item);
        break;
      }
    }

    String? propertyType;
    if (lower.contains('villa')) {
      propertyType = 'villa';
    } else if (lower.contains('plot')) {
      propertyType = 'plot';
    } else if (lower.contains('house') || lower.contains('independent')) {
      propertyType = 'house';
    } else if (lower.contains('flat') || lower.contains('apartment')) {
      propertyType = 'apartment';
    }

    String? facing;
    const facings = [
      'north-east',
      'north west',
      'north-west',
      'south east',
      'south-east',
      'south west',
      'south-west',
      'north',
      'south',
      'east',
      'west',
    ];
    for (final item in facings) {
      if (lower.contains(item)) {
        facing = item.replaceAll(' ', '-');
        break;
      }
    }

    final amenities = <String>[];
    const amenityCandidates = {
      'gym': ['gym', 'fitness'],
      'swimming pool': ['swimming pool', 'pool'],
      'parking': ['parking'],
      'lift': ['lift', 'elevator'],
      'security': ['security', 'gated'],
      'power backup': ['power backup', 'backup'],
      'clubhouse': ['clubhouse', 'club house'],
      'garden': ['garden', 'park'],
      'metro': ['metro'],
      'sunlight': ['sunlight', 'sunny'],
    };
    for (final entry in amenityCandidates.entries) {
      if (entry.value.any(lower.contains)) {
        amenities.add(entry.key);
      }
    }

    bool? furnished;
    if (lower.contains('unfurnished') || lower.contains('bare shell')) {
      furnished = false;
    } else if (lower.contains('furnished') ||
        lower.contains('fully furnished')) {
      furnished = true;
    }

    return ParsedQuery(
      bhk: bhk,
      maxBudget: maxBudget,
      location: location,
      landmark: landmark,
      propertyType: propertyType,
      facing: facing,
      amenities: amenities,
      furnished: furnished,
    );
  }

  static double? _convertBudget(double? value, String unit) {
    if (value == null) return null;
    if (unit == 'lakh' || unit == 'lac') return value * 100000;
    if (unit == 'cr' || unit == 'crore') return value * 10000000;
    return null;
  }

  static String _titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
