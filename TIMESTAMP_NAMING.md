# Timestamp Naming Convention Guide

## ✅ Correct Naming

### Standard Timestamp Fields (Use These!)

```dart
final DateTime createdAt;      // ✅ When the record was created
final DateTime updatedAt;      // ✅ When the record was last modified
final DateTime deletedAt;      // ✅ When the record was soft-deleted (optional)
```

### With User Tracking

```dart
final DateTime createdAt;
final String createdBy;        // ✅ User ID who created
final DateTime updatedAt;
final String updatedBy;        // ✅ User ID who last updated
```

## ❌ Incorrect Naming

```dart
final DateTime creationTimestamp;    // ❌ Too verbose
final DateTime updationTimestamp;    // ❌ "Updation" is not proper English
final DateTime updateTimestamp;      // ❌ Inconsistent with "createdAt"
final DateTime created;              // ❌ Not clear it's a timestamp
final DateTime modified;             // ❌ Use "updatedAt" instead
```

## 📚 Why "updatedAt" not "updation"?

### English Grammar:
- **Create** → **Creation** (noun)
- **Update** → **Update** (noun - same word!)
- **Delete** → **Deletion** (noun)

"Updation" is not a standard English word. The correct noun form of "update" is simply **"update"**.

However, for timestamp fields, we use the **past participle + "At"** pattern:
- **Created** + **At** = `createdAt`
- **Updated** + **At** = `updatedAt`
- **Deleted** + **At** = `deletedAt`

## 🌐 Industry Standards

### Firebase / Firestore
```javascript
{
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### MongoDB
```javascript
{
  createdAt: Date,
  updatedAt: Date
}
```

### PostgreSQL / MySQL
```sql
created_at TIMESTAMP
updated_at TIMESTAMP
```

### REST APIs (ISO 8601)
```json
{
  "createdAt": "2024-02-14T10:30:00Z",
  "updatedAt": "2024-02-15T14:45:00Z"
}
```

## 🎯 Complete Model Examples

### Basic Model
```dart
class RestroomModel {
  final String id;
  final String name;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  
  RestroomModel({
    required this.id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();
}
```

### Advanced Model (with user tracking)
```dart
class RestroomModel {
  final String id;
  final String name;
  
  // Timestamps with user tracking
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  
  RestroomModel({
    required this.id,
    required this.name,
    DateTime? createdAt,
    required this.createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    updatedBy = updatedBy ?? createdBy;
}
```

### Full Model (with soft delete)
```dart
class RestroomModel {
  final String id;
  final String name;
  
  // Full timestamp tracking
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;
  final String? deletedBy;
  
  // Helper getters
  bool get isDeleted => deletedAt != null;
  bool get isModified => updatedAt.isAfter(
    createdAt.add(const Duration(seconds: 1))
  );
}
```

## 🔄 Naming Conventions Across Languages

### Dart/Flutter (camelCase)
```dart
createdAt
updatedAt
deletedAt
```

### Database (snake_case)
```sql
created_at
updated_at
deleted_at
```

### JSON API (camelCase)
```json
{
  "createdAt": "2024-02-14T10:30:00Z",
  "updatedAt": "2024-02-15T14:45:00Z"
}
```

### GraphQL (camelCase)
```graphql
type Restroom {
  id: ID!
  name: String!
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

## 📋 Migration Checklist

If you have existing code with incorrect naming:

### Step 1: Update Models
```dart
// Before
final DateTime creationDate;
final DateTime modificationDate;

// After
final DateTime createdAt;
final DateTime updatedAt;
```

### Step 2: Update Firebase Fields
```dart
// In toMap()
'createdAt': Timestamp.fromDate(createdAt),
'updatedAt': Timestamp.fromDate(updatedAt),
```

### Step 3: Update fromMap()
```dart
// In fromMap()
createdAt: (map['createdAt'] as Timestamp).toDate(),
updatedAt: (map['updatedAt'] as Timestamp).toDate(),
```

### Step 4: Database Migration (if needed)
```sql
-- Rename columns in database
ALTER TABLE restrooms 
  RENAME COLUMN creation_date TO created_at;
  
ALTER TABLE restrooms 
  RENAME COLUMN modification_date TO updated_at;
```

## 💡 Best Practices

### 1. Auto-Set Timestamps
```dart
// In constructor
createdAt = createdAt ?? DateTime.now(),
updatedAt = updatedAt ?? DateTime.now()
```

### 2. Use copyWith for Updates
```dart
RestroomModel copyWith({
  String? name,
  DateTime? updatedAt,
}) {
  return RestroomModel(
    // ... other fields
    createdAt: this.createdAt,        // Never change
    updatedAt: updatedAt ?? DateTime.now(), // Auto-update
  );
}
```

### 3. Firebase Server Timestamp (Production)
```dart
// Use FieldValue.serverTimestamp() in production
Map<String, dynamic> toMap() {
  return {
    'name': name,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
```

### 4. Helper Methods
```dart
// Check if modified
bool get isModified => updatedAt.isAfter(
  createdAt.add(const Duration(seconds: 5))
);

// Get age
Duration get age => DateTime.now().difference(createdAt);

// Format display
String get createdAtFormatted => 
  DateFormat('MMM dd, yyyy').format(createdAt);
```

## 🎓 Summary

### ✅ Use This:
- `createdAt` / `created_at`
- `updatedAt` / `updated_at`
- `deletedAt` / `deleted_at`

### ❌ Don't Use This:
- `creationTimestamp` (too verbose)
- `updationTimestamp` (incorrect English)
- `updateTimestamp` (inconsistent)
- `modified` (ambiguous)

### 🌟 Golden Rule:
**Use the past participle + "At" pattern for all timestamp fields!**

---

**Updated Models:**
- ✅ `restroom_model.dart` - Now uses `createdAt` and `updatedAt`
- ✅ `review_model.dart` - Now uses `createdAt` and `updatedAt`
- ✅ Mock services updated with proper timestamps
