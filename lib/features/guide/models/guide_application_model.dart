// lib/features/guide/models/guide_application_model.dart

class GuideApplication {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String city;
  final int age;
  final List<String> languages;
  final String about;        // Kendini tanıtma
  final String tourIdeas;    // Yapmak istediği turlar
  final String status;       // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;

  GuideApplication({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.age,
    required this.languages,
    required this.about,
    required this.tourIdeas,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'city': city,
    'age': age,
    'languages': languages,
    'about': about,
    'tourIdeas': tourIdeas,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GuideApplication.fromMap(Map<String, dynamic> m) =>
      GuideApplication(
        id: m['id'] ?? '',
        userId: m['userId'] ?? '',
        fullName: m['fullName'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        city: m['city'] ?? '',
        age: m['age'] ?? 0,
        languages: List<String>.from(m['languages'] ?? []),
        about: m['about'] ?? '',
        tourIdeas: m['tourIdeas'] ?? '',
        status: m['status'] ?? 'pending',
        createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
      );
}