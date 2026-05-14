// lib/features/guide/models/guide_tour_model.dart

class GuideTour {
  final String id;
  final String guideId;
  final String guideName;
  final String guideContact; // mail veya telefon
  final String title;
  final String description;
  final String city;
  final String? imageUrl;
  final DateTime tourDate;
  final String tourTime;     // "10:00"
  final List<String> places; // Gezilecek yerler
  final double? price;       // opsiyonel
  final int? maxParticipants; // opsiyonel
  final List<String> likedBy; // userId listesi
  final DateTime createdAt;

  GuideTour({
    required this.id,
    required this.guideId,
    required this.guideName,
    required this.guideContact,
    required this.title,
    required this.description,
    required this.city,
    this.imageUrl,
    required this.tourDate,
    required this.tourTime,
    required this.places,
    this.price,
    this.maxParticipants,
    this.likedBy = const [],
    required this.createdAt,
  });

  int get likeCount => likedBy.length;

  Map<String, dynamic> toMap() => {
    'id': id,
    'guideId': guideId,
    'guideName': guideName,
    'guideContact': guideContact,
    'title': title,
    'description': description,
    'city': city,
    'imageUrl': imageUrl,
    'tourDate': tourDate.toIso8601String(),
    'tourTime': tourTime,
    'places': places,
    'price': price,
    'maxParticipants': maxParticipants,
    'likedBy': likedBy,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GuideTour.fromMap(Map<String, dynamic> m) => GuideTour(
    id: m['id'] ?? '',
    guideId: m['guideId'] ?? '',
    guideName: m['guideName'] ?? '',
    guideContact: m['guideContact'] ?? '',
    title: m['title'] ?? '',
    description: m['description'] ?? '',
    city: m['city'] ?? '',
    imageUrl: m['imageUrl'],
    tourDate: DateTime.tryParse(m['tourDate'] ?? '') ?? DateTime.now(),
    tourTime: m['tourTime'] ?? '',
    places: List<String>.from(m['places'] ?? []),
    price: (m['price'] as num?)?.toDouble(),
    maxParticipants: m['maxParticipants'] as int?,
    likedBy: List<String>.from(m['likedBy'] ?? []),
    createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
  );

  GuideTour copyWith({List<String>? likedBy}) => GuideTour(
    id: id, guideId: guideId, guideName: guideName,
    guideContact: guideContact, title: title, description: description,
    city: city, imageUrl: imageUrl, tourDate: tourDate, tourTime: tourTime,
    places: places, price: price, maxParticipants: maxParticipants,
    likedBy: likedBy ?? this.likedBy, createdAt: createdAt,
  );
}