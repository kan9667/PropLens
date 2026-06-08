//responsible for ai

import 'dart:convert'; //provides json encode and decode

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
}