# Project Structure & Architecture Guide

## 📁 Current Project Structure

```
lib/
├── models/                    # Data Models (Entities)
│   ├── restroom_model.dart   # Restroom data structure
│   ├── review_model.dart     # Review data structure
│   └── user_model.dart       # User data structure
│
├── services/                  # Business Logic & Data Operations
│   ├── restroom_service.dart     # Restroom business logic (mock)
│   ├── restroom_firestore.dart   # Restroom Firebase operations
│   ├── review_service.dart       # Review business logic (mock)
│   ├── review_firestore.dart     # Review Firebase operations
│   └── user_firestore.dart       # User Firebase operations
│
├── pages/                     # UI Screens/Pages
│   ├── login_page.dart
│   └── user/
│       ├── user_homepage.dart
│       ├── restroom_detail_page.dart
│       ├── add_new_restroom_page.dart
│       ├── write_review_page.dart
│       ├── photo_gallery_page.dart
│       └── report_issue_page.dart
│
├── widgets/                   # Reusable UI Components (NEW!)
│   ├── custom_button.dart    # Standardized button widget
│   ├── star_rating.dart      # Star rating components
│   └── loading_states.dart   # Loading/Empty/Error states
│
├── utils/                     # Helper Functions & Constants (NEW!)
│   ├── constants.dart        # App-wide constants (colors, sizes, etc.)
│   └── helpers.dart          # Utility functions (distance calc, formatting)
│
├── firebase_options.dart      # Firebase configuration
└── main.dart                 # App entry point
```

## 🎯 Architecture Pattern: **Layered Architecture**

### Layer 1: Models (Data Layer)
**Purpose:** Define data structures
- Pure Dart classes
- No business logic
- `fromMap()` and `toMap()` methods for Firebase conversion
- **Example:** `RestroomModel`, `ReviewModel`, `UserModel`

### Layer 2: Services (Business Logic Layer)
**Purpose:** Handle all business logic and data operations
- Split into two types:
  - **Mock Services** (`*_service.dart`): For development/testing
  - **Firebase Services** (`*_firestore.dart`): For production
- No UI code
- Return data to pages
- **Example:** `RestroomService`, `ReviewService`

### Layer 3: Pages (Presentation Layer)
**Purpose:** Display UI and handle user interactions
- Stateful/Stateless widgets
- Call services for data
- Handle navigation
- Minimal business logic
- **Example:** `UserHomePage`, `RestroomDetailPage`

### Layer 4: Widgets (Reusable UI Components)
**Purpose:** Share common UI elements
- Reusable across multiple pages
- Customizable with parameters
- Consistent design
- **Example:** `CustomButton`, `StarRating`

### Layer 5: Utils (Helper Layer)
**Purpose:** Provide utility functions and constants
- Constants for colors, sizes, routes
- Helper functions (distance calculation, formatting)
- Validators
- **Example:** `AppConstants`, `AppHelpers`

## ✅ Best Practices Currently Followed

1. ✅ **Separation of Concerns** - Models, Services, and UI are separated
2. ✅ **Mock Services** - Good for development before Firebase integration
3. ✅ **Model Conversion Methods** - `fromMap()` and `toMap()` for Firebase
4. ✅ **Type Safety** - Strong typing with Dart
5. ✅ **Organized File Structure** - Clear directory hierarchy

## ⚠️ Issues Found & Fixed

### 1. Missing Field in ReviewModel
**Issue:** `helpfulCount` field was used in sorting but not defined in model
**Fixed:** ✅ Added `helpfulCount` to ReviewModel and mock data

### 2. No Reusable Widgets
**Issue:** Repeated UI code across pages
**Fixed:** ✅ Created `widgets/` directory with reusable components

### 3. Magic Numbers & Hard-coded Values
**Issue:** Colors, sizes, and strings repeated everywhere
**Fixed:** ✅ Created `utils/constants.dart` for app-wide constants

### 4. No Helper Functions
**Issue:** Distance calculation, date formatting repeated
**Fixed:** ✅ Created `utils/helpers.dart` for utility functions

## 🔧 Recommended Next Steps

### Priority 1: Use New Constants & Widgets
Replace hard-coded values in existing pages:
```dart
// Before:
color: Color(0xFFBADFDB)

// After:
color: AppConstants.primaryColor
```

### Priority 2: Implement Firebase Services
Complete the `*_firestore.dart` files:
- Add CRUD operations
- Handle authentication
- Manage real-time updates

### Priority 3: Add State Management (Optional)
For complex state, consider:
- Provider (simple)
- Riverpod (recommended)
- Bloc (advanced)

### Priority 4: Add Error Handling
- Try-catch blocks in services
- User-friendly error messages
- Retry mechanisms

### Priority 5: Add Input Validation
- Form validators
- Phone number format
- Email validation

## 📝 Code Examples

### Using Constants:
```dart
import '../utils/constants.dart';

Container(
  padding: EdgeInsets.all(AppConstants.paddingMedium),
  decoration: BoxDecoration(
    color: AppConstants.primaryColor,
    borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
  ),
)
```

### Using Reusable Widgets:
```dart
import '../widgets/custom_button.dart';
import '../widgets/star_rating.dart';

// Instead of ElevatedButton
CustomButton(
  text: 'Submit Review',
  icon: Icons.send,
  onPressed: _submitReview,
  isLoading: isSubmitting,
)

// Instead of manual star rating
StarRating(
  rating: overallRating,
  onRatingChanged: (rating) {
    setState(() => overallRating = rating);
  },
)
```

### Using Helpers:
```dart
import '../utils/helpers.dart';

// Calculate distance
double distance = AppHelpers.calculateDistance(
  userLat, userLng,
  restroomLat, restroomLng,
);
String displayDistance = AppHelpers.formatDistance(distance);

// Format date
String timeAgo = AppHelpers.formatDate(review.timestamp);
```

## 🎨 Design Patterns Used

### 1. Repository Pattern (Partial)
Services act as repositories for data access

### 2. Factory Pattern
Models use factory constructors (`fromMap()`)

### 3. Service Layer Pattern
Business logic separated from UI

### 4. Component Pattern
Reusable widgets for consistent UI

## 🚀 Migration Guide

### Step 1: Update Existing Pages
Gradually replace hard-coded values with constants

### Step 2: Extract Reusable UI
Move repeated UI code to new widgets

### Step 3: Use Helper Functions
Replace manual calculations with helper methods

### Step 4: Test Thoroughly
Ensure nothing breaks after refactoring

## 📚 Further Reading

- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Best Practices](https://flutter.dev/docs/development/ui/layout/constraints)

---

**Last Updated:** February 2026
**Maintained By:** Development Team
