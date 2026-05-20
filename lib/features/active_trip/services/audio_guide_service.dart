// lib/features/active_trip/services/audio_guide_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioGuideService {
  // Singleton
  static final AudioGuideService _instance = AudioGuideService._();
  factory AudioGuideService() => _instance;
  AudioGuideService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  String get _geminiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  String get _azureKey => dotenv.env['AZURE_TTS_KEY'] ?? '';
  String get _azureRegion => dotenv.env['AZURE_TTS_REGION'] ?? 'eastus';

  // ── Ana metod ─────────────────────────────────────────────────────────────
  Future<void> playGuide({
    required String placeName,
    required String city,
    required String description,
    VoidCallback? onStart,
    VoidCallback? onFinish,
    VoidCallback? onError,
  }) async {
    try {
      if (_isPlaying) {
        await stop();
        return;
      }

      onStart?.call();
      _isPlaying = true;

      // Cache key — şehir + mekan adından oluştur
      final cacheKey = _cacheKey(city, placeName);
      final cachedFile = await _getCachedFile(cacheKey);

      File audioFile;

      if (cachedFile != null) {
        // Cache'de var — direkt kullan, API çağrısı yok
        debugPrint(' Playing from cache: $placeName');
        audioFile = cachedFile;
      } else {
        // Cache'de yok — üret ve kaydet
        debugPrint('🔊 Generating new audio: $placeName');

        // 1. Gemini'den metin al
        final text = await _generateText(
          placeName: placeName,
          city: city,
          description: description,
        );

        // 2. Azure TTS ile sese çevir
        final audioBytes = await _textToSpeech(text);

        // 3. Dosyaya kaydet
        audioFile = await _saveToCache(cacheKey, audioBytes);
      }

      // 4. Oynat
      await _player.setFilePath(audioFile.path);
      await _player.play();

      // Bitince state güncelle
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          onFinish?.call();
        }
      });
    } catch (e) {
      _isPlaying = false;
      debugPrint('❌ AudioGuide error: $e');
      onError?.call();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  void dispose() {
    _player.dispose();
  }

  // ── Cache yönetimi ────────────────────────────────────────────────────────
  String _cacheKey(String city, String placeName) {
    // Güvenli dosya adı — boşluk ve özel karakter yok
    final safe = '${city}_$placeName'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return 'audio_guide_$safe';
  }

  Future<File?> _getCachedFile(String key) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$key.mp3');
      if (await file.exists()) return file;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<File> _saveToCache(String key, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$key.mp3');
    await file.writeAsBytes(bytes);
    return file;
  }

  // Tüm cache'i temizle
  Future<void> clearCache() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('audio_guide_'));
      for (final f in files) {
        await f.delete();
      }
      debugPrint('🗑️ Audio guide cache cleared');
    } catch (_) {}
  }

  // ── Gemini — metin üret ───────────────────────────────────────────────────
  Future<String> _generateText({
    required String placeName,
    required String city,
    required String description,
  }) async {

    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

    // 1. ÇEVİRİ: Sesli rehber prompt kuralları tamamen İngilizceye çekildi
    final prompt =
        'You are a professional audio tour guide. '
        'Write a short, fluent, and engaging audio narration for tourists about "$placeName" in $city.\n\n'
        'Additional context: $description\n\n'
        'RULES:\n'
        '- Strictly do not exceed 300 characters.\n'
        '- Use a natural, spoken conversational tone; do not make lists.\n'
        '- Write in English.\n'
        '- Provide advice or tips on touring this specific place.\n'
        '- Include 1 or 2 interesting historical or cultural facts.\n'
        '- Do not start with any introduction like "Hello", "Welcome", or greeting phrases; dive directly into the facts.';


    final res = await http.post(
      Uri.parse('$url?key=$_geminiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [{'text': prompt}]
          }
        ],
        'generationConfig': {
          'temperature': 0.5,
          'maxOutputTokens': 900,
        },
      }),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw Exception('Gemini error: ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    final finishReason = data['candidates'][0]['finishReason'];
    debugPrint(' Gemini Stop Reason: $finishReason');
    if (finishReason == 'SAFETY') {
      debugPrint(' Flagged by safety filter');
    } else if (finishReason == 'MAX_TOKENS') {
      debugPrint(' Exceeded max tokens');
    }

    final text =
    data['candidates'][0]['content']['parts'][0]['text'] as String;
    debugPrint('🤖 Gemini Text: $text');
    return text.length > 300 ? '${text.substring(0, 297)}...' : text;
  }

  // ── Azure TTS — metni sese çevir ──────────────────────────────────────────
  Future<List<int>> _textToSpeech(String text) async {
    // Token al
    final tokenRes = await http.post(
      Uri.parse(
          'https://$_azureRegion.api.cognitive.microsoft.com/sts/v1.0/issueToken'),
      headers: {'Ocp-Apim-Subscription-Key': _azureKey},
    ).timeout(const Duration(seconds: 10));

    if (tokenRes.statusCode != 200) {
      throw Exception('Azure token error: ${tokenRes.statusCode}');
    }

    final token = tokenRes.body;

    // 2. ÇEVİRİ & GÜNCELLEME: TTS ses dili ve yapısı Amerikan İngilizcesine (en-US-AvaNeural) geçirildi
    final ssml = '''
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
  <voice name="en-US-AvaNeural">
    <prosody rate="-5%" pitch="0%">
      ${_escapeXml(text)}
    </prosody>
  </voice>
</speak>''';

    final ttsRes = await http.post(
      Uri.parse(
          'https://$_azureRegion.tts.speech.microsoft.com/cognitiveservices/v1'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': 'audio-16khz-128kbitrate-mono-mp3',
        'User-Agent': 'VoyixiApp',
      },
      body: ssml,
    ).timeout(const Duration(seconds: 30));

    if (ttsRes.statusCode != 200) {
      throw Exception('Azure TTS error: ${ttsRes.statusCode}');
    }

    return ttsRes.bodyBytes;
  }

  String _escapeXml(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}