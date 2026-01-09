import 'package:flutter/material.dart';
import 'package:feeddo_flutter/feeddo_flutter.dart';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');
    print('Message notification: ${message.notification?.body}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feeddo Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FeeddoDemo(),
    );
  }
}

class FeeddoDemo extends StatefulWidget {
  const FeeddoDemo({super.key});

  @override
  State<FeeddoDemo> createState() => _FeeddoDemoState();
}

class _FeeddoDemoState extends State<FeeddoDemo> {
  String _status = 'Ready to initialize';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-initialize on app launch
    _initFeeddo();
  }

  /// Initialize Feeddo SDK
  Future<void> _initFeeddo() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    String? token = await messaging.getToken();

    if (kDebugMode) {
      print('Registration Token=$token');
    }

    setState(() {
      _isLoading = true;
      _status = 'Initializing Feeddo...';
    });

    try {
      final userId = await Feeddo.init(
        apiKey: 'fdo_7b963c07666b4fc38dd2114b70ef6cb6',
        context: context,
        notificationDuration: Duration(seconds: 10),
      );

      Feeddo.registerPushToken(
        pushToken: token!,
        pushProvider: FeeddoPushProvider.fcm,
      );

      int count = Feeddo.unreadMessageCount;
      debugPrint('Initial unread message count: $count');

      setState(() {
        _status = 'Feeddo initialized!\nUser ID: $userId';
        _isLoading = false;
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('A new onMessageOpenedApp event was published!');
        print('Message data: ${message.data}');
        print('Message notification: ${message.notification?.title}');
        print('Message notification: ${message.notification?.body}');
        Feeddo.handleNotificationTap(context, message.data);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received a message while in the foreground!');
        print('Message data: ${message.data}');
        print('Message notification: ${message.notification?.title}');
        print('Message notification: ${message.notification?.body}');
        Feeddo.showInappNotification(
          context: context,
          title: message.notification?.title ?? 'New Message',
          message: message.notification?.body ?? '',
          data: message.data,
        );
      });
    } catch (e) {
      setState(() {
        _status = 'Initialization failed: $e';
        _isLoading = false;
      });
    }
  }

  /// Initialize user on app launch
  Future<void> _initializeUser() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing user...';
    });

    try {
      final userId = await Feeddo.init(
        apiKey: 'fdo_7b963c07666b4fc38dd2114b70ef6cb6',
        context: context,
        subscriptionStatus: 'free',
        customAttributes: {
          'signupDate': DateTime.now().toIso8601String(),
          'plan': 'basic',
        },
      );

      setState(() {
        _status = 'User initialized!\nUser ID: $userId';
        _isLoading = false;
      });
    } on FeeddoApiException catch (e) {
      setState(() {
        _status = 'API Error: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  /// Update user information
  Future<void> _updateUser() async {
    setState(() {
      _isLoading = true;
      _status = 'Updating user...';
    });

    try {
      await Feeddo.init(
        context: context,
        apiKey: 'fdo_7b963c07666b4fc38dd2114b70ef6cb6',
        userName: 'John Doe Updated',
        subscriptionStatus: 'premium',
        customAttributes: {
          'plan': 'pro',
          'lastUpdated': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _status = 'User updated successfully!';
        _isLoading = false;
      });
    } on FeeddoApiException catch (e) {
      setState(() {
        _status = 'API Error: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  /// Upsert with custom data
  Future<void> _upsertCustomUser() async {
    setState(() {
      _isLoading = true;
      _status = 'Upserting custom user...';
    });

    try {
      final userId = await Feeddo.init(
        context: context,
        apiKey: 'fdo_7b963c07666b4fc38dd2114b70ef6cb6',
        externalUserId: 'custom-user-456',
        userName: 'Jane Smith',
        email: 'jane@example.com',
        userSegment: 'power-user',
        subscriptionStatus: 'premium',
        customAttributes: {
          'role': 'admin',
          'preferences': {'theme': 'dark', 'notifications': true},
        },
      );

      setState(() {
        _status = 'Custom user upserted!\nUser ID: $userId';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  /// Clear user - Not available in simplified API
  Future<void> _clearUser() async {
    setState(() {
      _status =
          'Note: Clear user not available.\nUser data persists in SharedPreferences.';
    });
  }

  /// Load stored user - Not available in simplified API
  Future<void> _loadStoredUser() async {
    setState(() {
      _status =
          'Note: User data is automatically loaded.\nJust call Feeddo.init() again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Feeddo Flutter Demo'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.support_agent,
                size: 64,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 24),
              const Text(
                'Feeddo Flutter SDK Demo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'End User Upsert Example',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_status),
                      if (_isLoading) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _initializeUser,
                icon: const Icon(Icons.person_add),
                label: const Text('Initialize User'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateUser,
                icon: const Icon(Icons.edit),
                label: const Text('Update User'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _upsertCustomUser,
                icon: const Icon(Icons.people),
                label: const Text('Upsert Custom User'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadStoredUser,
                icon: const Icon(Icons.storage),
                label: const Text('Load Stored User'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _clearUser,
                icon: const Icon(Icons.clear),
                label: const Text('Clear User'),
              ),

              const SizedBox(height: 32),
              const Text(
                'Support UI',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Feeddo.show(
                  context,
                  theme: FeeddoTheme.dark(),
                  desktopConstraints: BoxConstraints(
                    maxWidth: 370,
                    maxHeight: 700,
                  ),
                ),
                icon: const Icon(Icons.chat),
                label: const Text('Open Support (Default Dark)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    Feeddo.show(context, theme: FeeddoTheme.light()),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Open Support (Light)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Feeddo.show(
                  context,
                  theme: FeeddoTheme(
                    colors: FeeddoColors(
                      background: Colors.indigo.shade900,
                      backgroundGradient: [
                        Colors.indigo.shade900,
                        Colors.purple.shade900,
                      ],
                      textPrimary: Colors.white,
                      cardBackground: Colors.indigo.shade800,
                      cardText: Colors.white,
                      iconColor: Colors.white,
                      closeButtonColor: Colors.white,
                    ),
                    isDark: true,
                  ),
                ),
                icon: const Icon(Icons.color_lens),
                label: const Text('Open Support (Custom Theme)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Features',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('✓ Auto-collects device info'),
                      const Text('✓ Auto-collects platform info'),
                      const Text('✓ Auto-collects app version'),
                      const Text('✓ Supports custom attributes'),
                      const Text('✓ Backend manages user IDs'),
                      const Text('✓ Persists data in SharedPreferences'),
                      const Text('✓ Automatic user ID reuse'),
                      const Text('✓ Country & locale from IP (backend)'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
