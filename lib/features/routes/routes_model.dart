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
    required this.dayPlans,
    required this.createdAt,
  });

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
  
}
