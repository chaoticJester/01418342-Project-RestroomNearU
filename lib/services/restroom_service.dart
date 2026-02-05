import '../models/restroom_model.dart';
import '../models/review_model.dart';

/// Mock data service for restrooms
/// TODO: Replace with real Firebase service later
class RestroomService {
  
  // Mock restroom data
  static List<RestroomModel> getMockRestrooms() {
    return [
      RestroomModel(
        restroomId: '1',
        restroomName: 'Engineer 2nd floor toilet',
        address: '2nd floor Engineer Building',
        latitude: 13.8476,
        longitude: 100.5696,
        openTime: '9:00',
        closeTime: '18:00',
        isFree: true,
        is24hrs: false,
        phoneNumber: '02-123-4567',
        amenities: {
          'toiletPaper': true,
          'soap': true,
          'handDryer': true,
          'wheelchairAccessible': true,
          'babyChangingStation': true,
          'hotWater': true,
          'wifi': false,
          'powerOutlet': false,
        },
        photos: [],
        reviewIds: ['r1', 'r2', 'r3', 'r4', 'r5', 'r6'],
        avgRating: 5.0,
        totalRatings: 23,
      ),
      RestroomModel(
        restroomId: '2',
        restroomName: 'Science Building 3rd floor',
        address: '3rd floor Science Building',
        latitude: 13.8480,
        longitude: 100.5700,
        openTime: '8:00',
        closeTime: '20:00',
        isFree: true,
        is24hrs: false,
        phoneNumber: '02-123-4568',
        amenities: {
          'toiletPaper': true,
          'soap': true,
          'handDryer': false,
          'wheelchairAccessible': true,
          'babyChangingStation': false,
          'hotWater': true,
          'wifi': true,
          'powerOutlet': true,
        },
        photos: [],
        reviewIds: [],
        avgRating: 4.5,
        totalRatings: 15,
      ),
      RestroomModel(
        restroomId: '3',
        restroomName: 'Library 1st floor',
        address: '1st floor Main Library',
        latitude: 13.8470,
        longitude: 100.5690,
        openTime: '7:00',
        closeTime: '22:00',
        isFree: true,
        is24hrs: false,
        phoneNumber: '02-123-4569',
        amenities: {
          'toiletPaper': true,
          'soap': true,
          'handDryer': true,
          'wheelchairAccessible': true,
          'babyChangingStation': true,
          'hotWater': false,
          'wifi': true,
          'powerOutlet': true,
        },
        photos: [],
        reviewIds: [],
        avgRating: 4.8,
        totalRatings: 42,
      ),
    ];
  }

  // Get a single restroom by ID
  static RestroomModel? getRestroomById(String id) {
    try {
      return getMockRestrooms().firstWhere((r) => r.restroomId == id);
    } catch (e) {
      return null;
    }
  }

  // Calculate distance from user (mock)
  static String getDistance(double lat, double lng) {
    // TODO: Implement actual distance calculation
    return '500m from you';
  }

  // Check if restroom is currently open
  static bool isOpen(RestroomModel restroom) {
    if (restroom.is24hrs) return true;
    
    // TODO: Implement actual time checking
    // For now, just return true as mock
    return true;
  }

  // Get rating breakdown (mock)
  static Map<String, int> getRatingBreakdown(String restroomId) {
    // Mock rating breakdown
    return {
      'cleanliness': 5,
      'availability': 5,
      'amenities': 5,
      'smell': 5,
    };
  }
}
