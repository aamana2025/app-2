# Access Token Usage

This document explains how the access token is automatically handled in the Flutter app.

## How It Works

1. **Login Response**: When a user logs in successfully, the API returns an `accessToken` in the response:
   ```json
   {
     "message": "Login successful",
     "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
     "user": {
       "id": "68caf59ea25f252e69145a42",
       "name": "fares mohamed",
       "email": "fares.dev.m@gmail.com",
       // ... other user data
     }
   }
   ```

2. **Automatic Token Setting**: The `AuthProvider` automatically extracts the `accessToken` and sets it in the `ApiService`:
   ```dart
   // In AuthProvider.login()
   if (response['accessToken'] != null && response['user'] != null) {
     _token = response['accessToken'];
     _user = response['user'];
     _isAuthenticated = true;
     
     // Make token available for all API calls by default
     _apiService.setAccessToken(_token);
   }
   ```

3. **Automatic Header Inclusion**: All API calls automatically include the token in the Authorization header:
   ```dart
   // In ApiService._buildHeaders()
   Map<String, String> _buildHeaders({String? accessToken, bool json = true}) {
     final effectiveToken = (accessToken != null && accessToken.isNotEmpty)
         ? accessToken
         : (_accessToken ?? '');
     
     return <String, String>{
       if (json) 'Content-Type': 'application/json',
       if (effectiveToken.isNotEmpty) 'Authorization': 'Bearer $effectiveToken',
     };
   }
   ```

## API Methods That Use the Token

All API methods automatically include the access token when available:

- `getClassFiles()` - Get files for a class
- `getClassNotes()` - Get notes for a class  
- `getStudentClasses()` - Get student's joined classes
- `joinClass()` - Join a class
- `getUserSubscriptionStatus()` - Get subscription status
- `getClassTasks()` - Get class tasks/exams
- `updateUserProfile()` - Update user profile
- `getPlanDetails()` - Get plan details
- `getUserProfile()` - Get user profile
- `getStudentData()` - Get unified student data
- `submitTaskSolution()` - Submit task solution
- And many more...

## Example Usage

```dart
// After successful login, the token is automatically set
final authProvider = Provider.of<AuthProvider>(context, listen: false);
await authProvider.login(email: email, password: password);

// All API calls now automatically include the token
final classes = await authProvider.getStudentClasses();
final files = await apiService.getClassFiles(classId: 'class123');
```

## Token Persistence

The access token is automatically:
- Saved to secure storage when login is successful
- Restored from storage when the app starts
- Set in the API service when restored
- Cleared when the user logs out

## Debugging

You can verify the token is working by calling:
```dart
// Check if token is set
bool hasToken = authProvider.verifyAccessToken();

// Test API call with current token
Map<String, dynamic> result = await authProvider.testApiWithToken();
```

## Manual Token Override

If you need to use a different token for a specific API call, you can pass it as a parameter:
```dart
final files = await apiService.getClassFiles(
  classId: 'class123',
  accessToken: 'different_token_here', // This will override the default token
);
```

## Security Notes

- The token is stored securely using Flutter Secure Storage
- Token is only included in HTTPS requests
- Token is automatically cleared on logout
- Token preview is logged for debugging (first 20 characters only)
