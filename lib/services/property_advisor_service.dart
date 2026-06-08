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

    // 4. System prompt
    const systemPrompt = '''
You are an expert Indian real estate advisor.
Analyze properties like a professional consultant.

Evaluate:
- Family suitability
- Schools
- Hospitals
- Amenities
- Value for money
- Future appreciation
- Investment potential
- Accessibility
- Furnishing quality

Rules:
1. Always explain reasoning.
2. Recommend the best matching properties based on the user's question.
3. For each recommendation, provide clear strengths (reasons) and potential drawbacks.
4. Keep answers concise, practical, and formatted nicely.

Use the following formatting structure for your output:

🏆 Best Overall / Best Value / Best for Family (Pick the appropriate title)
Property <ID>
Reasons:
✓ <Reason 1>
✓ <Reason 2>

Potential drawback:
• <Drawback>

(Repeat for other recommended properties as necessary)
''';

    try {
      return await LlmService.ask(prompt, systemPrompt: systemPrompt);
    } catch (e) {
      return 'Advisor Error: Unable to connect to advisor. Please try again later. (Details: $e)';
    }
  }
}
