import 'package:firebase_ai/firebase_ai.dart';

class GeminiFinanceAssistantService {
  GeminiFinanceAssistantService();

  final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
    systemInstruction: Content.system(
      '''
You are the WSFM AI Finance Assistant.

WSFM is a finance management app for Wi-Fi stations and centers.

Your job:
- Help admins and managers understand sales, expenses, cards sold, revenue, and profit.
- Answer using the provided WSFM finance context only.
- Do not invent numbers.
- If the context says a period has 0 records, explain that there is no data for that period.
- If the user asks for profit, use: profit = total sales - total expenses.
- Keep answers short and clear.
- Use simple business language.
''',
    ),
  );

  Future<String> ask({
    required String message,
    required String financeContext,
    required List<Map<String, String>> history,
  }) async {
    final cleanedHistory = history
        .where((item) {
          final text = item['text']?.trim() ?? '';
          return text.isNotEmpty &&
              !text.startsWith('Hi, I am your WSFM AI assistant');
        })
        .take(10)
        .map((item) {
          final role = item['role'];
          final text = item['text'] ?? '';

          if (role == 'assistant') {
            return Content.model([TextPart(text)]);
          }

          return Content.text(text);
        })
        .toList();

    final chat = _model.startChat(
      history: cleanedHistory,
    );

    final response = await chat.sendMessage(
      Content.text(
        '''
$financeContext

User question:
$message
''',
      ),
    );

    final answer = response.text?.trim();

    if (answer == null || answer.isEmpty) {
      return 'I could not generate a response. Please try again.';
    }

    return answer;
  }
}