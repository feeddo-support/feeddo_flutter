# Feeddo Flutter - Quick Start Guide

Get started with Feeddo Flutter SDK in 5 minutes.

## 1. Install (30 seconds)

Add to `pubspec.yaml`:

```yaml
dependencies:
  feeddo_flutter: ^0.0.1
```

Run:
```bash
flutter pub get
```

## 2. Initialize (1 minute)

In your main app file:

```dart
import 'package:feeddo_flutter/feeddo_flutter.dart';

class _MyAppState extends State<MyApp> {
  late final FeeddoClient feeddo;

  @override
  void initState() {
    super.initState();
    
    // Initialize Feeddo
    feeddo = FeeddoClient(appId: 'YOUR_APP_ID');
    
    // Initialize user
    _initUser();
  }

  Future<void> _initUser() async {
    try {
      await feeddo.initializeUser(
        externalUserId: 'user-123',  // Your user ID
        userName: 'John Doe',
        email: 'john@example.com',
      );
    } catch (e) {
      print('Feeddo init failed: $e');
    }
  }

  @override
  void dispose() {
    feeddo.dispose();
    super.dispose();
  }
}
```

## 3. That's It! 🎉

Feeddo will automatically collect:
- ✅ Device model
- ✅ OS version
- ✅ App version
- ✅ Platform (iOS/Android/Web)
- ✅ Locale and country
- ✅ User information you provide

## Common Tasks

### Update User Information

```dart
await feeddo.initializeUser(
  externalUserId: 'user-123',
  userName: 'New Name',
  subscriptionStatus: 'premium',
);
```

### Add Custom Attributes

```dart
await feeddo.initializeUser(
  externalUserId: 'user-123',
  userName: 'Jane',
  customAttributes: {
    'plan': 'pro',
    'company': 'Acme Corp',
  },
);
```

### Handle Errors

```dart
try {
  await feeddo.initializeUser(/*...*/);
} on FeeddoApiException catch (e) {
  print('API Error: ${e.message}');
} catch (e) {
  print('Error: $e');
}
```

## Next Steps

- 📖 Read [README.md](README.md) for full API reference
- 🔧 Check [INTEGRATION.md](INTEGRATION.md) for patterns and best practices
- 💻 Run the [example app](example/lib/main.dart) to see it in action

## Get Your App ID

Visit [feeddo.dev](https://feeddo.dev) to:
1. Create an account
2. Create your app
3. Copy your App ID
4. Replace `'YOUR_APP_ID'` in the code above

## Troubleshooting

**Q: "Target of URI doesn't exist" error**  
A: Run `flutter pub get` in your project directory

**Q: User not showing up in dashboard**  
A: Check your App ID is correct and app exists in Feeddo

**Q: Device info not collected**  
A: Make sure `autoCollectDeviceInfo: true` (it's the default)

## Support

- 📧 Email: support@feeddo.dev
- 📖 Docs: https://docs.feeddo.dev
- 🐛 Issues: GitHub issues

---

**Ready to go!** Your Flutter app now automatically tracks users with full device context. 🚀
