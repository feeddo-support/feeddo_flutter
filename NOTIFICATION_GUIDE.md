# Feeddo In-App Notifications Guide

Instagram-style in-app notification system for displaying unread messages and real-time message updates.

## Features

- 🎨 **Instagram-style UI** - Sleek notification banner with slide-in animation
- 📬 **Unread Message Detection** - Shows notifications when init returns unread conversations
- ⚡ **Real-time Updates** - Automatic notifications when new messages arrive via WebSocket
- 🎯 **Tap to Open** - Tapping notification opens the conversation
- ✖️ **Dismissible** - Users can dismiss notifications manually
- ⏱️ **Auto-dismiss** - Notifications auto-hide after 5 seconds (configurable)
- 📱 **Queue Management** - Multiple notifications queue and show sequentially

## Quick Start

### 1. Initialize and Check for Unread Messages

```dart
import 'package:feeddo_flutter/feeddo_flutter.dart';

// Initialize Feeddo
final result = await Feeddo.init(
  apiKey: 'your-api-key',
  userName: 'John Doe',
  email: 'john@example.com',
);

// Show notification if there are unread messages
if (result.hasUnreadMessages) {
  Feeddo.showNotificationIfUnread(context);
}

// Or use the result directly
if (result.recentConversation != null && 
    result.recentConversation!.unreadMessages > 0) {
  print('You have ${result.recentConversation!.unreadMessages} unread messages');
  Feeddo.showNotificationIfUnread(context);
}
```

### 2. Enable Real-time Notifications

```dart
// Enable automatic notifications for incoming messages
Feeddo.enableNotifications(
  context,
  theme: FeeddoTheme.dark(),
  duration: Duration(seconds: 5), // How long to show each notification
);

// Later, when you want to disable them
Feeddo.disableNotifications();
```

### 3. Manual Notification Trigger

```dart
// Show notification for a specific conversation
final conversation = await Feeddo.getConversations();
Feeddo.showNotification(
  context,
  conversation.first,
  theme: FeeddoTheme.light(),
);
```

## Complete Integration Example

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  InitResult? _initResult;

  @override
  void initState() {
    super.initState();
    _initializeFeeddo();
  }

  Future<void> _initializeFeeddo() async {
    try {
      final result = await Feeddo.init(
        apiKey: 'your-api-key',
        userName: 'John Doe',
        email: 'john@example.com',
      );

      setState(() {
        _initResult = result;
      });

      // Show notification if there are unread messages
      // Use WidgetsBinding to ensure the context is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (result.hasUnreadMessages) {
          Feeddo.showNotificationIfUnread(context);
        }

        // Enable real-time notifications
        Feeddo.enableNotifications(context);
      });
    } catch (e) {
      print('Failed to initialize Feeddo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('My App'),
          actions: [
            // Show unread count badge
            if (_initResult?.hasUnreadMessages ?? false)
              IconButton(
                icon: Badge(
                  label: Text('${_initResult!.recentConversation!.unreadMessages}'),
                  child: Icon(Icons.chat),
                ),
                onPressed: () {
                  Feeddo.show(context);
                },
              )
            else
              IconButton(
                icon: Icon(Icons.chat),
                onPressed: () {
                  Feeddo.show(context);
                },
              ),
          ],
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Feeddo.show(context);
            },
            child: Text('Open Support'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    Feeddo.disableNotifications();
    Feeddo.clearNotifications();
    super.dispose();
  }
}
```

## API Reference

### InitResult

Returned by `Feeddo.init()`:

```dart
class InitResult {
  final String userId;
  final Conversation? recentConversation;
  bool get hasUnreadMessages; // Convenience getter
}
```

### Notification Methods

#### showNotificationIfUnread

Shows a notification if the recent conversation has unread messages.

```dart
static void showNotificationIfUnread(
  BuildContext context, {
  FeeddoTheme? theme,
  Duration duration = const Duration(seconds: 5),
})
```

#### showNotification

Manually show a notification for any conversation.

```dart
static void showNotification(
  BuildContext context,
  Conversation conversation, {
  FeeddoTheme? theme,
  Duration duration = const Duration(seconds: 5),
})
```

#### enableNotifications

Enable automatic notifications for incoming WebSocket messages.

```dart
static void enableNotifications(
  BuildContext context, {
  FeeddoTheme? theme,
  Duration duration = const Duration(seconds: 5),
})
```

#### disableNotifications

Disable automatic notifications.

```dart
static void disableNotifications()
```

#### clearNotifications

Clear all visible and queued notifications.

```dart
static void clearNotifications()
```

### FeeddoNotificationManager

Direct access to notification management:

```dart
// Show notification
FeeddoNotificationManager.showNotification(
  context,
  conversation,
  theme: theme,
  duration: Duration(seconds: 5),
);

// Clear all notifications
FeeddoNotificationManager.clearAll();
```

## Customization

### Theme

```dart
Feeddo.showNotificationIfUnread(
  context,
  theme: FeeddoTheme(
    brightness: Brightness.light,
    colors: FeeddoColors(
      primary: Colors.blue,
      textPrimary: Colors.black,
      textSecondary: Colors.grey,
      // ... other colors
    ),
  ),
);
```

### Duration

```dart
// Show notification for 10 seconds
Feeddo.showNotificationIfUnread(
  context,
  duration: Duration(seconds: 10),
);
```

## Best Practices

1. **Initialize Early**: Call `Feeddo.init()` in your app's startup code
2. **Check Context**: Use `WidgetsBinding.instance.addPostFrameCallback` when showing notifications immediately after init
3. **Enable on App Launch**: Call `enableNotifications()` when your app starts to catch all incoming messages
4. **Disable on Dispose**: Always disable notifications when leaving your main screen
5. **Clear on Logout**: Call `clearNotifications()` when user logs out
6. **Handle Errors**: Wrap init in try-catch to handle network failures gracefully

## Troubleshooting

### Notifications not showing

- Ensure you have a valid `BuildContext` with an `Overlay`
- Check that `Feeddo.init()` completed successfully
- Verify the conversation has `unreadMessages > 0`

### Notifications showing multiple times

- Call `clearNotifications()` before showing new ones
- Disable notifications when navigating away from your screen

### WebSocket notifications not working

- Ensure you called `Feeddo.enableNotifications()`
- Check that WebSocket is connected (happens automatically when calling `Feeddo.show()`)
- Verify your API key and network connection

## Example: Chat Badge in AppBar

```dart
AppBar(
  title: Text('My App'),
  actions: [
    ValueListenableBuilder<int>(
      valueListenable: Feeddo.instance.conversationService,
      builder: (context, _, __) {
        final unreadCount = Feeddo.instance.conversationService.unreadMessageCount;
        return IconButton(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: Icon(Icons.chat),
          ),
          onPressed: () => Feeddo.show(context),
        );
      },
    ),
  ],
)
```

## See Also

- [Integration Guide](INTEGRATION.md)
- [Quick Start](QUICKSTART.md)
- [API Documentation](README.md)
