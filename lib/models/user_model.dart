class UserModel {
  final String uid;
  final String email;
  final String? fullName;
  final bool isAdmin;
  final bool isGuide;
  final bool isPending; // Rehberlik başvurusu onay bekliyor mu?

  UserModel({
    required this.uid,
    required this.email,
    this.fullName,
    this.isAdmin = false,
    this.isGuide = false,
    this.isPending = false,
  });

  // Firestore'dan gelen veriyi (Map) nesneye çevirir
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      fullName: map['fullName'],
      isAdmin: map['isAdmin'] ?? false,
      isGuide: map['isGuide'] ?? false,
      isPending: map['isPending'] ?? false,
    );
  }

  // Nesneyi Firestore'a göndermek için Map'e çevirir
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'isAdmin': isAdmin,
      'isGuide': isGuide,
      'isPending': isPending,
    };
  }
}