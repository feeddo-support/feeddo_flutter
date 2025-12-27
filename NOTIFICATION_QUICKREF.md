# Feeddo Notifications - Quick Reference

## Basic Setup (1 line of code!)

```dart
final result = await Feeddo.init(apiKey: 'your-key', context: context);
```

That's it! Notifications are automatically enabled and shown.

## Without Notifications

```dart
// Just omit the context parameter
final result = await Feeddo.init(apiKey: 'your-key');
```

## Disable Notifications

```dart
final result = await Feeddo.init(
  apiKey: 'your-key',
  context: context,
  isInAppNotificationOn: false, // Disable even with context
);
```

## API Methods

| Method | Purpose | Parameters |
|--------|---------|------------|
| `Feeddo.init()` | Initialize SDK with automatic notifications | `apiKey`, `context?`, `isInAppNotificationOn?`, `theme?`, user data... |
| `Feeddo.dispose()` | Clean up and reset Feeddo instance | - |
| `FeeddoNotificationManager.showNotification()` | Manually show notification | `context`, `conversation`, `theme?`, `duration?` |
| `FeeddoNotificationManager.clearAll()` | Clear all notifications | - |

## InitResult Properties

```dart
InitResult result = await Feeddo.init(...);

result.userId              // String: The user ID
result.recentConversation  // Conversation?: Recent conversation (if any)
result.hasUnreadMessages   // bool: True if unread count > 0
```

## Conversation Model

```dart
Conversation {
  String id;
  String? displayName;      // Sender name
  String? lastMessagePreview;
  int unreadMessages;       // Unread count
  // ... other fields
}
```

## Common Patterns

### Pattern 1: With Notifications (Default)
```dart
void initState() {
  super.initState();
  _initializeFeeddo();
}

Future<void> _initializeFeeddo() async {
  final result = await Feeddo.init(
    apiKey: 'your-key',
    context: context,
    userName: 'John Doe',
    // isInAppNotificationOn is true by default
  );
  setState(() => initResult = result);
}
```

### Pattern 2: Without Notifications
```dart
final result = await Feeddo.init(
  apiKey: 'your-key',
  userName: 'John Doe',
  // No context = no notifications
);
```

### Pattern 3: Disable Notifications
```dart
final result = await Feeddo.init(
  apiKey: 'your-key',
  context: context,
  isInAppNotificationOn: false,
);
```

### Pattern 4: Custom Theme
```dart
final result = await Feeddo.init(
  apiKey: 'your-key',
  context: context,
  theme: FeeddoTheme.light(), // or custom theme
);
```

### Pattern 2: AppBar Badge
```dart
AppBar(
  actions: [
    IconButton(
      icon: Badge(
        isLabelVisible: initResult.hasUnreadMessages,
        label: Text('${initResult.recentConversation?.unreadMessages}'),
        child: Icon(Icons.chat),
      ),
      onPressed: () => Feeddo.show(context),
    ),
  ],
)
```

### Pattern 4: Clean Up on Logout
```dart
@override
void dispose() {
  Feeddo.dispose(); // Cleans up everything
  super.dispose();
}
```

## Theming

### Dark Theme (Default)
```dart
await Feeddo.init(
  apiKey: 'your-key',
  context: context,
  theme: FeeddoTheme.dark(), // This is the default
);
```

### Light Theme
```dart
await Feeddo.init(
  apiKey: 'your-key',
  context: context,
  theme: FeeddoTheme.light(),
);
```

### Custom Theme
```dart
await Feeddo.init(
  apiKey: 'your-key',
  context: context,
  theme: FeeddoTheme(
    isDark: true,
    colors: FeeddoColors(
      primary: Colors.purple,
      textPrimary: Colors.white,
      // ... other colors
    ),
  ),
);
```

## Manual Operations (Advanced)

### Show Notification Manually
```dart
FeeddoNotificationManager.showNotification(
  context,
  conversation,
  theme: FeeddoTheme.dark(),
  duration: Duration(seconds: 5),
);
```

### Clear All Notifications
```dart
FeeddoNotificationManager.clearAll();
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Notification not showing | Check `initResult.hasUnreadMessages` |
| Multiple notifications overlapping | They queue automatically, check duration |
| WebSocket notifications not working | Call `enableNotifications()` |
| Notification persists after navigation | Call `clearNotifications()` |
| Context errors | Use `WidgetsBinding.instance.addPostFrameCallback` |

## Best Practices

1. ✅ Pass `context` to `Feeddo.init()` to enable automatic notifications
2. ✅ Omit `context` if you don't want notifications
3. ✅ Set `isInAppNotificationOn: false` to disable notifications even with context
4. ✅ Call `Feeddo.dispose()` on logout to clean up
5. ✅ Use `theme` parameter in init for consistent theming
6. ❌ Don't call init multiple times without disposing first
7. ❌ Don't manually manage notifications unless you have specific needs

## Example: Complete Integration

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  InitResult? initResult;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final result = await Feeddo.init(apiKey: 'your-key');
    setState(() => initResult = result);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (result.hasUnreadMessages) {
        Feeddo.showNotificationIfUnread(context);
      }
      Feeddo.enableNotifications(context);
    });
  }

  @override
  void dispose() {
    Feeddo.disableNotifications();
    Feeddo.clearNotifications();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('My App'),
          actions: [
            if (initResult?.hasUnreadMessages ?? false)
              IconButton(
                icon: Badge(
                  label: Text('${initResult!.recentConversation!.unreadMessages}'),
                  child: Icon(Icons.chat),
                ),
                onPressed: () => Feeddo.show(context),
              ),
          ],
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Feeddo.show(context),
            child: Text('Support'),
          ),
        ),
      ),
    );
  }
}
```

## See Also

- [NOTIFICATION_GUIDE.md](NOTIFICATION_GUIDE.md) - Complete guide
- [NOTIFICATION_IMPLEMENTATION.md](NOTIFICATION_IMPLEMENTATION.md) - Technical details
- [example/lib/notification_example.dart](example/lib/notification_example.dart) - Working example
