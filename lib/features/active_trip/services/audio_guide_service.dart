// lib/features/active_trip/services/audio_guide_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioGuideService {
  static final AudioGuideService _instance = AudioGuideService._();
  factory AudioGuideService() => _instance;
  AudioGuideService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  String get _geminiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  String get _googleApiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  // ── Ana Metod ────────────────────────────────────────────────────────────
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

// Cachekey   --------------------------------------------------------------------------
      final cacheKey = _cacheKey(city, placeName);
      final cachedFile = await _getCachedFile(cacheKey);

      File audioFile;

      if (cachedFile != null) {
        debugPrint('💾 Playing from cache: $placeName');
        audioFile = cachedFile;
      } else {
        debugPrint('🔊 Generating new audio via Google Cloud TTS: $placeName');

// 1. Gemini'den metnini al  --------------------------------------------------------------------------
        final text = await _generateText(
          placeName: placeName,
          city: city,
          description: description,
        );

// 2.TTS ile metni  sese dönüştür--------------------------------------------------------------------------
        final audioBytes = await _textToSpeech(text);

// 3. Gelen byte verisini .mp3 dosyası olarak diske kaydet -------------------------------------------------
        audioFile = await _saveToCache(cacheKey, audioBytes);
      }

// 4. Diskteki dosyayı oynat --------------------------------------------------------------------------
      await _player.setFilePath(audioFile.path);
      await _player.play();

// Bitince durumu güncelle --------------------------------------------------------------------------
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

  // ── Cache Yönetimi ─────────────────────────────────────────────
  String _cacheKey(String city, String placeName) {
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

  // ── Gemini — Metin Üretim Katmanı ─────────────────────────────────────────
  Future<String> _generateText({
    required String placeName,
    required String city,
    required String description,
  }) async {
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

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
    final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
    debugPrint(' Gemini Text: $text');
    return text.length > 300 ? '${text.substring(0, 297)}...' : text;
  }

// ── Google Cloud TTS Katmanı ──────────────────────────────────────────────
  Future<List<int>> _textToSpeech(String text) async {
    if (_googleApiKey.isEmpty) {
      throw Exception('Google API Key is missing from .env');
    }

    const url = 'https://texttospeech.googleapis.com/v1/text:synthesize';

    final response = await http.post(
      Uri.parse('$url?key=$_googleApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'input': {'text': text},
        'voice': {
          'languageCode': 'en-US',
          'name': 'en-US-Neural2-H', 
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'speakingRate': 0.95,
          'pitch': 0.0
        }
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Google TTS API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final String audioContent = data['audioContent'];
    return base64Decode(audioContent);
  }
}