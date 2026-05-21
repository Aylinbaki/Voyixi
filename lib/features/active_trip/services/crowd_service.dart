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

  // Olay güdümlü bellek (Sadece mekan değişene kadar veriyi kilitler)
  final Map<String, (CrowdLevel, DateTime, String?)> _cache = {};

  /// Belirli bir mekanın kalabalık seviyesini tek seferlik çeker.
  /// Zaman kontrolü kaldırılmıştır. Sadece mekan değiştiğinde tetiklenip 1 kere update eder.
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

    // 2. KONTROL: Eğer placeId yoksa bütçeyi korumak için Google'a gitme, yerel heuristiği çalıştır.
    if (placeId == null || placeId.isEmpty) {
      debugPrint('⚠️ CrowdService: placeId eksik, yerel motor çalışıyor: $placeName');
      final localEstimate = _estimateLocalHeuristic(fallbackLevel);
      return (localEstimate, null);
    }

    // 3. KONTROL: Olay tetiklendiyse Google Places API'den tam 1 kere güncel durumu çek
    try {
      final result = await _fetchCrowdLevelFromGoogle(
        placeId: placeId,
        fallbackLevel: fallbackLevel,
      );
<<<<<<< Updated upstream

      // Çekilen veriyi zaman damgasıyla belleğe yaz
      _cache[key] = (result.$1, DateTime.now(), result.$2);
=======
      
      // Çekilen veriyi zamandan bağımsız olarak belleğe sabitle
      _cache[cacheKey] = (result.$1, DateTime.now(), result.$2);
>>>>>>> Stashed changes
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
    // Sadece açılış saatlerini ve iş durumunu isteyerek ağ maliyetini minimuma indirdik (FinOps)
    final res = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
<<<<<<< Updated upstream
            '?place_id=$id'
            '&fields=current_opening_hours,user_ratings_total,rating,business_status'
            '&key=$_key',
=======
        '?place_id=$placeId'
        '&fields=current_opening_hours,business_status'
        '&key=$_key',
>>>>>>> Stashed changes
      ),
    ).timeout(const Duration(seconds: 5));

    if (res.statusCode != 200) return (_parseFallback(fallbackLevel), null);

    final data = jsonDecode(res.body);
    if (data['status'] != 'OK') return (_parseFallback(fallbackLevel), null);

    final result = data['result'] as Map<String, dynamic>?;
    if (result == null) return (_parseFallback(fallbackLevel), null);

    // İşletmenin kalıcı/geçici kapalılık kontrolü
    final businessStatus = result['business_status'] as String?;
<<<<<<< Updated upstream
    if (businessStatus == 'CLOSED_TEMPORARILY' ||
        businessStatus == 'CLOSED_PERMANENTLY') {
      // 2. ÇEVİRİ: Geçici kapalı durumu İngilizce yapıldı
      return (CrowdLevel.closed, 'Temporarily Closed');
=======
    if (businessStatus == 'CLOSED_TEMPORARILY' || businessStatus == 'CLOSED_PERMANENTLY') {
      return (CrowdLevel.closed, 'Geçici Kapalı');
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
          // Google Haritalar haftayı Pazar gününden başlatır (0 = Pazar, 1 = Pazartesi...)
          final currentWeekday = now.weekday == 7 ? 0 : now.weekday;
=======
          final currentWeekday = now.weekday == 7 ? 0 : now.weekday; 
>>>>>>> Stashed changes
          final periods = openingHours['periods'] as List?;

          if (periods != null) {
            for (var period in periods) {
              final open = period['open'] as Map<String, dynamic>?;
              if (open != null && open['day'] == currentWeekday) {
                final timeStr = open['time'] as String?;
                if (timeStr != null && timeStr.length == 4) {
                  // 3. ÇEVİRİ: Gelecek açılış saati metin şablonu İngilizce yapıldı
                  nextOpenTime = 'Opens at ${timeStr.substring(0, 2)}:${timeStr.substring(2)}';
                  break;
                }
              }
            }
          }
<<<<<<< Updated upstream
        } catch (_) {
          nextOpenTime = 'Closed';
        }
=======
        } catch (_) {}
>>>>>>> Stashed changes
        return (CrowdLevel.closed, nextOpenTime);
      }
    }

<<<<<<< Updated upstream
    // Mekan şu an açıksa yorum sayısına ve saate bağlı heuristik tahmin motorunu çalıştır
    final estimatedLevel = _estimateFromTimeAndRating(
      result['user_ratings_total'] as int? ?? 0,
      (result['rating'] as num?)?.toDouble() ?? 3.0,
      openingHours,
    );

    return (estimatedLevel, null);
  }

  Future<String?> _findPlaceId(String name, String city) async {
    final res = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
            '?query=${Uri.encodeComponent('$name $city')}'
            '&key=$_key',
      ),
    ).timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return null;
    return results[0]['place_id'] as String?;
  }

  CrowdLevel _estimateFromTimeAndRating(
      int totalRatings,
      double rating,
      dynamic currentHours,
      ) {
=======
    // Mekan şu an açıksa, canlı kalabalık tahmini için akıllı yerel motoru çalıştır
    return (_estimateLocalHeuristic(fallbackLevel), null);
  }

  CrowdLevel _estimateLocalHeuristic(String? fallbackLevel) {
>>>>>>> Stashed changes
    final now = DateTime.now();
    final hour = now.hour;
    final isWeekend = now.weekday >= 6;

    final base = _parseFallback(fallbackLevel);
    int index = base.index;

    // Saatlik ve dönemsel yoğunluk kaydırma parametreleri
    if (hour >= 12 && hour <= 16) {
      index += 1; // Öğle saatleri yoğunluk artışı
    } else if (hour < 9 || hour > 21) {
      index -= 2; // Gece veya sabah erken sakinliği
    }

    if (isWeekend) index += 1; // Hafta sonu çarpanı

    return CrowdLevel.values[index.clamp(0, 3)];
  }

  // 4. ÇEVİRİ: Fallback metin ayrıştırıcısı yeni İngilizce veri standartlarına göre güncellendi
  CrowdLevel _parseFallback(String? level) => switch (level) {
    'Calm' => CrowdLevel.quiet,
    'Busy' => CrowdLevel.busy,
    'Very Busy' => CrowdLevel.veryBusy,
    _ => CrowdLevel.moderate,
  };

  /// Mekan değişim anlarında hafızayı sıfırlayıp yeni istek atılmasını tetikler.
  void clearCache() {
    _cache.clear();
    debugPrint('🗑️ CrowdService önbelleği olay tetiklenmesiyle sıfırlandı.');
  }
}