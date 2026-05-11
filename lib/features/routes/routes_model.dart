import '../trip_result/trip_result_model.dart';
class SavedTrip {
  final String id;
  final String title;        
  final String city;
  final int days;
  final String budget;
  final List<String> preferences;
  final String summary;
  final String? imageUrl;
  final DateTime? tripDate;
  final DateTime? startDate; //tur başla
  final DateTime? endDate;   //tur bitiş (starDate+days)
  final double completionRate; //tamamlanma oranı
  final List<Map<String, dynamic>> dayPlans;
  final DateTime createdAt;

  SavedTrip({
    required this.id,
    required this.title,
    required this.city,
    required this.days,
    required this.budget,
    required this.preferences,
    required this.summary,
    this.imageUrl,
    this.tripDate,
    this.startDate,
    this.endDate,
    this.completionRate = 0.0,
    required this.dayPlans,
    required this.createdAt,
  });

  /// Tur bugün aktif mi? (startDate <= bugün <= endDate)
  bool get isActive {
    if (startDate == null || endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return !today.isBefore(start) && !today.isAfter(end);
  }

  /// Tur henüz başlamadı mı?
  bool get isUpcoming {
    if (startDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    return today.isBefore(start);
  }

  /// Tur bitti mi?
  bool get isFinished {
    if (endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return today.isAfter(end);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'city': city,
    'days': days,
    'budget': budget,
    'preferences': preferences,
    'summary': summary,
    'imageUrl': imageUrl,
    'tripDate': tripDate?.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'completionRate': completionRate,
    'dayPlans': dayPlans,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedTrip.fromMap(Map<String, dynamic> map) => SavedTrip(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    city: map['city'] ?? '',
    days: map['days'] ?? 0,
    budget: map['budget'] ?? '',
    preferences: List<String>.from(map['preferences'] ?? []),
    summary: map['summary'] ?? '',
    imageUrl: map['imageUrl'],
    tripDate: map['tripDate'] != null
        ? DateTime.tryParse(map['tripDate'])
        : null,
    startDate: map['startDate'] != null
        ? DateTime.tryParse(map['startDate'])
        : null,
    endDate: map['endDate'] != null
        ? DateTime.tryParse(map['endDate'])
        : null,
    completionRate:
    (map['completionRate'] as num?)?.toDouble() ?? 0.0,
    dayPlans: List<Map<String, dynamic>>.from(
      (map['dayPlans'] ?? []).map((d) => Map<String, dynamic>.from(d)),
    ),
    createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
  );
  
  TripResult toTripResult() => TripResult(
  city: city,
  days: days,
  budget: budget,
  dayPlans: dayPlans
      .map((d) => DayPlan.fromJson(d))
      .toList(),
);
  //completionRate ?? this.completionRate satırı:
  // eğer yeni değer verilmişse onu kullan, verilmemişse mevcut değeri koru.
  SavedTrip copyWith({double? completionRate}) => SavedTrip(
    id: id,
    title: title,
    city: city,
    days: days,
    budget: budget,
    preferences: preferences,
    summary: summary,
    imageUrl: imageUrl,
    tripDate: tripDate,
    startDate: startDate,
    endDate: endDate,
    completionRate: completionRate ?? this.completionRate,
    dayPlans: dayPlans,
    createdAt: createdAt,
  );
}
