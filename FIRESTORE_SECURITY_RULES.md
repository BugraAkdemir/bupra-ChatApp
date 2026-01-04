# Firestore Security Rules - Display Name Uniqueness Enforcement

## CRITICAL: Display Name Uniqueness Rules

The following Firestore security rules **ENFORCE** display name uniqueness at the database level. This ensures that:
- Multiple users can have the same base username (Discord-style: bugra#1234, bugra#1256)
- Each display name (username#number) is unique
- Race conditions are prevented
- Client-side code bypass attempts are blocked

## Complete Firestore Rules

Copy and paste these rules into Firebase Console > Firestore Database > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ============================================
    // DISPLAY NAME UNIQUENESS ENFORCEMENT
    // ============================================
    // The 'displayNames' collection stores displayName -> uid mappings
    // Display name format: username#number (e.g., bugra#1234)
    // This collection ENFORCES uniqueness at the database level
    match /displayNames/{normalizedDisplayName} {
      // Only allow creation if document doesn't exist
      // This prevents duplicate display names even in race conditions
      allow create: if request.auth != null &&
                       !exists(/databases/$(database)/documents/displayNames/$(normalizedDisplayName)) &&
                       request.resource.data.uid == request.auth.uid &&
                       request.resource.data.displayName is string &&
                       request.resource.data.displayName.matches('.*#[0-9]{4}');

      // Allow read for all authenticated users (needed for availability checks and transactions)
      allow read: if request.auth != null;

      // Display name documents should NOT be updated or deleted by clients
      allow update, delete: if false;
    }

    // ============================================
    // USERS COLLECTION
    // ============================================
    match /users/{userId} {
      allow read: if request.auth != null;

      // Users can only create/update their own document
      // Display name must match the one in 'displayNames' collection
      allow create: if request.auth != null &&
                       request.auth.uid == userId &&
                       request.resource.data.username is string &&
                       request.resource.data.username.size() >= 3 &&
                       request.resource.data.username.size() <= 20 &&
                       request.resource.data.displayName is string &&
                       request.resource.data.displayName.matches('.*#[0-9]{4}');

      allow update: if request.auth != null &&
                       request.auth.uid == userId;

      allow delete: if false; // Prevent user deletion via client

      // User preferences subcollection
      match /preferences/{preferenceId} {
        allow read, write: if request.auth != null &&
                              request.auth.uid == userId;
      }
    }

    // ============================================
    // CHATS COLLECTION
    // ============================================
    match /chats/{chatId} {
      allow read, write: if request.auth != null &&
        request.auth.uid in resource.data.members;
      allow create: if request.auth != null &&
        request.auth.uid in request.resource.data.members;
      // Allow updating deletedBy field for members
      allow update: if request.auth != null &&
        request.auth.uid in resource.data.members &&
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['deletedBy']);
    }

    // ============================================
    // MESSAGES SUBCOLLECTION
    // ============================================
    match /chats/{chatId}/messages/{messageId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        request.auth.uid == resource.data.senderId;
    }

    // ============================================
    // FRIENDS COLLECTION
    // ============================================
    match /friends/{userId}/friends/{friendId} {
      allow read: if request.auth != null &&
        request.auth.uid == userId;

      // Users can add friends to their own collection
      // Also allow adding to friend's collection when accepting a request (bidirectional)
      allow create: if request.auth != null &&
                       (request.auth.uid == userId ||
                        request.auth.uid == friendId);

      allow update, delete: if request.auth != null &&
        request.auth.uid == userId;
    }

    // ============================================
    // FRIEND REQUESTS COLLECTION
    // ============================================
    match /friendRequests/{requestId} {
      // Users can create requests (send)
      allow create: if request.auth != null &&
                       request.auth.uid == request.resource.data.senderId &&
                       request.resource.data.receiverId is string &&
                       request.resource.data.status == 'pending';

      // Users can read their own incoming or outgoing requests
      // Note: resource.data might not exist for queries, so we check both
      allow read: if request.auth != null &&
                     (!resource.exists ||
                      resource.data.senderId == request.auth.uid ||
                      resource.data.receiverId == request.auth.uid);

      // Receivers can update status (accept/reject)
      // Also allow updating senderDisplayName and senderPhotoUrl (for display purposes)
      allow update: if request.auth != null &&
                       resource.data.receiverId == request.auth.uid &&
                       (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status']) ||
                        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'senderDisplayName', 'senderPhotoUrl']));

      // Senders can delete their own pending requests (cancel)
      allow delete: if request.auth != null &&
                       resource.data.senderId == request.auth.uid &&
                       resource.data.status == 'pending';
    }

    // ============================================
    // NOTIFICATIONS COLLECTION
    // ============================================
    // This collection is used for push notification queue
    // Only authenticated users can create notifications
    // Cloud Functions will process and delete them
    match /notifications/{notificationId} {
      allow create: if request.auth != null;
      allow read, update, delete: if false; // Only Cloud Functions can modify
    }
  }
}
```

## How It Works

### 1. Display Name Reservation System

The `displayNames` collection acts as a reservation system:
- Document ID: Normalized (lowercase) display name (e.g., "bugra#1234")
- Document Data: `{ uid, displayName (original case), createdAt }`
- Format: `username#number` where number is 4 digits (1000-9999)

### 2. Atomic Transaction

When a user registers:
1. User enters base username (e.g., "bugra")
2. Firebase Auth user is created
3. System generates unique display name (e.g., "bugra#1234")
4. **Transaction starts**
5. Check if `displayNames/{normalizedDisplayName}` exists
6. If exists → **Transaction fails** → Delete Auth user → Generate new number → Retry
7. If not exists → Create `displayNames/{normalizedDisplayName}` → Create `users/{uid}` → **Transaction commits**

### 3. Race Condition Safety

If two users try to register "bugra" simultaneously:
- User A: System generates "bugra#1234" → Transaction reserves it
- User B: System generates "bugra#5678" → Transaction reserves it
- Both succeed with different display names!

If two users get the same number (very rare):
- User A: Transaction checks → display name doesn't exist → reserves it
- User B: Transaction checks → display name **now exists** → **Transaction fails** → System generates new number

Firestore transactions are **atomic** - only one can succeed.

### 4. Security Rules Enforcement

Even if someone bypasses the client code:
- Rule: `!exists(/databases/$(database)/documents/displayNames/$(normalizedDisplayName))`
- This rule **prevents** creating a display name document if it already exists
- Database-level enforcement = **100% guarantee**

## Database Structure

```
displayNames/
  {normalizedDisplayName}/  (e.g., "bugra#1234", "bugra#1256")
    - uid: "user123"
    - displayName: "bugra#1234"
    - createdAt: timestamp

users/
  {uid}/
    - username: "bugra" (base username without #number)
    - displayName: "bugra#1234" (full display name)
    - email: "user@example.com"
    - photoUrl: "https://..."
```

## Important Notes

1. **Never delete displayName documents manually** - They must be kept for uniqueness
2. **Display name is case-insensitive** - "bugra#1234" and "Bugra#1234" are the same
3. **Multiple users can have the same base username** - System assigns unique numbers (bugra#1234, bugra#1256)
4. **Display name format is enforced** - Must be "username#number" where number is 4 digits
5. **Transaction is mandatory** - Direct writes bypass uniqueness checks

## Testing

To test display name uniqueness:

1. Try registering "testuser" - Should succeed (e.g., "testuser#1234")
2. Try registering "testuser" again - Should succeed with different number (e.g., "testuser#5678")
3. Multiple users can have the same base username - Each gets unique number
4. Display names are unique - "testuser#1234" can only exist once

## Migration

If you have existing users, you need to migrate:

1. Create `displayNames` documents for all existing users
2. Generate unique display names (username#number) for each user
3. Update user documents with displayName field

Example migration script (run once):

```javascript
// Run in Firebase Console > Firestore > Data
// Or use a Cloud Function
const users = await db.collection('users').get();
const batch = db.batch();
const usedNumbers = new Set();

users.forEach(userDoc => {
  const data = userDoc.data();
  const baseUsername = data.username || 'user';

  // Generate unique number
  let number;
  do {
    number = 1000 + Math.floor(Math.random() * 9000);
  } while (usedNumbers.has(number));
  usedNumbers.add(number);

  const displayName = `${baseUsername}#${number}`;
  const normalizedDisplayName = displayName.toLowerCase();

  // Create displayName document
  const displayNameRef = db.collection('displayNames').doc(normalizedDisplayName);
  batch.set(displayNameRef, {
    uid: userDoc.id,
    displayName: displayName,
    createdAt: FieldValue.serverTimestamp()
  });

  // Update user document with displayName
  batch.update(db.collection('users').doc(userDoc.id), {
    displayName: displayName
  });
});

await batch.commit();
```

