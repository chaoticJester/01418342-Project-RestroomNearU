# 🚽 RestroomNearU — Project Presentation Summary
**CS342 Mobile Application Development**

---

## 📱 What is RestroomNearU?

RestroomNearU is a Flutter mobile application that helps users **find nearby restrooms quickly**, view reviews, photos, and detailed information, and contribute by adding new restrooms to the community database.

**Core Problem Solved:**
- Hard to find a restroom when you urgently need one
- No way to know if a restroom is clean or not before going
- Missing details like price, opening hours, or available amenities

---

## 👥 User Roles

| Role | Description |
|------|-------------|
| **User** | Browse map, search restrooms, write reviews, add new restrooms, report issues |
| **Admin** | Approve/reject restroom requests, manage reports, ban/suspend users |

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Dart) |
| **Backend / Database** | Firebase (Cloud Firestore) |
| **Authentication** | Firebase Auth |
| **File Storage** | Firebase Storage |
| **Map & Location** | Google Maps Flutter SDK + Geolocator |
| **Address Search** | Google Places API |
| **Navigation / Routing** | Google Directions API |
| **State Management** | Provider |
| **Secrets Management** | flutter_dotenv (.env file) |

---

## 🔌 APIs Used — Deep Dive

---

### 1. 🔥 Firebase Authentication
**Package:** `firebase_auth: ^6.1.4`

**What it does:**
Handles all user identity — sign up, login, password reset, and Google Sign-In.

**How we use it:**

```dart
// Email & Password Login
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email, password: password
);

// Google Sign-In
final googleUser = await GoogleSignIn(serverClientId: '...').signIn();
final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,
  idToken: googleAuth.idToken,
);
await FirebaseAuth.instance.signInWithCredential(credential);

// Password Reset
await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

// Listen to auth state changes (used in main.dart to route users)
FirebaseAuth.instance.authStateChanges().listen((user) { ... });
```

**Key flows:**
- On app start, `authStateChanges()` stream decides whether to show `LoginPage` or `UserHomePage`/`AdminHomePage`
- After login, `syncUserWithFirestore()` creates a Firestore user doc if it doesn't exist yet
- If a user is banned or suspended, a lock screen is shown instead of the app

---

### 2. 🗄️ Cloud Firestore (Main Database)
**Package:** `cloud_firestore: ^6.1.2`

**What it does:**
NoSQL real-time database storing all app data — users, restrooms, reviews, requests, and reports.

**Collections:**

| Collection | Purpose |
|------------|---------|
| `users` | User profiles, points, favorites, role |
| `restrooms` | Restroom data with ratings |
| `reviews` | User reviews linked to restrooms |
| `requests` | Pending admin approval queue |
| `reports` | User-submitted issue reports |

**How we use it:**

```dart
// Real-time stream (auto-updates UI when data changes)
FirebaseFirestore.instance
  .collection('restrooms')
  .snapshots()
  .map((snap) => snap.docs.map(RestroomModel.fromMap).toList());

// Atomic transaction (used when adding a review to update restroom averages)
await firestore.runTransaction((transaction) async {
  final restroomSnap = await transaction.get(restroomRef);
  // recalculate avg ratings...
  transaction.set(reviewRef, reviewData);
  transaction.update(restroomRef, { 'avgRating': newAvg, ... });
});

// Increment points when admin approves restroom
await _userCollection.doc(userId).update({
  'totalAdded': FieldValue.increment(1),
  'points': FieldValue.increment(50),
});
```

**Why transactions matter:**
When a user writes a review, we atomically update the restroom's `avgRating`, `avgCleanliness`, `avgAvailability`, `avgAmenities`, and `avgScent` in a single transaction — preventing race conditions if two users submit reviews simultaneously.

---

### 3. 📦 Firebase Storage
**Package:** `firebase_storage: ^13.0.6`

**What it does:**
Stores all uploaded images — profile photos, restroom photos, and review photos.

**How we use it:**

```dart
// Upload a restroom photo
final ref = FirebaseStorage.instance
  .ref()
  .child('requests/$requestId/$timestamp.jpg');

await ref.putFile(
  imageFile,
  SettableMetadata(contentType: 'image/jpeg'),
);

final downloadUrl = await ref.getDownloadURL();
// Store downloadUrl in Firestore
```

**Storage paths used:**

| Path | Content |
|------|---------|
| `profile_photos/{userId}.jpg` | User profile photo |
| `requests/{requestId}/{timestamp}.jpg` | Photos attached to restroom submission |
| `restrooms/{restroomId}/{timestamp}.jpg` | Photos added to existing restrooms |
| `reviews/{reviewId}/{timestamp}.jpg` | Review photos |

---

### 4. 🗺️ Google Maps Flutter SDK *(Main API)*
**Package:** `google_maps_flutter: ^2.14.2`

**What it does:**
Displays the interactive map on the homepage where all restrooms are shown as markers. Also used in the navigation page to draw the walking route.

**How we use it:**

```dart
GoogleMap(
  initialCameraPosition: CameraPosition(target: userLatLng, zoom: 15),
  markers: _buildMarkers(),       // custom restroom pin icons
  onMapCreated: (controller) => _mapController = controller,
  onCameraMove: (position) => _onZoomChanged(position.zoom),
  onCameraIdle: () => _rebuildClusters(),
  myLocationEnabled: true,
)
```

**Custom features built on top:**
- **Cluster markers** — restrooms that are close together merge into a single circle showing the count, and split apart as you zoom in (using a custom grid-based clustering algorithm)
- **Custom pin icons** — rendered using Flutter's `Canvas` API to show the restroom's rating score directly on the pin
- **Navigation route polyline** — walking route is drawn on the map using decoded polyline data from the Directions API

---

### 5. 📍 Google Places API *(Address Autocomplete)*
**Service:** REST HTTP call to `maps.googleapis.com`
**Package used:** `http: ^1.2.1`

**What it does:**
Powers the address search bar in "Add New Restroom" — as the user types, it shows real-time place suggestions limited to Thailand.

**Two endpoints used:**

**Step 1 — Autocomplete (suggestions while typing):**
```dart
final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
  'input': query,              // user's typed text
  'key': apiKey,               // from .env file
  'language': 'th',            // Thai language results
  'components': 'country:th',  // limit to Thailand
  'types': 'establishment',
});
final response = await http.get(uri);
// Returns list of place suggestions with placeId
```

**Step 2 — Place Details (get lat/lng after user selects a suggestion):**
```dart
final url = 'https://maps.googleapis.com/maps/api/place/details/json'
  '?place_id=$placeId&fields=geometry&key=$apiKey';
final response = await http.get(Uri.parse(url));
// Returns { geometry: { location: { lat, lng } } }
// → map camera moves to that location automatically
```

**User experience flow:**
1. User types address → debounce 350ms → fetch suggestions
2. User taps a suggestion → fetch lat/lng → map pin moves to exact location

---

### 6. 🧭 Google Directions API *(Navigation)*
**Service:** REST HTTP call to `maps.googleapis.com`
**Package used:** `http: ^1.2.1`

**What it does:**
When a user taps "Navigate" on a restroom, it draws a walking route from the user's current GPS location to the restroom, and shows estimated walking time and distance.

**How we use it:**

```dart
final url = 'https://maps.googleapis.com/maps/api/directions/json?'
  'origin=${userLat},${userLng}&'
  'destination=${restroomLat},${restroomLng}&'
  'mode=walking&'
  'key=$apiKey';

final response = await http.get(Uri.parse(url));
final data = json.decode(response.body);

// Extract route info
final leg = data['routes'][0]['legs'][0];
_distance = leg['distance']['text'];   // e.g. "1.2 km"
_duration = leg['duration']['text'];   // e.g. "15 mins"

// Decode polyline points and draw on map
_polylineCoordinates = _decodePolyline(
  data['routes'][0]['overview_polyline']['points']
);
```

The encoded polyline string is decoded using a custom `_decodePolyline()` function that converts Google's compressed format into a `List<LatLng>` points for the map's `Polyline` widget.

---

### 7. 📡 Geolocator
**Package:** `geolocator: ^14.0.2`

**What it does:**
Gets the device's current GPS coordinates — used for centering the map on the user, calculating distances to restrooms, and as the starting point for navigation.

**How we use it:**

```dart
// Get current position
Position position = await Geolocator.getCurrentPosition(
  locationSettings: LocationSettings(accuracy: LocationAccuracy.high)
);

// Calculate distance between user and restroom
double distanceInMeters = Geolocator.distanceBetween(
  userLat, userLng, restroomLat, restroomLng
);
// Displayed as "450 m" or "2.3 km" on cards and detail page
```

---

### 8. 🖼️ Image Picker
**Package:** `image_picker: ^1.0.7`

**What it does:**
Lets users pick photos from their camera or gallery — used in three places: writing reviews, adding a new restroom, and updating the profile photo.

**How we use it:**

```dart
final picked = await ImagePicker().pickImage(
  source: ImageSource.camera,  // or ImageSource.gallery
  imageQuality: 80,            // compress to reduce upload size
  maxWidth: 1200,
  maxHeight: 1200,
);
if (picked != null) {
  final file = File(picked.path);
  // upload to Firebase Storage
}
```

---

## 🗂️ Firebase Data Schema

### `users`
```
userId, displayName, email, role (user/admin),
points, totalReviews, totalAdded, totalHelpful,
reviewIds[], favoriteRestrooms[], photoUrl,
isBanned, suspendedUntil
```

### `restrooms`
```
restroomId, restroomName, address, latitude, longitude,
openTime, closeTime, is24hrs, isFree, price, phoneNumber,
amenities{}, photos[], reviewIds[],
avgRating, avgCleanliness, avgAvailability, avgAmenities, avgScent,
totalRatings, createdBy, createdAt, updatedBy, updatedAt
```

### `reviews`
```
reviewId, restroomId, reviewerId, reviewerName, reviewerPhotoUrl,
rating, cleanlinessRating, availabilityRating, amenitiesRating, smellRating,
amenitiesFound{}, comment, photos[],
totalLikes, helpfulCount, likedBy[],
createdAt, updatedAt, timestamp
```

### `requests`
```
requestId, userId, status (pending/approved/rejected),
restroom{}, adminId, createdAt
```

### `reports`
```
reportId, restroomId, restroomName, reviewId,
issueType, title, description, severity (low/medium/high),
reportedById, reportedByName, reportedByEmail, isAnonymous,
photos[], reviewed, createdAt
```

---

## 🎯 Points & Level System

| Action | Points Earned |
|--------|--------------|
| Write a review | +20 pts |
| Add a restroom (admin approved) | +50 pts |
| Review receives a Helpful vote | +5 pts |

| Level | Points Required | Badge |
|-------|----------------|-------|
| 1 | 0 – 99 | Newbie |
| 2 | 100 – 299 | Explorer |
| 3 | 300 – 599 | Reviewer |
| 4 | 600 – 999 | Expert |
| 5 | 1000+ | Restroom Legend |

---

## 📋 Feature Checklist

### User Features
- [x] Email/Password login & registration
- [x] Google Sign-In
- [x] Password reset via email
- [x] Map view with all restrooms + smart clustering
- [x] List view of restrooms
- [x] Restroom detail page (ratings, amenities, photos, reviews)
- [x] Write / edit / delete review with sub-ratings + photos
- [x] Review sorting (Recent, Highest, Lowest, Most Helpful)
- [x] Helpful vote on reviews
- [x] Full-screen photo gallery (swipe to browse)
- [x] Upload photos to restrooms and reviews
- [x] Save to Favorites
- [x] Add new restroom (map pin + address autocomplete + photo upload)
- [x] Navigate to restroom (live walking route on map)
- [x] Report issue on restroom
- [x] Profile page with stats, level, badge, review history
- [x] Edit profile (name, avatar)
- [x] Delete account
- [x] Ban / Suspension lock screen

### Admin Features
- [x] Dashboard with quick stats
- [x] Approve / Reject restroom requests
- [x] View and edit all restrooms
- [x] Manage user reports (mark reviewed / dismiss)
- [x] Delete review or restroom directly from report
- [x] Suspend user (1 / 3 / 7 / 30 days)
- [x] Ban user permanently
- [x] User management page

---

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry + auth routing
├── firebase_options.dart          # Firebase config
├── models/
│   ├── user_model.dart
│   ├── restroom_model.dart
│   ├── review_model.dart
│   ├── request_model.dart
│   └── report_model.dart
├── services/
│   ├── user_firestore.dart
│   ├── restroom_firestore.dart
│   ├── review_firestore.dart
│   ├── request_firestore.dart
│   ├── report_firestore.dart
│   └── location_service.dart
├── pages/
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── forget_password_page.dart
│   ├── user/
│   │   ├── user_homepage.dart          # Map + list view
│   │   ├── restroom_detail_page.dart
│   │   ├── write_review_page.dart
│   │   ├── add_new_restroom_page.dart
│   │   ├── navigation_page.dart        # Walking route
│   │   ├── report_issue_page.dart
│   │   ├── photo_gallery_page.dart
│   │   ├── profile_page.dart
│   │   └── profile_settings_page.dart
│   └── admin/
│       ├── admin_homepage.dart
│       ├── admin_request_page.dart
│       ├── admin_report_page.dart
│       ├── admin_total_toilets_page.dart
│       ├── admin_edit_toilet_page.dart
│       ├── admin_users_page.dart
│       └── admin_profile_page.dart
├── providers/
│   └── app_auth_provider.dart
├── widgets/                           # Reusable UI components
└── utils/                             # Colors, helpers, UI utilities
```

---

*CS342 — RestroomNearU | Flutter + Firebase | 2025*