enum Role { user, admin }

class UserModel { 
  final String userId;
  final String displayName;
  final String email;
  final Role role;
  final int totalReviews;
  final List<String> reviewIds; 

  UserModel({
    required this.userId,
    required this.displayName,
    required this.email,
    this.role = Role.user, 
    this.totalReviews = 0,
    this.reviewIds = const [], 
  });

  // 1. ฟังก์ชันแปลงข้อมูลจาก Firestore (Map) มาเป็น Class ของเรา
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      // แปลง String 'admin' กลับมาเป็น Enum Role.admin
      role: Role.values.firstWhere(
        (e) => e.name == map['role'], 
        orElse: () => Role.user
      ),
      totalReviews: map['totalReviews']?.toInt() ?? 0,
      // แปลง List dynamic เป็น List<String>
      reviewIds: List<String>.from(map['reviewIds'] ?? []),
    );
  }

  // 2. ฟังก์ชันแปลง Class ของเราเป็น Map เพื่อบันทึกลง Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'role': role.name, // แปลง Enum เป็น String ('user', 'admin') ก่อนเก็บ
      'totalReviews': totalReviews,
      'reviewIds': reviewIds,
    };
  }
}