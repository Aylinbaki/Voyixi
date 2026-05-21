class PlaceItem {
  final String name;
  final String description;
  final String timeSlot;      
  final String duration;    
  final String crowdLevel; 
  final double? lat;
  final double? lng;
  final String? photoUrl;
  final String? placeId;

  PlaceItem({
    required this.name,
    required this.description,
    required this.timeSlot,
    required this.duration,
    required this.crowdLevel,
    this.lat,
    this.lng,
    this.photoUrl,
    this.placeId,
  });

  PlaceItem copyWith({
    String? name, String? description, String? timeSlot,
    String? duration, String? crowdLevel, double? lat, double? lng,
    String? photoUrl, String? placeId,
  }) => PlaceItem(
    name: name ?? this.name,
    description: description ?? this.description,
    timeSlot: timeSlot ?? this.timeSlot,
    duration: duration ?? this.duration,
    crowdLevel: crowdLevel ?? this.crowdLevel,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    photoUrl: photoUrl ?? this.photoUrl,
    placeId: placeId ?? this.placeId,
  );

  /// Firestore / Gemini'den gelen ham URL'i görüntülenebilir hale getirir.
  String? get resolvedPhotoUrl {
    final raw = photoUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.contains('](')) {
      return raw.split('](')[1].replaceAll(')', '').trim();
    }
    return raw.replaceAll('[', '').replaceAll(']', '').trim();
  }

  bool get hasPhoto => resolvedPhotoUrl != null && resolvedPhotoUrl!.isNotEmpty;

  factory PlaceItem.fromJson(Map<String, dynamic> j) => PlaceItem(
    name: j['name'] ?? '',
    description: j['description'] ?? '',
    timeSlot: j['timeSlot'] ?? '',
    duration: j['duration'] ?? '',
    crowdLevel: j['crowdLevel'] ?? 'Moderate',
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
    photoUrl: j['photoUrl'] as String?,
    placeId: j['placeId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'description': description, 'timeSlot': timeSlot,
    'duration': duration, 'crowdLevel': crowdLevel,
    'lat': lat, 'lng': lng,
    'photoUrl': photoUrl,
    'placeId': placeId,
  };
}

class DayPlan {
  final int dayNumber;
  List<PlaceItem> places;

  DayPlan({required this.dayNumber, required this.places});

  factory DayPlan.fromJson(Map<String, dynamic> j) => DayPlan(
    dayNumber: j['day'] ?? 1,
    places: (j['places'] as List? ?? [])
        .map((p) => PlaceItem.fromJson(p as Map<String, dynamic>))
        .toList(),
  );
}

class TripResult {
  final String city;
  final String country;
  final int days;
  final String budget;
  final List<DayPlan> dayPlans;
  final double totalDistanceKm;

  TripResult({
    required this.city,
    required this.days,
    required this.budget,
    required this.dayPlans,
    this.totalDistanceKm = 0,
    this.country = '',
  });

}