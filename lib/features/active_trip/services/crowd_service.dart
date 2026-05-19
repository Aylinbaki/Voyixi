// lib/features/active_trip/services/crowd_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

enum CrowdLevel { quiet, moderate, busy, veryBusy, closed }

extension CrowdLevelExt on CrowdLevel {
  String get label => switch (this) {
        CrowdLevel.quiet => 'Sakin',
        CrowdLevel.moderate => 'Orta',
        CrowdLevel.busy => 'Yoğun',
        CrowdLevel.veryBusy => 'Çok Yoğun',
        CrowdLevel.closed => 'Kapalı',
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

  // Cache: placeId/key → (CrowdLevel, FetchTime, SpecialStatusText)
  final Map<String, (CrowdLevel, DateTime, String?)> _cache = {};

  /// Belirli bir mekanın anlık kalabalık seviyesini veya kapalılık durumunu tek seferlik çeker.
  /// Son 5 dakika içinde istek atıldıysa, ağ tüketimini önlemek için önbellekteki taze veriyi döner.
  Future<(CrowdLevel, String?)> getCrowdLevel({
    required String placeName,
    required String city,
    String? placeId,
    String? fallbackLevel,
  }) async {
    final key = placeId ?? '${city}_$placeName';

    // 1. KONTROL: Cache taze mi?
    if (_cache.containsKey(key)) {
      final cachedData = _cache[key]!;
      final lastFetch = cachedData.$2;
      if (DateTime.now().difference(lastFetch) < const Duration(minutes: 5)) {
        return (cachedData.$1, cachedData.$3); // Önbellekten taze veriyi fırlat
      }
    }

    // 2. KONTROL: Cache yoksa veya eskiyse Google Places API'ye çık
    try {
      final result = await _fetchCrowdLevel(
        placeName: placeName,
        city: city,
        placeId: placeId,
        fallbackLevel: fallbackLevel,
      );
      
      // Çekilen veriyi zaman damgasıyla belleğe yaz
      _cache[key] = (result.$1, DateTime.now(), result.$2);
      return result;
    } catch (e) {
      // Herhangi bir ağ hatasında veya zaman aşımında Gemini fallback değerini döndür
      return (_parseFallback(fallbackLevel), null);
    }
  }

  Future<(CrowdLevel, String?)> _fetchCrowdLevel({
    required String placeName,
    required String city,
    String? placeId,
    String? fallbackLevel,
  }) async {
    // placeId yoksa önce text search endpoint'i ile ID buluyoruz
    final id = placeId ?? await _findPlaceId(placeName, city);
    if (id == null) return (_parseFallback(fallbackLevel), null);

    // Place Details endpoint'inden gerekli alanları kısıtlı seçerek çekiyoruz (Maliyet optimizasyonu)
    final res = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$id'
        '&fields=current_opening_hours,user_ratings_total,rating,business_status'
        '&key=$_key',
      ),
    ).timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) return (_parseFallback(fallbackLevel), null);

    final data = jsonDecode(res.body);
    if (data['status'] != 'OK') return (_parseFallback(fallbackLevel), null);

    final result = data['result'] as Map<String, dynamic>?;
    if (result == null) return (_parseFallback(fallbackLevel), null);

    // İşletme kalıcı veya geçici olarak kapalıysa direkt kapalı bilgisini dön
    final businessStatus = result['business_status'] as String?;
    if (businessStatus == 'CLOSED_TEMPORARILY' ||
        businessStatus == 'CLOSED_PERMANENTLY') {
      return (CrowdLevel.closed, 'Geçici Kapalı');
    }

    // Çalışma saatleri ve güncel açıklık kontrolü
    final openingHours = result['current_opening_hours'] as Map<String, dynamic>?;
    if (openingHours != null) {
      final bool isOpenNow = openingHours['open_now'] ?? true;

      // Eğer mekan o an kapalıysa bir sonraki açılış saatini ayıkla
      if (!isOpenNow) {
        String nextOpenTime = 'Kapalı';
        try {
          final now = DateTime.now();
          // Google Haritalar haftayı Pazar gününden başlatır (0 = Pazar, 1 = Pazartesi...)
          final currentWeekday = now.weekday == 7 ? 0 : now.weekday; 
          final periods = openingHours['periods'] as List?;

          if (periods != null) {
            for (var period in periods) {
              final open = period['open'] as Map<String, dynamic>?;
              // Bugünün açılış saatini bul
              if (open != null && open['day'] == currentWeekday) {
                final timeStr = open['time'] as String?; // Örn: Google'dan "0900" gelir
                if (timeStr != null && timeStr.length == 4) {
                  nextOpenTime = 'Açılış: ${timeStr.substring(0, 2)}:${timeStr.substring(2)}';
                  break;
                }
              }
            }
          }
        } catch (_) {
          nextOpenTime = 'Kapalı';
        }
        return (CrowdLevel.closed, nextOpenTime);
      }
    }

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
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;
    final isWeekend = weekday >= 6;

    // Popülarite taban skoru (Yorum sayısı yoğunluğu)
    int baseScore;
    if (totalRatings < 500) baseScore = 0;
    else if (totalRatings < 2000) baseScore = 1;
    else if (totalRatings < 10000) baseScore = 2;
    else baseScore = 3;

    // Günün saat dilimine göre yoğunluk değişimi
    int timeBonus = 0;
    if (hour >= 10 && hour <= 13) timeBonus = 1;
    else if (hour >= 14 && hour <= 17) timeBonus = 1;
    else if (hour >= 18 && hour <= 20) timeBonus = 1;
    else if (hour < 9 || hour > 20) timeBonus = -1;

    // Hafta sonu çarpanı
    if (isWeekend) timeBonus += 1;

    final total = (baseScore + timeBonus).clamp(0, 3);
    return CrowdLevel.values[total];
  }

  CrowdLevel _parseFallback(String? level) => switch (level) {
        'Sakin' => CrowdLevel.quiet,
        'Yoğun' => CrowdLevel.busy,
        'Çok Yoğun' => CrowdLevel.veryBusy,
        _ => CrowdLevel.moderate,
      };

  /// Manuel olarak önbelleği temizlemek (örn: sayfayı aşağı kaydırıp yenileyince) gerekirse tetiklenebilir.
  void clearCache() {
    _cache.clear();
  }
}