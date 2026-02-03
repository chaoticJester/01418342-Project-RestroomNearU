class RestroomModel {
  final String restroomId;
  final String restroomName;
  final String address;
  final double latitude;  
  final double longitude; 
  final String? openTime; 
  final String? closeTime; 
  final bool isFree;
  final double? price;    
  final bool is24hrs;
  final String phoneNumber;
  final Map<String, bool> amenities; 
  final List<String> photos;
  final List<String> reviewIds;
  final double avgRating; 
  final int totalRatings; 

  RestroomModel({
    required this.restroomId,
    required this.restroomName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.openTime,
    this.closeTime,
    this.isFree = true,
    this.price,
    this.is24hrs = false,
    this.phoneNumber = '',
    required this.amenities,
    this.photos = const [],
    this.reviewIds = const [],
    this.avgRating = 0.0,
    this.totalRatings = 0,
  });

  // 1. แปลงข้อมูลจาก Firebase (Map) -> Object
  factory RestroomModel.fromMap(Map<String, dynamic> map, String id) {
    return RestroomModel(
      restroomId: id, 
      restroomName: map['restroomName'] ?? 'Unknown Restroom',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(), 
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      openTime: map['openTime'],
      closeTime: map['closeTime'],
      isFree: map['isFree'] ?? true,
      price: map['price']?.toDouble(),
      is24hrs: map['is24hrs'] ?? false,
      phoneNumber: map['phoneNumber'] ?? '',
      // แปลง Map<String, dynamic> เป็น Map<String, bool>
      amenities: Map<String, bool>.from(map['amenities'] ?? {}),
      photos: List<String>.from(map['photos'] ?? []),
      reviewIds: List<String>.from(map['reviewIds'] ?? []),
      avgRating: (map['avgRating'] ?? 0.0).toDouble(),
      totalRatings: (map['totalRatings'] ?? 0).toInt(),
    );
  }

  // 2. แปลง Object -> Map เพื่อส่งขึ้น Firebase
  Map<String, dynamic> toMap() {
    return {
      'restroomName': restroomName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'openTime': openTime,
      'closeTime': closeTime,
      'isFree': isFree,
      'price': price,
      'is24hrs': is24hrs,
      'phoneNumber': phoneNumber,
      'amenities': amenities,
      'photos': photos,
      'reviewIds': reviewIds,
      'avgRating': avgRating,
      'totalRatings': totalRatings,
    };
  }
}