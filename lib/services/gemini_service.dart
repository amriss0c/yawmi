import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'ADD_YOUR_KEY_HERE'; 
  
  static Future<String> getDailyQuote() async {
    if (_apiKey == 'ADD_YOUR_KEY_HERE' || _apiKey.isEmpty) {
      return "النجاح هو مجموع محاولات صغيرة تتكرر كل يوم.";
    }
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final prompt = "Give me one short, inspiring daily quote in Arabic. Just the quote.";
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "كن أنت التغيير الذي تريده";
    } catch (e) {
      return "البدايات الصعبة تصنع نهايات عظيمة";
    }
  }
}
