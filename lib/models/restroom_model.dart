import 'package:cloud_firestore/cloud_firestore.dart';

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
  final double avgCleanliness;
  final double avgAvailability;
  final double avgAmenities;
  final double avgScent;
  final int totalRatings;
  
  // Timestamp fields
  final DateTime createdAt;      // When the restroom was added
  final DateTime updatedAt;      // When last modified
  final String createdBy;        // User ID who added this restroom
  final String? updatedBy;       // User ID who last updated

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
    this.avgCleanliness = 0.0,
    this.avgAvailability = 0.0,
    this.avgAmenities = 0.0,
    this.avgScent = 0.0,
    this.totalRatings = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.createdBy = '',
    this.updatedBy,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // 1. Convert from Firebase (Map) -> Object
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
      amenities: Map<String, bool>.from(map['amenities'] ?? {}),
      photos: List<String>.from(map['photos'] ?? []),
      reviewIds: List<String>.from(map['reviewIds'] ?? []),
      avgRating: (map['avgRating'] ?? 0.0).toDouble(),
      avgCleanliness: (map['avgCleanliness'] ?? 0.0).toDouble(),
      avgAvailability: (map['avgAvailability'] ?? 0.0).toDouble(),
      avgAmenities: (map['avgAmenities'] ?? 0.0).toDouble(),
      avgScent: (map['avgScent'] ?? 0.0).toDouble(),
      totalRatings: (map['totalRatings'] ?? 0).toInt(),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'],
    );
  }

  // 2. Convert Object -> Map for Firebase
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
      'avgCleanliness': avgCleanliness,
      'avgAvailability': avgAvailability,
      'avgAmenities': avgAmenities,
      'avgScent': avgScent,
      'totalRatings': totalRatings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  // Helper method to create a copy with updated fields
  RestroomModel copyWith({
    String? restroomName,
    String? address,
    double? latitude,
    double? longitude,
    String? openTime,
    String? closeTime,
    bool? isFree,
    double? price,
    bool? is24hrs,
    String? phoneNumber,
    Map<String, bool>? amenities,
    List<String>? photos,
    List<String>? reviewIds,
    double? avgRating,
    double? avgCleanliness,
    double? avgAvailability,
    double? avgAmenities,
    double? avgScent,
    int? totalRatings,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return RestroomModel(
      restroomId: this.restroomId,
      restroomName: restroomName ?? this.restroomName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      isFree: isFree ?? this.isFree,
      price: price ?? this.price,
      is24hrs: is24hrs ?? this.is24hrs,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amenities: amenities ?? this.amenities,
      photos: photos ?? this.photos,
      reviewIds: reviewIds ?? this.reviewIds,
      avgRating: avgRating ?? this.avgRating,
      avgCleanliness: avgCleanliness ?? this.avgCleanliness,
      avgAvailability: avgAvailability ?? this.avgAvailability,
      avgAmenities: avgAmenities ?? this.avgAmenities,
      avgScent: avgScent ?? this.avgScent,
      totalRatings: totalRatings ?? this.totalRatings,
      createdAt: this.createdAt, // Never change
      updatedAt: updatedAt ?? DateTime.now(), // Auto-update to now
      createdBy: this.createdBy, // Never change
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
