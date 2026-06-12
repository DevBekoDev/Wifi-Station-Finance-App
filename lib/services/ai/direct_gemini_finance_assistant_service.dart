import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DirectGeminiFinanceAssistantService {
  DirectGeminiFinanceAssistantService({
    required this.apiKey,
    this.model = const String.fromEnvironment(
      'GEMINI_MODEL',
      defaultValue: 'gemini-2.5-flash-lite',
    ),
  });

  final String apiKey;
  final String model;

  Future<String> ask({
    required String message,
    required String financeContext,
    required List<Map<String, String>> history,
    int maxOutputTokens = 500,
  }) async {
    if (apiKey.trim().isEmpty) {
      return 'Gemini API key is missing. Run the app using --dart-define=GEMINI_API_KEY=YOUR_KEY.';
    }

    final contents = <Map<String, dynamic>>[
      ..._buildHistory(history),
      {
        'role': 'user',
        'parts': [
          {
            'text': '''
You are the WSFM AI Finance Assistant.

Main rules:
- Use WSFM context as the only source for exact numbers, users, centers, sales, expenses, profit, managers, emails, and roles.
- Do not invent sales, expenses, profit, users, centers, emails, managers, or roles.
- If the context says access denied, clearly say the user does not have access to that data.
- Do not say a center does not exist when access is denied.
- Managers can only access their assigned center.
- Admins can access all centers.
- Do not use Markdown.
- Do not use **bold**.
- Use plain text only.
- Use simple bullets with "-" when helpful.

Advice rules:
- You may give general business advice when the user asks how to improve sales, reduce expenses, or understand low profit.
- When giving advice, base it on the available WSFM numbers.
- Clearly say it is a recommendation, not stored database data.
- Do not refuse advice questions just because the context does not directly contain advice.

Answer length rules:
- Short answers are okay for simple questions.
- Do not cut important financial data.
- Never end the answer with an unfinished sentence.
- If you cannot complete a long answer, give a shorter complete answer instead.
- If the user asks for each center, give one complete section for every center provided in the context.
- For each center, include manager, total sales, total expenses, profit, cards sold, sales records count, and expenses records count when available.
- Do not stop after the first center.
- Do not say "here is the data" without actually listing the data.

WSFM context:
$financeContext

User question:
$message
''',
          },
        ],
      },
    ];

    final response = await _postWithRetry(
      contents: contents,
      maxOutputTokens: maxOutputTokens,
    );

    if (response.statusCode == 429) {
      return 'The AI usage limit is busy right now. Please try again in a moment.';
    }

    if (response.statusCode == 503) {
      return 'The AI model is temporarily busy because of high demand. Please try again in a moment.';
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('Gemini API error ${response.statusCode}: ${response.body}');
      return 'Sorry, the AI service could not answer right now. Please try again.';
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      return 'I could not generate a response. Please try again.';
    }

    final firstCandidate = candidates.first as Map<String, dynamic>;
    final finishReason = firstCandidate['finishReason']?.toString();
    final usageMetadata = data['usageMetadata'];

    debugPrint('GEMINI MODEL: $model');
    debugPrint('GEMINI FINISH REASON: $finishReason');
    debugPrint('GEMINI USAGE: $usageMetadata');

    final content = firstCandidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;

    if (parts == null || parts.isEmpty) {
      if (finishReason == 'SAFETY') {
        return 'I cannot answer that request safely.';
      }

      return 'I could not generate a response. Please try again.';
    }

    final text = parts
        .map((part) {
          if (part is Map<String, dynamic>) {
            return part['text']?.toString() ?? '';
          }

          return '';
        })
        .where((value) => value.trim().isNotEmpty)
        .join('\n')
        .trim();

    if (text.isEmpty) {
      return 'I could not generate a response. Please try again.';
    }

    if (finishReason == 'MAX_TOKENS') {
      return '$text\n\nNote: The answer was shortened because it reached the output limit.';
    }

    return text;
  }

  Future<http.Response> _postWithRetry({
    required List<Map<String, dynamic>> contents,
    required int maxOutputTokens,
  }) async {
    http.Response? lastResponse;

    for (int attempt = 0; attempt < 3; attempt++) {
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
        ),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': maxOutputTokens,
          },
        }),
      );

      lastResponse = response;

      if (response.statusCode != 429 && response.statusCode != 503) {
        return response;
      }

      await Future.delayed(
        Duration(seconds: 2 + attempt),
      );
    }

    return lastResponse!;
  }

  List<Map<String, dynamic>> _buildHistory(
    List<Map<String, String>> history,
  ) {
    final filteredHistory = history.where((item) {
      final text = item['text']?.trim() ?? '';

      return text.isNotEmpty &&
          !text.startsWith('Hi, I am your WSFM AI assistant') &&
          !text.startsWith('AI error:') &&
          !text.startsWith('Sorry, I could not connect') &&
          !text.startsWith('Sorry, the AI service');
    }).toList();

    final lastMessages = filteredHistory.length > 4
        ? filteredHistory.sublist(filteredHistory.length - 4)
        : filteredHistory;

    return lastMessages.map((item) {
      final role = item['role'] == 'assistant' ? 'model' : 'user';

      return {
        'role': role,
        'parts': [
          {
            'text': item['text'] ?? '',
          },
        ],
      };
    }).toList();
  }
}