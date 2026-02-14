# Quick Reference Guide

## 🎨 New Files Created

### `/lib/utils/`
```
constants.dart    → Colors, sizes, routes, text styles
helpers.dart      → Distance calc, date format, validation
```

### `/lib/widgets/`
```
custom_button.dart    → Reusable button component
star_rating.dart      → Star rating widgets
loading_states.dart   → Loading/Empty/Error states
```

### Documentation
```
ARCHITECTURE.md      → Full architecture documentation
PROJECT_SUMMARY.md   → This summary
```

## 🔥 Quick Examples

### 1. Using Colors
```dart
// ❌ Before:
Container(
  color: Color(0xFFBADFDB),
)

// ✅ After:
import '../utils/constants.dart';

Container(
  color: AppConstants.primaryColor,
)
```

### 2. Using Custom Button
```dart
// ❌ Before:
ElevatedButton(
  onPressed: _submit,
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFBADFDB),
    // ... more styling
  ),
  child: Text('Submit'),
)

// ✅ After:
import '../widgets/custom_button.dart';

CustomButton(
  text: 'Submit',
  icon: Icons.send,
  onPressed: _submit,
  isLoading: isSubmitting,
)
```

### 3. Using Star Rating
```dart
// ❌ Before:
Row(
  children: List.generate(5, (index) {
    return GestureDetector(
      onTap: () => setState(() => rating = index + 1),
      child: Icon(
        index < rating ? Icons.star : Icons.star_border,
        // ... more code
      ),
    );
  }),
)

// ✅ After:
import '../widgets/star_rating.dart';

StarRating(
  rating: rating,
  onRatingChanged: (newRating) {
    setState(() => rating = newRating);
  },
)
```

### 4. Using Helpers
```dart
// ❌ Before:
String distance = "500m from you"; // Hard-coded

// ✅ After:
import '../utils/helpers.dart';

double distKm = AppHelpers.calculateDistance(
  userLat, userLng,
  restroomLat, restroomLng,
);
String distance = AppHelpers.formatDistance(distKm);
```

### 5. Using Loading States
```dart
// ❌ Before:
if (isLoading) {
  return Center(
    child: CircularProgressIndicator(),
  );
}

// ✅ After:
import '../widgets/loading_states.dart';

if (isLoading) {
  return LoadingIndicator(
    message: 'Loading restrooms...',
  );
}

if (error != null) {
  return ErrorState(
    message: error!,
    onRetry: _loadData,
  );
}

if (data.isEmpty) {
  return EmptyState(
    icon: Icons.wc,
    title: 'No Restrooms Found',
    description: 'Try adjusting your filters',
  );
}
```

## 📋 Migration Checklist

### Phase 1: Constants (1 hour)
- [ ] Replace all `Color(0xFFBADFDB)` with `AppConstants.primaryColor`
- [ ] Replace all `Color(0xFFFCF9EA)` with `AppConstants.backgroundColor`
- [ ] Replace all `Color(0xFFFFA4A4)` with `AppConstants.accentColor`
- [ ] Replace hard-coded padding with `AppConstants.padding*`
- [ ] Replace hard-coded font sizes with `AppConstants.textSize*`

### Phase 2: Widgets (2 hours)
- [ ] Replace `ElevatedButton` with `CustomButton`
- [ ] Replace manual star rating with `StarRating`
- [ ] Replace loading indicators with `LoadingIndicator`
- [ ] Add `EmptyState` to list views
- [ ] Add `ErrorState` for error handling

### Phase 3: Helpers (1 hour)
- [ ] Use `AppHelpers.formatDistance()` for distance display
- [ ] Use `AppHelpers.formatDate()` for review dates
- [ ] Use `AppHelpers.formatAmenityName()` for amenity labels
- [ ] Add email validation with `AppHelpers.isValidEmail()`
- [ ] Add phone validation with `AppHelpers.isValidPhoneNumber()`

### Phase 4: Testing (1 hour)
- [ ] Test all updated pages
- [ ] Verify colors are consistent
- [ ] Check button interactions
- [ ] Test loading states
- [ ] Verify distance calculations

## 🎯 Files to Update First

### High Priority:
1. `restroom_detail_page.dart` - Uses many hard-coded values
2. `write_review_page.dart` - Has repeated star rating code
3. `report_issue_page.dart` - Has repeated button code

### Medium Priority:
4. `user_homepage.dart` - Can use helper functions
5. `add_new_restroom_page.dart` - Can use custom buttons
6. `photo_gallery_page.dart` - Can use constants

## 💡 Pro Tips

### 1. Import Organization
```dart
// 1. Flutter imports
import 'package:flutter/material.dart';

// 2. Package imports
import 'package:google_maps_flutter/google_maps_flutter.dart';

// 3. Project imports
import '../models/restroom_model.dart';
import '../services/restroom_service.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';
```

### 2. Widget Extraction
When you see the same UI code 3+ times, extract it to a widget!

### 3. Constant Naming
Use descriptive names:
```dart
// ❌ Bad
const c1 = Color(0xFF...);

// ✅ Good
const primaryColor = Color(0xFF...);
```

### 4. Helper Functions
If you're doing the same calculation/formatting 2+ times, make a helper!

## 🚨 Common Mistakes to Avoid

### ❌ Don't:
```dart
// Don't hard-code colors
color: Color(0xFFBADFDB)

// Don't repeat star rating code
Row(children: [for star in stars ...])

// Don't hard-code text sizes
fontSize: 16

// Don't repeat button styling
ElevatedButton(style: ElevatedButton.styleFrom(...))
```

### ✅ Do:
```dart
// Use constants
color: AppConstants.primaryColor

// Use widgets
StarRating(rating: rating)

// Use constants
fontSize: AppConstants.textSizeMedium

// Use widgets
CustomButton(text: 'Submit')
```

## 📞 Need Help?

Check these files:
1. `ARCHITECTURE.md` - Full architecture guide
2. `PROJECT_SUMMARY.md` - Overall project assessment
3. `/lib/widgets/` - Example widget implementations
4. `/lib/utils/` - Helper function examples

## 🎉 Benefits You'll Get

✅ **Consistency** - Same colors, sizes, styles everywhere
✅ **Maintainability** - Change one constant, update everywhere
✅ **Reusability** - Write once, use many times
✅ **Readability** - `AppConstants.primaryColor` > `Color(0xFFBADFDB)`
✅ **Productivity** - Less code to write, faster development
✅ **Quality** - Fewer bugs, easier testing

---

**Start with one file at a time!** Good luck! 🚀
