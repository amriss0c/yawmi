import 'dart:math';

class GeminiService {
  static Future<String> getDailyQuote() async {
    // Placeholder - replace with real Gemini call later if you add API key
    final quotes = [
      'استمر في العمل يا بطل!',
      'اليوم يوم إنجاز جديد',
      'كل خطوة تقربك من هدفك',
      'أنت قادر على أكثر مما تظن',
      'الإصرار يصنع المعجزات',
    ];
    return quotes[Random().nextInt(quotes.length)];
  }
}
