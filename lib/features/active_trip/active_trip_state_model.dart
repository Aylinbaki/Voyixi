enum TripPlaceStatus { waiting, current, completed }
class TripPlaceState {
  final int dayIdx;
  final int placeIdx;
  TripPlaceStatus status;
  int? rating;
  String? review;

  TripPlaceState({
    required this.dayIdx,
    required this.placeIdx,
    this.status = TripPlaceStatus.waiting,
    this.rating,
    this.review,
  });

  Map<String, dynamic> toMap() => {
    'dayIdx': dayIdx,
    'placeIdx': placeIdx,
    'status': status.name,
    'rating': rating,
    'review': review,
  };

  factory TripPlaceState.fromMap(Map<String, dynamic> m) => TripPlaceState(
    dayIdx: m['dayIdx'] ?? 0,
    placeIdx: m['placeIdx'] ?? 0,
    status: TripPlaceStatus.values.firstWhere(
      (s) => s.name == (m['status'] ?? 'waiting'),
      orElse: () => TripPlaceStatus.waiting,
    ),
    rating: m['rating'] as int?,
    review: m['review'] as String?,
  );
}