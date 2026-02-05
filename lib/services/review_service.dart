import '../models/review_model.dart';

/// Mock data service for reviews
/// TODO: Replace with real Firebase service later
class ReviewService {
  
  // Get mock reviews for a restroom
  static List<ReviewModel> getReviewsByRestroomId(String restroomId) {
    final now = DateTime.now();
    
    return [
      ReviewModel(
        reviewId: 'r1',
        restroomId: restroomId,
        reviewerId: 'u1',
        reviewerName: 'Pheeraphat Jumnong',
        reviewerPhotoUrl: '',
        rating: 5.0,
        comment: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin euismod libero sit amet diam sagittis pellentesque. Proin Proin lobortis commodo arcu',
        timestamp: now.subtract(const Duration(days: 1)),
        totalLikes: 12,
        photos: [],
      ),
      ReviewModel(
        reviewId: 'r2',
        restroomId: restroomId,
        reviewerId: 'u2',
        reviewerName: 'John Stus',
        reviewerPhotoUrl: '',
        rating: 5.0,
        comment: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin euismod libero sit amet diam sagittis pellentesque. Proin Proin lobortis commodo arcu',
        timestamp: now.subtract(const Duration(days: 3)),
        totalLikes: 8,
        photos: [],
      ),
      ReviewModel(
        reviewId: 'r3',
        restroomId: restroomId,
        reviewerId: 'u3',
        reviewerName: 'Heelo Woorld',
        reviewerPhotoUrl: '',
        rating: 5.0,
        comment: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin euismod libero sit amet diam sagittis pellentesque. Proin Proin lobortis commodo arcu',
        timestamp: now.subtract(const Duration(days: 5)),
        totalLikes: 15,
        photos: [],
      ),
      ReviewModel(
        reviewId: 'r4',
        restroomId: restroomId,
        reviewerId: 'u4',
        reviewerName: 'King Cha II',
        reviewerPhotoUrl: '',
        rating: 5.0,
        comment: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin euismod libero sit amet diam sagittis pellentesque. Proin Proin lobortis commodo arcu',
        timestamp: now.subtract(const Duration(days: 7)),
        totalLikes: 5,
        photos: [],
      ),
      ReviewModel(
        reviewId: 'r5',
        restroomId: restroomId,
        reviewerId: 'u1',
        reviewerName: 'Pheeraphat Jumnong',
        reviewerPhotoUrl: '',
        rating: 5.0,
        comment: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin euismod libero sit amet diam sagittis pellentesque. Proin Proin lobortis commodo arcu',
        timestamp: now.subtract(const Duration(days: 10)),
        totalLikes: 20,
        photos: [],
      ),
      ReviewModel(
        reviewId: 'r6',
        restroomId: restroomId,
        reviewerId: 'u2',
        reviewerName: 'John Stus',
        reviewerPhotoUrl: '',
        rating: 5.0,
        comment: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin euismod libero sit amet diam sagittis pellentesque. Proin Proin lobortis commodo arcu',
        timestamp: now.subtract(const Duration(days: 14)),
        totalLikes: 3,
        photos: [],
      ),
    ];
  }

  // Get rating badge text
  static String getRatingBadge(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 3.5) return 'Good';
    if (rating >= 2.5) return 'Average';
    if (rating >= 1.5) return 'Poor';
    return 'Very Poor';
  }
}
