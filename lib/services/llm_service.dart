//responsible for ai

import 'dart:convert'; //provides json encode and decode

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../data/types.dart';

class LlmService {
  static Future<String> ask(
  String prompt, {
  String? systemPrompt,
}) async {
    final apiKey =
        dotenv.env['OPENROUTER_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Missing API Key');
    }

    final response = await http.post( //sends data to openrouter
      Uri.parse(
        'https://openrouter.ai/api/v1/chat/completions',
      ),

      headers: { //provides metadata
        'Authorization': 'Bearer $apiKey', //allowed to use open router
        'Content-Type': 'application/json', //tells open router the req body contains JSON
      },

      body: jsonEncode({ //dart object becomes json
        'model':
            'google/gemma-3-27b-it',

        'messages': [
  if (systemPrompt != null)
    {
      'role': 'system',
      'content': systemPrompt,
    },

  {
    'role': 'user',
    'content': prompt,
  },
],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'API Error: ${response.body}',
      );
    }

    final data =
        jsonDecode(response.body); //json response becomes dart object

    return data['choices'][0]
        ['message']['content'];
  }

  static Future<AiOverview> generateOverview({
    required List<Property> results,
    required String query,
  }) async {
    if (results.isEmpty) {
      return const AiOverview(
        bestMatch: BestMatch(
          title: 'No property matches',
          priceDisplay: 'N/A',
          matchScore: 0.0,
        ),
        quickInsights: ['Try a different query'],
        fullAnalysis: 'We couldn\'t find any properties matching your criteria. Try adjusting your budget, location, or amenities filters.',
        bestMatchReason: 'No match reason',
        fullRecommendation: {},
      );
    }

    final best = results.first;
    final bestTitle = '${best.bhk} BHK Flat in ${best.location.split(',')[0]}';
    final bestPrice = '₹${(best.price / 100000).toStringAsFixed(0)}L';
    final bestScore = best.matchScore ?? 1.0;

    final insights = best.matchReasons != null && best.matchReasons!.isNotEmpty
        ? best.matchReasons!.take(3).toList()
        : ['Matches BHK requirement', 'Located in Gurgaon'];

    String analysis = '';
    try {
      final propertiesSummary = results.take(3).map((p) => {
        'bhk': p.bhk,
        'price': '₹${(p.price / 100000).toStringAsFixed(0)}L',
        'location': p.location,
        'amenities': p.amenities.take(3).toList(),
      }).toList();

      final prompt = 'Provide a brief summary card overview of the best properties that match this search query: "$query". Here are the top properties to choose from: ${jsonEncode(propertiesSummary)}.';
      analysis = await ask(
        prompt,
        systemPrompt: 'You are an AI Overview assistant. Write a highly concise 2-sentence summary comparing these properties and showing why they match. Do not include markdown.',
      );
    } catch (e) {
      analysis = 'Found ${results.length} matching properties. $bestTitle represents the best match at $bestPrice with a match rating of ${(bestScore * 100).toStringAsFixed(0)}%.';
    }

    return AiOverview(
      bestMatch: BestMatch(
        title: bestTitle,
        priceDisplay: bestPrice,
        matchScore: bestScore,
      ),
      quickInsights: insights,
      fullAnalysis: analysis,
      bestMatchReason: insights.isNotEmpty ? insights.first : 'Matches search criteria',
      fullRecommendation: const {},
    );
  }

  static Future<Map<String, String>> generateFullRecommendation({
    required List<Property> results,
    required String query,
  }) async {
    if (results.isEmpty) return const {};

    final topThree = results.take(3).map((p) => {
      'id': p.id,
      'bhk': p.bhk,
      'price': '₹${(p.price / 100000).toStringAsFixed(0)}L',
      'location': p.location,
      'amenities': p.amenities,
      'nearbySchools': p.nearbySchools,
      'nearbyHospitals': p.nearbyHospitals,
      'furnishing': p.furnishing,
      'parking': p.parking,
      'ageYears': p.ageYears,
    }).toList();

    const systemPrompt = '''
You are an expert Indian real estate advisor. Analyze these properties and the user's query. Return a structured recommendation with these exact sections separated by headers:
BEST_MATCH | RUNNER_UP | PROS | CONS | INVESTMENT | RENTAL_YIELD | FAMILY | APPRECIATION | SCHOOLS | HOSPITALS
Be specific, use Indian market context, mention actual numbers.
Keep each section under 80 words.
''';

    final userPrompt = '''
User query: $query
Properties: ${jsonEncode(topThree)}
Provide the full analysis.
''';

    try {
      final response = await ask(userPrompt, systemPrompt: systemPrompt);
      return _parseFullRecommendation(response);
    } catch (e) {
      debugPrint('Error generating full recommendation: $e');
      return const {};
    }
  }

  static Map<String, String> _parseFullRecommendation(String raw) {
    final Map<String, String> parsed = {};
    final sections = [
      'BEST_MATCH',
      'RUNNER_UP',
      'PROS',
      'CONS',
      'INVESTMENT',
      'RENTAL_YIELD',
      'FAMILY',
      'APPRECIATION',
      'SCHOOLS',
      'HOSPITALS'
    ];

    for (int i = 0; i < sections.length; i++) {
      final currentSection = sections[i];
      final nextSection = i + 1 < sections.length ? sections[i + 1] : null;

      final regExpStart = RegExp(
        r'(?:^|\n|\r)\s*(?:\*{1,3}|#|\d\.)?\s*' + currentSection + r'\s*(?::|-|\||\n)?',
        caseSensitive: false,
      );
      final matchStart = regExpStart.firstMatch(raw);

      if (matchStart != null) {
        final startIndex = matchStart.end;
        int endIndex = raw.length;

        if (nextSection != null) {
          final regExpEnd = RegExp(
            r'(?:^|\n|\r)\s*(?:\*{1,3}|#|\d\.)?\s*' + nextSection + r'\s*(?::|-|\||\n)?',
            caseSensitive: false,
          );
          final matchEnd = regExpEnd.firstMatch(raw);
          if (matchEnd != null) {
            endIndex = matchEnd.start;
          }
        }

        var content = raw.substring(startIndex, endIndex).trim();
        if (content.endsWith('|')) {
          content = content.substring(0, content.length - 1).trim();
        }
        parsed[currentSection] = content;
      } else {
        parsed[currentSection] = '';
      }
    }
    return parsed;
  }
}