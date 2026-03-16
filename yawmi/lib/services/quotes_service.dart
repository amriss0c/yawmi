import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QuotesService {
  static final QuotesService instance = QuotesService._();
  QuotesService._();

  static const _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static const Map<String, String> categoryTags = {
    'الانضباط والعادات': 'discipline and habits',
    'الإرادة والمثابرة': 'willpower and perseverance',
    'الحكمة والتفكير': 'wisdom and philosophy',
    'الإنجاز والنجاح': 'achievement and success',
    'الصبر والسكينة': 'patience and inner peace',
    'النمو الشخصي': 'personal growth and self-improvement',
    'علم النفس': 'psychology and human behavior',
  };

  static const List<String> defaultCategories = [
    'الانضباط والعادات',
    'الإرادة والمثابرة',
    'الحكمة والتفكير',
    'الإنجاز والنجاح',
    'الصبر والسكينة',
    'النمو الشخصي',
    'علم النفس',
  ];

  String _apiKey = '';
  List<String> _enabledCategories = List.from(defaultCategories);
  String _quoteArabic = '';
  String _quoteAuthor = '';
  bool _isLoading = false;

  String get quoteArabic => _quoteArabic;
  String get quoteAuthor => _quoteAuthor;
  bool get isLoading => _isLoading;
  bool get isConfigured => _apiKey.isNotEmpty;
  List<String> get enabledCategories => _enabledCategories;

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('gemini_api_key') ?? '';
    final saved = prefs.getStringList('quote_categories');
    _enabledCategories = saved ?? List.from(defaultCategories);
    _quoteArabic = prefs.getString('cached_quote_ar') ?? '';
    _quoteAuthor = prefs.getString('cached_quote_author') ?? '';
  }

  Future<void> saveApiKey(String key) async {
    _apiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKey);
  }

  Future<void> saveCategories(List<String> cats) async {
    _enabledCategories = cats;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('quote_categories', cats);
  }

  String _pickCategory() {
    if (_enabledCategories.isEmpty) return 'الحكمة والتفكير';
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return _enabledCategories[dayOfYear % _enabledCategories.length];
  }

  Future<void> fetchQuote(Function() onUpdate) async {
    // TEMP: hardcoded for testing — remove after confirming flow works
    if (_apiKey.isEmpty) _apiKey = 'AIzaSyDlRudZIVhQzBp1GdWvpU3yGoc5JhpnES8';
    debugPrint('fetchQuote called. Key empty: \${_apiKey.isEmpty}. Key length: \${_apiKey.length}');
    if (_apiKey.isEmpty) {
      debugPrint('fetchQuote: no API key — skipping');
      _isLoading = false;
      onUpdate();
      return;
    }
    _isLoading = true;
    onUpdate();

    try {
      final category = _pickCategory();
      final categoryEn = categoryTags[category] ?? 'wisdom';

      // Check daily cache — one new quote per day per category
      final today = DateTime.now();
      final cacheKey = 'quote_${today.year}_${today.month}_${today.day}_$category';
      final prefs = await SharedPreferences.getInstance();
      final cachedAr = prefs.getString('${cacheKey}_ar');
      final cachedAuthor = prefs.getString('${cacheKey}_author');

      if (cachedAr != null && cachedAuthor != null) {
        _quoteArabic = cachedAr;
        _quoteAuthor = cachedAuthor;
        _isLoading = false;
        onUpdate();
        return;
      }

      // Build prompt — ask Gemini for quote directly in Arabic
      final prompt = '''أعطني اقتباساً واحداً قوياً ومؤثراً باللغة العربية الفصحى من شخصية عالمية مشهورة ومحترمة في مجال: $categoryEn

الشروط:
- الاقتباس باللغة العربية الفصحى فقط
- من شخصية حقيقية مشهورة عالمياً (رياضيين، فلاسفة، قادة، علماء، أدباء)
- لا تكرر نفس الاقتباسات الشائعة جداً
- متنوع في المصادر (ليس دائماً أرسطو أو كونفوشيوس)

أعد فقط سطرين:
السطر الأول: نص الاقتباس بالعربية
السطر الثاني: اسم صاحب الاقتباس بالعربية والإنجليزية''';

      final response = await http.post(
        Uri.parse('$_geminiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.9,
            'maxOutputTokens': 200,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('Gemini response: \${response.statusCode}');
      debugPrint('Gemini body: \${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
                ?.toString()
                .trim() ??
            '';

        if (text.isNotEmpty) {
          final lines = text
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList();

          if (lines.length >= 2) {
            _quoteArabic = lines[0];
            _quoteAuthor = lines[1];
          } else if (lines.length == 1) {
            _quoteArabic = lines[0];
            _quoteAuthor = '';
          }

          // Cache today's quote
          await prefs.setString('${cacheKey}_ar', _quoteArabic);
          await prefs.setString('${cacheKey}_author', _quoteAuthor);
          await prefs.setString('cached_quote_ar', _quoteArabic);
          await prefs.setString('cached_quote_author', _quoteAuthor);

          debugPrint('Quote fetched: $_quoteArabic — $_quoteAuthor');
        }
      } else {
        debugPrint('Gemini API error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('fetchQuote error: $e');
    }

    _isLoading = false;
    onUpdate();
  }
}
