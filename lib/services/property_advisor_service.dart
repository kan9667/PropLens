import 'dart:convert';
import '../data/types.dart';
import 'llm_service.dart';

class PropertyAdvisorService {
  /// Converts the top 5 matching properties to a compact JSON and requests
  /// recommendations from OpenRouter based on the user's conversational query.
  static Future<String> askAdvisor({
    required String question,
    required List<Property> properties,
  }) async {
    if (properties.isEmpty) {
      return 'Please search for properties first before asking the Advisor.';
    }

    // 1. Take the top 5 matched properties
    final topProperties = properties.take(5).toList();

    // 2. Convert them into a compact JSON structure
    final compactList = topProperties.map((p) => {
      'id': p.id,
      'bhk': p.bhk,
      'areaSqFt': p.area,
      'priceRupees': p.price,
      'location': p.location,
      'furnishingStatus': p.furnishing,
      'amenities': p.amenities,
      'nearbySchools': p.nearbySchools,
      'nearbyHospitals': p.nearbyHospitals,
      'ageYears': p.ageYears,
      'floor': p.floor,
      'totalFloors': p.totalFloors,
      'parking': p.parking,
      'matchScore': p.matchScore != null ? '${(p.matchScore! * 100).toStringAsFixed(0)}%' : null,
    }).toList();

    final propertiesJson = const JsonEncoder.withIndent('  ').convert(compactList);

    // 3. Build user prompt
    final prompt = '''
User Question: "$question"

Available Property Search Results (Top 5 Matches):
$propertiesJson

Recommend the best properties based on the user's question, explaining your reasoning clearly. Reference specific properties by their ID, BHK, price in Lakhs, and location. Highlight strengths and weaknesses, and list drawbacks if any.
''';

    const systemPrompt = '''
You are an expert Indian real estate advisor. Answer in plain English only.

Rules:
1. Keep the full answer under 100 words.
2. No markdown, asterisks, hashtags, bullet symbols, or emojis.
3. Use short sentences and line breaks between ideas.
4. Name properties by BHK, price in Lakhs, and location (not raw IDs).
5. State one best pick, one alternative if relevant, and one honest drawback.
6. Be direct and practical for a home buyer in India.
''';

    try {
      final raw = await LlmService.ask(prompt, systemPrompt: systemPrompt);
      return formatAdvisorAnswer(raw);
    } catch (e) {
      return 'Unable to reach the advisor right now. Please try again in a moment.';
    }
  }

  /// Strips markdown/symbol noise so answers read cleanly in the UI.
  static String formatAdvisorAnswer(String raw) {
    var text = raw.trim();

    text = text.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    text = text.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    text = text.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
    text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*[-*•✓▪►]\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+[.)]\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'[🏆🥈✅❌💰📈👨‍👩‍👧📅🏫🏥🤖]'), '');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.replaceAll(RegExp(r' {2,}'), ' ');

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return lines.join('\n\n');
  }
}
