# Feeddo Flutter Integration Guide

Complete guide for integrating Feeddo Flutter SDK into your application.

## Installation

### 1. Add Dependency

Add to `pubspec.yaml`:

```yaml
dependencies:
  feeddo_flutter: ^0.0.1
```

Run:
```bash
flutter pub get
```

### 2. Import Package

```dart
import 'package:feeddo_flutter/feeddo_flutter.dart';
```

## Integration Patterns

### Pattern 1: Global Singleton (Recommended)

Create a global Feeddo instance for easy access throughout your app.

**lib/services/feeddo_service.dart**:
```dart
import 'package:feeddo_flutter/feeddo_flutter.dart';

class FeeddoService {
  static final FeeddoService _instance = FeeddoService._internal();
  late final FeeddoClient _client;

  factory FeeddoService() {
    return _instance;
  }

  FeeddoService._internal() {
    _client = FeeddoClient(
      appId: 'your-app-id',
      apiUrl: 'https://api.feeddo.dev',
    );
  }

  FeeddoClient get client => _client;

  void dispose() {
    _client.dispose();
  }
}

// Usage anywhere in your app:
// final feeddo = FeeddoService().client;
```

### Pattern 2: Provider Pattern

Use with `provider` package for dependency injection.

**lib/providers/feeddo_provider.dart**:
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feeddo_flutter/feeddo_flutter.dart';

class FeeddoProvider extends ChangeNotifier {
  late final FeeddoClient _client;
  String? _userId;

  FeeddoProvider({required String appId}) {
    _client = FeeddoClient(appId: appId);
  }

  String? get userId => _userId;

  Future<void> initializeUser({
    required String externalUserId,
    String? userName,
    String? email,
  }) async {
    _userId = await _client.initializeUser(
      externalUserId: externalUserId,
      userName: userName,
      email: email,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }
}

// In main.dart:
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => FeeddoProvider(appId: 'your-app-id'),
      child: MyApp(),
    ),
  );
}

// Usage in widgets:
final feeddo = Provider.of<FeeddoProvider>(context);
```

### Pattern 3: GetX Pattern

Use with GetX for state management.

```dart
import 'package:get/get.dart';
import 'package:feeddo_flutter/feeddo_flutter.dart';

class FeeddoController extends GetxController {
  late final FeeddoClient _client;
  final userId = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    _client = FeeddoClient(appId: 'your-app-id');
  }

  Future<void> initializeUser({
    required String externalUserId,
    String? userName,
    String? email,
  }) async {
    userId.value = await _client.initializeUser(
      externalUserId: externalUserId,
      userName: userName,
      email: email,
    );
  }

  @override
  void onClose() {
    _client.dispose();
    super.onClose();
  }
}

// In main.dart:
void main() {
  Get.put(FeeddoController());
  runApp(MyApp());
}

// Usage:
final feeddo = Get.find<FeeddoController>();
```

## Common Use Cases

### Use Case 1: Initialize on App Launch

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FeeddoClient _feeddo;

  @override
  void initState() {
    super.initState();
    _feeddo = FeeddoClient(appId: 'your-app-id');
    _initializeFeeddo();
  }

  Future<void> _initializeFeeddo() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('feeddo_user_id');

    try {
      final userId = await _feeddo.initializeUser(
        userId: storedUserId,
        externalUserId: 'your-user-id',
        userName: 'John Doe',
        email: 'john@example.com',
      );
      
      await prefs.setString('feeddo_user_id', userId);
    } catch (e) {
      print('Failed to initialize Feeddo: $e');
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
      home: HomeScreen(),
    );
  }
}
```

### Use Case 2: Update User on Login

```dart
Future<void> onUserLogin(User user) async {
  final feeddo = FeeddoClient(appId: 'your-app-id');
  
  try {
    await feeddo.initializeUser(
      externalUserId: user.id,
      userName: user.name,
      email: user.email,
      subscriptionStatus: user.isPremium ? 'premium' : 'free',
      customAttributes: {
        'loginMethod': 'email',
        'lastLogin': DateTime.now().toIso8601String(),
      },
    );
  } on FeeddoApiException catch (e) {
    print('Feeddo error: ${e.message}');
  }
}
```

### Use Case 3: Update User on Profile Change

```dart
Future<void> onProfileUpdated(UserProfile profile) async {
  final feeddo = FeeddoService().client;
  
  try {
    await feeddo.initializeUser(
      externalUserId: profile.id,
      userName: profile.displayName,
      email: profile.email,
      customAttributes: {
        'profileComplete': profile.isComplete,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
    );
  } catch (e) {
    print('Failed to update user: $e');
  }
}
```

### Use Case 4: Track Subscription Changes

```dart
Future<void> onSubscriptionChanged(String userId, String plan) async {
  final feeddo = FeeddoService().client;
  
  await feeddo.initializeUser(
    externalUserId: userId,
    subscriptionStatus: plan,
    customAttributes: {
      'subscriptionChangedAt': DateTime.now().toIso8601String(),
      'previousPlan': 'free',
      'newPlan': plan,
    },
  );
}
```

### Use Case 5: User Segmentation

```dart
Future<void> identifyUserSegment(User user) async {
  final feeddo = FeeddoService().client;
  
  String segment = 'regular';
  if (user.purchaseCount > 10) {
    segment = 'power-user';
  } else if (user.isPremium) {
    segment = 'premium';
  }
  
  await feeddo.initializeUser(
    externalUserId: user.id,
    userSegment: segment,
    customAttributes: {
      'purchaseCount': user.purchaseCount,
      'totalSpent': user.totalSpent,
      'accountAge': user.accountAgeDays,
    },
  );
}
```

## User ID Management

### Automatic User ID Management

The SDK automatically manages user IDs via SharedPreferences. You don't need to manually store or retrieve user IDs:

```dart
// First time - SDK creates user and saves ID automatically
final userId = await feeddo.initializeUser(
  externalUserId: 'user-123',
  userName: 'John Doe',
);

// Later - SDK automatically loads the saved ID
await feeddo.initializeUser(
  externalUserId: 'user-123',
  userName: 'Jane Doe',  // Updates existing user
);

// Clear user session when logging out
await feeddo.clearUser();
```

### For Authenticated Apps

```dart
Future<void> onUserLogin(AuthUser authUser) async {
  final feeddo = FeeddoService().client;
  
  await feeddo.initializeUser(
    externalUserId: authUser.uid,
    userName: authUser.displayName,
    email: authUser.email,
  );
}

Future<void> onUserLogout() async {
  final feeddo = FeeddoService().client;
  await feeddo.clearUser();
}
```

## Error Handling

### Comprehensive Error Handling

```dart
Future<void> safeUpsertUser() async {
  final feeddo = FeeddoClient(appId: 'your-app-id');
  
  try {
    final userId = await feeddo.initializeUser(
      userName: 'John Doe',
      email: 'john@example.com',
    );
    print('Success: $userId');
  } on FeeddoApiException catch (e) {
    // Handle API-specific errors
    print('API Error: ${e.message}');
    print('Status Code: ${e.statusCode}');
    print('Details: ${e.details}');
    
    // Show user-friendly message
    if (e.statusCode == 403) {
      showError('Access denied. Please check your app ID.');
    } else if (e.statusCode == 500) {
      showError('Server error. Please try again later.');
    } else {
      showError('Failed to initialize user: ${e.message}');
    }
  } on SocketException {
    // Handle network errors
    showError('No internet connection');
  } catch (e) {
    // Handle unexpected errors
    print('Unexpected error: $e');
    showError('An unexpected error occurred');
  }
}
```

## Testing

### Unit Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddo_flutter/feeddo_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('FeeddoClient', () {
    test('upsertEndUser returns userId', () async {
      // Mock HTTP client
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": true, "userId": "test-123", "action": "created"}',
          201,
        );
      });
      
      final feeddo = FeeddoClient(
        appId: 'test-app',
        apiUrl: 'https://api.test.com',
      );
      
      final userId = await feeddo.upsertEndUser(
        userName: 'Test User',
      );
      
      expect(userId, 'test-123');
    });
  });
}
```

## Performance Tips

1. **Initialize Once**: Create one FeeddoClient instance and reuse it
2. **Async Operations**: Always use async/await for API calls
3. **Error Handling**: Always wrap API calls in try-catch
4. **User ID Caching**: Store user ID locally to avoid unnecessary API calls
5. **Batch Updates**: Update user info when multiple fields change, not individually

## Troubleshooting

### Issue: "No internet connection"
- Check device connectivity
- Verify API URL is correct
- Check firewall/proxy settings

### Issue: "Access denied"
- Verify your app ID is correct
- Check if app exists in Feeddo dashboard
- Ensure API endpoint is accessible

### Issue: Device info not collected
- Ensure `autoCollectDeviceInfo` is set to `true` (default)
- Check platform-specific permissions if needed
- Verify device_info_plus and package_info_plus are installed

## Next Steps

1. Integrate chat widget (coming soon)
2. Set up push notifications for ticket updates
3. Configure custom user segments in Feeddo dashboard
4. Review analytics and user insights

## Support

- Documentation: https://docs.feeddo.dev
- Issues: https://github.com/feeddo/feeddo-flutter/issues
- Email: support@feeddo.dev
