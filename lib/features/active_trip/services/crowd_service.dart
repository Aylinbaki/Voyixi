// lib/features/active_trip/services/crowd_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

enum CrowdLevel { quiet, moderate, busy, veryBusy, closed }

extension CrowdLevelExt on CrowdLevel {
 // 1. ÇEVİRİ: Kalabalık durum etiketleri İngilizce yapıldı
  String get label => switch (this) {
    CrowdLevel.quiet => 'Calm',
    CrowdLevel.moderate => 'Moderate',
    CrowdLevel.busy => 'Busy',
    CrowdLevel.veryBusy => 'Very Busy',
    CrowdLevel.closed => 'Closed',
  };

  Color get color => switch (this) {
    CrowdLevel.quiet => const Color(0xFF4CAF50),
    CrowdLevel.moderate => const Color(0xFFF9A825),
    CrowdLevel.busy => const Color(0xFFEF6C00),
    CrowdLevel.veryBusy => const Color(0xFFE53935),
    CrowdLevel.closed => const Color(0xFF78909C),
  };

  Color get bgColor => switch (this) {
    CrowdLevel.quiet => const Color(0xFFE8F5E9),
    CrowdLevel.moderate => const Color(0xFFFFF8E1),
    CrowdLevel.busy => const Color(0xFFFFF3E0),
    CrowdLevel.veryBusy => const Color(0xFFFFEBEE),
    CrowdLevel.closed => const Color(0xFFECEFF1),
  };

  IconData get icon => switch (this) {
    CrowdLevel.quiet => Icons.sentiment_very_satisfied_rounded,
    CrowdLevel.moderate => Icons.sentiment_satisfied_rounded,
    CrowdLevel.busy => Icons.sentiment_dissatisfied_rounded,
    CrowdLevel.veryBusy => Icons.sentiment_very_dissatisfied_rounded,
    CrowdLevel.closed => Icons.lock_outline_rounded,
  };
}

class CrowdService {
  static final CrowdService _i = CrowdService._();
  factory CrowdService() => _i;
  CrowdService._();

  String get _key => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  final Map<String, (CrowdLevel, DateTime, String?)> _cache = {};

  // Belirli bir mekanın kalabalık seviyesini tek seferlik çeker. Sadece mekan değiştiğinde tetiklenip 1 kere update eder.
  Future<(CrowdLevel, String?)> getCrowdLevel({
    required String placeName,
    required String city,
    String? placeId,
    String? fallbackLevel,
  }) async {
    final cacheKey = placeId ?? '${city}_$placeName'.toLowerCase().replaceAll(' ', '_');

    // 1. KONTROL: Bellekte bu mekan zaten var mı? Sayfa her setState olduğunda API'ye gitmeyi engeller.
    if (_cache.containsKey(cacheKey)) {
      final cachedData = _cache[cacheKey]!;
      return (cachedData.$1, cachedData.$3);
    }

    // 2. KONTROL: Eğer placeId yoksa bütçeyi korumak için Google'a gitme, yerel tahmini çalıştır.
    if (placeId == null || placeId.isEmpty) {
      debugPrint(' CrowdService: placeId eksik, yerel motor çalışıyor: $placeName');
      final localEstimate = _estimateLocalHeuristic(fallbackLevel);
      _cache[cacheKey] = (localEstimate, DateTime.now(), null);
      return (localEstimate, null);
    }
    // 3. KONTROL: Olay tetiklendiyse Google Places API'den tam 1 kere güncel durumu çek
    try {
      final result = await _fetchCrowdLevelFromGoogle(
        placeId: placeId,
        fallbackLevel: fallbackLevel,
      );

      
      // Çekilen veriyi belleğe sabitle
      _cache[cacheKey] = (result.$1, DateTime.now(), result.$2);
      return result;
    } catch (e) {
      debugPrint('❌ CrowdService API hatası: $e');
      return (_parseFallback(fallbackLevel), null);
    }
  }

  Future<(CrowdLevel, String?)> _fetchCrowdLevelFromGoogle({
    required String placeId,
    String? fallbackLevel,
  }) async {
    final res = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'

        '?place_id=$placeId'
        '&fields=current_opening_hours,business_status'
        '&key=$_key',
      ),
    ).timeout(const Duration(seconds: 5));

    if (res.statusCode != 200) return (_parseFallback(fallbackLevel), null);

    final data = jsonDecode(res.body);
    if (data['status'] != 'OK') return (_parseFallback(fallbackLevel), null);

    final result = data['result'] as Map<String, dynamic>?;
    if (result == null) return (_parseFallback(fallbackLevel), null);

    // İşletmenin  kapalılık kontrolü
    final businessStatus = result['business_status'] as String?;

    if (businessStatus == 'CLOSED_TEMPORARILY' ||
        businessStatus == 'CLOSED_PERMANENTLY') {
      return (CrowdLevel.closed, 'Temporarily Closed');

    }

    // Çalışma saatleri ve canlı açıklık kontrolü
    final openingHours = result['current_opening_hours'] as Map<String, dynamic>?;
    if (openingHours != null) {
      final bool isOpenNow = openingHours['open_now'] ?? true;

      if (!isOpenNow) {
        // 'Kapalı' -> 'Closed'
        String nextOpenTime = 'Closed';
        try {
          final now = DateTime.now();
          // Google Haritalar haftayı Pazar gününden başlatır 
          final currentWeekday = now.weekday == 7 ? 0 : now.weekday;
          final periods = openingHours['periods'] as List?;

          if (periods != null) {
            for (var period in periods) {
              final open = period['open'] as Map<String, dynamic>?;
              if (open != null && open['day'] == currentWeekday) {
                final timeStr = open['time'] as String?;
                if (timeStr != null && timeStr.length == 4) {
                  nextOpenTime = 'Opens at ${timeStr.substring(0, 2)}:${timeStr.substring(2)}';
                  break;
                }
              }
            }
          }
        } catch (_) {}
        return (CrowdLevel.closed, nextOpenTime);
      }
    }

    // Mekan açıksa yerel saat heuristiği kullan
    return (_estimateLocalHeuristic(fallbackLevel), null);
  }

  /// Gemini fallback + günün saati ile kalabalık tahmini .
  CrowdLevel _estimateLocalHeuristic(String? fallbackLevel) {
    final now = DateTime.now();
    final hour = now.hour;
    final isWeekend = now.weekday >= 6;
    final base = _parseFallback(fallbackLevel);
    int index = base.index;
    if (hour >= 12 && hour <= 16) {
      index += 1;
    } else if (hour < 9 || hour > 21) {
      index -= 2;
    }
    if (isWeekend) index += 1;
    return CrowdLevel.values[index.clamp(0, 3)];
  }

  CrowdLevel _parseFallback(String? level) => switch (level) {
    'Calm' => CrowdLevel.quiet,
    'Busy' => CrowdLevel.busy,
    'Very Busy' => CrowdLevel.veryBusy,
    _ => CrowdLevel.moderate,
  };

  /// Mekan değişim anlarında hafızayı sıfırlayıp yeni istek atılmasını tetikler.
  void clearCache() {
    _cache.clear();
    debugPrint(' CrowdService önbelleği olay tetiklenmesiyle sıfırlandı.');
  }
}