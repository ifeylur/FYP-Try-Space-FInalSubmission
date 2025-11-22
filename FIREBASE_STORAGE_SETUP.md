# Firebase Storage Setup Guide

## Issue: Firebase Storage 404 Errors

If you're seeing `StorageException: Object does not exist at location` (404 errors), it means Firebase Storage is not properly configured.

## Solution Steps:

### 1. Enable Firebase Storage in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Storage** in the left sidebar
4. Click **Get Started** if Storage is not enabled
5. Choose your storage location (same as Firestore is recommended)
6. Start in **test mode** for development (you can secure it later)

### 2. Configure Storage Security Rules

In Firebase Console → Storage → Rules, use these rules for development:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      // Allow authenticated users to read/write their own files
      allow read, write: if request.auth != null 
        && request.resource.size < 5 * 1024 * 1024  // 5MB limit
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

For production, use more restrictive rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.size < 2 * 1024 * 1024  // 2MB limit
        && request.resource.contentType.matches('image/.*');
    }
  }
}
```

### 3. Verify Firebase Configuration

Make sure your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are properly configured with the correct Storage bucket URL.

### 4. App Check (Optional but Recommended)

The warning about "No AppCheckProvider installed" is not critical but you can enable App Check for better security:

1. In Firebase Console → App Check
2. Register your app
3. Add App Check to your Flutter app (requires additional setup)

### 5. Fallback Behavior

The app includes a fallback mechanism: if Firebase Storage upload fails, it will automatically use base64 encoding to store the image in Firestore. This ensures the app continues to work even if Storage is not configured.

## Testing

After configuring Storage:

1. Try uploading a profile image
2. Check Firebase Console → Storage to see if files appear
3. Check the app logs for any remaining errors

## Common Issues:

- **404 Error**: Storage bucket doesn't exist or rules are blocking access
- **403 Error**: Security rules are too restrictive
- **Network Error**: Check internet connection and Firebase project configuration

