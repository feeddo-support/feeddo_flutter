# Feeddo Flutter SDK

Drop a live AI support chat into your Flutter app with just 2 lines of code.

## What is Feeddo?

Feeddo is an AI-powered customer support widget for your Flutter app. Here's what it does:

- **AI Agent** handles simple questions by reading your docs and FAQs
- **Auto-creates support tickets** when the AI can't solve the issue
- **Live chat** - You can jump in and chat directly with users
- **Smart bug tracking** - Auto-detects and creates issues for bug reports
- **Feature requests** - Captures and organizes feature requests from users
- **Community board** - Let users vote on feature requests and see known bugs

All this drops right into your app with zero hassle.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  feeddo_flutter: ^0.0.5
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Get Your API Key

Sign up at [feeddo.dev](https://feeddo.dev) and grab your API key from the dashboard.

### 2. Initialize Feeddo

Call `Feeddo.init()` when your app starts (usually in your main screen):

```dart
import 'package:feeddo_flutter/feeddo_flutter.dart';

await Feeddo.init(
      apiKey: 'your-api-key-here',  // Get this from feeddo.dev
      context: context,
    );
```

### 3. Show the Support Chat

Add a button anywhere in your app to open the support widget:

```dart
ElevatedButton(
  onPressed: () {
    Feeddo.show(context);  // Opens the support home screen
  },
  child: Text('Get Help'),
)
```

That's it! Your users can now chat with the AI and create support tickets.

### 4. Show the Community Board

Want to show just the feature requests and bug reports? Use this:

```dart
ElevatedButton(
  onPressed: () {
    Feeddo.showCommunityBoard(context);  // Opens feature requests & bugs
  },
  child: Text('Request a feature'),
)
```

## Understanding `Feeddo.init()`

The `init()` method sets up Feeddo with your user data. Here's what each parameter does:

```dart
await Feeddo.init(
  // Required: Your API key from feeddo.dev
  apiKey: 'your-api-key',
  
  // Required: The BuildContext for showing notifications
  context: context,
  
  // Optional: Your app's user ID (links Feeddo to your users)
  externalUserId: 'user_12345',
  
  // Optional: User's display name (appears in chats)
  userName: 'John Doe',
  
  // Optional: User's email
  email: 'john@example.com',
  
  // Optional: Segment your users (e.g., 'pro', 'free', 'trial')
  userSegment: 'premium',
  
  // Optional: Track subscription status
  subscriptionStatus: 'active',
  
  // Optional: Any extra data you want to track
  customAttributes: {
    'plan': 'pro',
    'signupDate': '2026-01-01',
    'country': 'US',
  },
  
  // Optional: Enable/disable in-app notifications (default: true)
  isInAppNotificationOn: true,
  
  // Optional: Push notification token (for remote notifications)
  pushToken: 'fcm-token-here',
  
  // Optional: Push provider (fcm, apns, or onesignal)
  pushProvider: FeeddoPushProvider.fcm,
);
```

**Returns:** The `userId` that Feeddo created for this user.

## Notifications Setup

Feeddo has two types of notifications:

### 1. In-App Notifications (Automatic)

When someone replies to your user's message, a notification slides down from the top of the screen. This works automatically if you set `context` in `init()`.

```dart
await Feeddo.init(
  apiKey: 'your-api-key',
  context: context,  // This enables in-app notifications
  isInAppNotificationOn: true,  // Default is true
);
```

To turn off in-app notifications:

```dart
await Feeddo.init(
  apiKey: 'your-api-key',
  context: context,
  isInAppNotificationOn: false,  // No in-app notifications
);
```

### 2. Push Notifications (Optional)

If you haven't set up push notifications in your app yet, please follow the [Firebase Cloud Messaging Get Started guide](https://firebase.google.com/docs/cloud-messaging/flutter/get-started) to configure your project.

To get notifications even when the app is closed, register your push token:

```dart
// When you get the FCM token
await Feeddo.registerPushToken(
  pushToken: 'your-push-token',
  pushProvider: FeeddoPushProvider.fcm,  // or .apns, .onesignal
);
```

Or pass it directly to `init()`:

```dart
await Feeddo.init(
  apiKey: 'your-api-key',
  context: context,
  pushToken: 'your-push-token',
  pushProvider: FeeddoPushProvider.fcm,
);
```

When a push notification arrives, handle it like this:

```dart
// Handle notification tap when app is in background/terminated
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  Feeddo.handleNotificationTap(context, message.data);
});

// Handle notification when app is in foreground
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  Feeddo.showInappNotification(
    context: context,
    title: message.notification?.title ?? 'New Message',
    message: message.notification?.body ?? '',
    data: message.data,
  );
});
```

## Customizing Colors

Feeddo comes with dark and light themes, but you can customize any color:

### Using Built-in Themes

```dart
// Dark theme (default)
Feeddo.show(context, theme: FeeddoTheme.dark());

// Light theme
Feeddo.show(context, theme: FeeddoTheme.light());
```

### Custom Colors

Create your own theme by customizing colors:

```dart
final myTheme = FeeddoTheme(
  isDark: true,
  colors: FeeddoColors(
    // Main background
    background: Color(0xFF1A1A2E),
    
    // Text colors
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B0B0),
    
    // Primary action color (buttons, links)
    primary: Color(0xFF00D9FF),
    
    // Cards and surfaces
    cardBackground: Color(0xFF252540),
    surface: Color(0xFF252540),
    
    // App bar
    appBarBackground: Color(0xFF1A1A2E),
    
    // Status colors
    success: Color(0xFF4CAF50),
    error: Color(0xFFFF5252),
    
    // Borders and dividers
    border: Color(0xFF3A3A5C),
    divider: Color(0xFF2A2A3E),
  ),
);

// Use it when showing Feeddo
Feeddo.show(context, theme: myTheme);
```

You can also apply the theme to notifications and the community board:

```dart
// Show with custom theme
Feeddo.show(context, theme: myTheme);
Feeddo.showCommunityBoard(context, theme: myTheme);

// Set default theme in init()
await Feeddo.init(
  apiKey: 'your-api-key',
  context: context,
  theme: myTheme,  // This theme will be used for notifications
);
```

### Available Colors

| Color Property | What it controls |
|----------------|------------------|
| `background` | Main screen background |
| `textPrimary` | Primary text (titles, main content) |
| `textSecondary` | Secondary text (timestamps, hints) |
| `cardBackground` | Background of cards and message bubbles |
| `primary` | Primary buttons, links, active elements |
| `surface` | Secondary surfaces (bottom sheets) |
| `success` | Success states, completed tasks |
| `error` | Error states, urgent notifications |
| `border` | Borders around inputs and cards |
| `divider` | Separators between items |
| `appBarBackground` | Top navigation bar background |

### Gradient Background

Want a gradient background? Easy:

```dart
final gradientTheme = FeeddoTheme(
  isDark: true,
  colors: FeeddoColors(
    background: Color(0xFF1A1A2E),  // Fallback color
    backgroundGradient: [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
    ],
  ),
);
```

## Update User Info

Need to update user info after they sign up or change their profile?

```dart
await Feeddo.updateUser(
  userName: 'Jane Smith',
  email: 'jane@example.com',
  userSegment: 'enterprise',
);
```

## Show Unread Message Count

Want to show a badge with unread messages?

```dart
int unreadCount = Feeddo.unreadMessageCount;

// Use it in your UI
Badge(
  label: Text('$unreadCount'),
  child: Icon(Icons.chat),
)
```

## Need Help?

- **Docs:** [docs.feeddo.dev](https://docs.feeddo.dev)
- **Website:** [feeddo.dev](https://feeddo.dev)
- **Issues:** [GitHub Issues](https://github.com/feeddo/feeddo-flutter/issues)

## License

MIT License - see LICENSE file for details
