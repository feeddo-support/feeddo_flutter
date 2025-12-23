# Feeddo Flutter SDK

AI-powered customer support and feedback widget for Flutter applications. Automatically collects device information and manages end users.

## Features

✅ **End User Management**: Create and update end users with comprehensive information  
✅ **Automatic Device Info**: Auto-collects platform, device model, OS version, app version  
✅ **Backend User ID Management**: User IDs generated and managed by Feeddo backend  
✅ **Data Persistence**: All user data saved to SharedPreferences automatically  
✅ **Custom Attributes**: Store custom key-value pairs for user segmentation  
✅ **Cross-Platform**: Works on iOS, Android, Web, macOS, Windows, Linux  
✅ **Type Safe**: Full TypeScript-like type safety with Dart  
✅ **Geo Detection**: Country and locale automatically detected from IP address by backend  

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  feeddo_flutter: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize Feeddo Client

```dart
import 'package:feeddo_flutter/feeddo_flutter.dart';

// Initialize the client with your app ID
final feeddo = FeeddoClient(
  appId: 'your-app-id',
  // apiUrl: 'https://api.feeddo.dev', // Optional: custom API URL
);
```

### 2. Initialize User on App Launch

```dart
// On app launch or user login - creates new user or loads existing
final userId = await feeddo.initializeUser(
  externalUserId: 'user-123',  // Your system's user ID
  userName: 'John Doe',
  email: 'john@example.com',
  subscriptionStatus: 'premium',
  customAttributes: {
    'plan': 'pro',
    'signupDate': '2024-01-01',
  },
);

print('User initialized: $userId');
```

### 3. Update User Information

```dart
// When user updates their profile - just call initializeUser again
await feeddo.initializeUser(
  externalUserId: 'user-123',
  userName: 'John Smith',  // Updated name
  subscriptionStatus: 'premium',
  customAttributes: {
    'plan': 'enterprise',  // Updated plan
  },
);
```

## API Reference

### FeeddoClient

Main client for interacting with Feeddo services.

#### Constructor

```dart
FeeddoClient({
  required String appId,        // Your Feeddo app ID
  String apiUrl = 'https://api.feeddo.dev',  // API base URL
})
```

#### Methods

##### initializeUser()

Initialize or update a user session. Automatically collects device information and manages user ID via SharedPreferences.

```dart
Future<String> initializeUser({
  String? externalUserId,                  // Your system's user ID
  String? userName,                        // User's display name
  String? email,                          // User's email
  String? userSegment,                    // Custom user segment
  String? subscriptionStatus,             // Subscription status
  Map<String, dynamic>? customAttributes, // Custom data
})
```

**Returns**: User ID (String)

**Behavior**: 
- First call: Creates new user, backend generates ID, saves to SharedPreferences
- Subsequent calls: Loads ID from SharedPreferences, updates user data
- User ID is automatically managed - no need to store it yourself

**Example**:
```dart
// First call - creates user
final userId = await feeddo.initializeUser(
  externalUserId: 'user-456',
  userName: 'Jane Doe',
  email: 'jane@example.com',
);

// Later - updates user (reuses stored ID)
await feeddo.initializeUser(
  externalUserId: 'user-456',
  userName: 'Jane Smith',  // Updated
);
```

##### clearUser()

Clear the current user session and remove from SharedPreferences.

```dart
Future<void> clearUser()
```

**Throws**: `StateError` if no user is initialized

**Example**:
```dart
await feeddo.clearUser();
print('User session cleared');
```

## Automatically Collected Information

The SDK automatically collects device information:

| Field | Description | Example |
|-------|-------------|---------|
| `platform` | Platform type | `ios`, `android`, `web`, `desktop` |
| `deviceModel` | Device model | `iPhone 14`, `Pixel 7`, `macOS MacBookPro` |
| `osVersion` | OS version | `iOS 17.0`, `Android 13 (SDK 33)` |
| `appVersion` | Your app version | `1.2.3` |

**Note**: `country` and `locale` are automatically detected by the backend from the user's IP address, so you don't need to collect them manually.

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:feeddo_flutter/feeddo_flutter.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FeeddoClient _feeddo;

  @override
  void initState() {
    super.initState();
    
    // Initialize Feeddo
    _feeddo = FeeddoClient(appId: 'your-app-id');
    
    // Initialize user
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      final userId = await _feeddo.initializeUser(
        externalUserId: 'user-123',
        userName: 'John Doe',
        email: 'john@example.com',
        subscriptionStatus: 'free',
        customAttributes: {
          'signupDate': DateTime.now().toIso8601String(),
        },
      );
      print('User initialized: $userId');
    } on FeeddoApiException catch (e) {
      print('Failed to initialize user: ${e.message}');
    }
  }

  @override
  void dispose() {
    _feeddo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('My App')),
        body: Center(child: Text('Hello Feeddo!')),
      ),
    );
  }
}
```

## Best Practices

### 1. Initialize Early

Initialize the user as early as possible in your app lifecycle.

### 2. Persist User ID

Store the user ID locally for subsequent app launches using SharedPreferences or similar.

### 3. Update on Profile Changes

Update user info when they modify their profile.

### 4. Handle Errors Gracefully

Always handle API errors with try-catch blocks.

### 5. Custom Attributes for Segmentation

Use custom attributes for user segmentation and analytics.

## File Structure

```
feeddo_flutter/
├── lib/
│   ├── feeddo_flutter.dart              # Main entry point
│   └── src/
│       ├── feeddo_client.dart           # Main client class
│       ├── models/
│       │   └── end_user.dart            # EndUser model
│       ├── services/
│       │   └── api_service.dart         # API service
│       └── utils/
│           └── device_info_helper.dart  # Device info helper
├── example/
│   └── lib/
│       └── main.dart                    # Example app
└── README.md
```

## Platform Support

| Platform | Supported | Auto Device Info |
|----------|-----------|------------------|
| iOS | ✅ Yes | ✅ Yes |
| Android | ✅ Yes | ✅ Yes |
| Web | ✅ Yes | ✅ Yes |
| macOS | ✅ Yes | ✅ Yes |
| Windows | ✅ Yes | ✅ Yes |
| Linux | ✅ Yes | ✅ Yes |

## Dependencies

- `http`: ^1.2.0 - HTTP client
- `device_info_plus`: ^10.1.0 - Device information
- `package_info_plus`: ^8.0.0 - Package/app information

## License

See LICENSE file.

## Support

For issues and questions, visit [feeddo.dev](https://feeddo.dev)
