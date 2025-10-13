import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'user_details_page.dart';
import 'user_list_page.dart';
import 'alerts_page.dart';
import 'basic_needs_page.dart';
import 'volunteer_details_page.dart';
import 'volunteers_page.dart';
import 'safety_status_page.dart';
import 'emergency_contacts_page.dart';
import 'first_aid_page.dart';
import 'offline_alerts_page.dart';

/// Background FCM message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Background message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Handle FCM messages in the background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const EmergencyContactApp());
}

class EmergencyContactApp extends StatefulWidget {
  const EmergencyContactApp({super.key});

  @override
  State<EmergencyContactApp> createState() => _EmergencyContactAppState();
}

class _EmergencyContactAppState extends State<EmergencyContactApp> {
  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  void _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request user permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔔 Permission status: ${settings.authorizationStatus}');

    // Retrieve FCM token
    String? token = await messaging.getToken();
    print('🔑 FCM Token: $token');

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📢 Foreground message: ${message.notification?.title}');
      print('📩 Body: ${message.notification?.body}');
    });

    // App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 App opened from notification: ${message.data}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disaster Response and Safety App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.red,
        scaffoldBackgroundColor: Colors.grey.shade100,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.redAccent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),

        // <-- FIX: use CardThemeData here (ThemeData expects CardThemeData?)
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
        ),

        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      // Initial route
      initialRoute: '/',

      // Routes
      routes: {
        '/': (context) => const LoginPage(),
        '/signup': (context) =>  SignUpPage(),
        '/home': (context) =>  HomePage(),
        '/user_details': (context) => const UserDetailsPage(),
        '/user_list': (context) => const UserListPage(),
        '/alerts': (context) => const AlertsPage(),
        '/needs': (context) => const BasicNeedsPage(),
        '/volunteer': (context) => const VolunteerDetailsPage(),
        '/volunteers': (context) => const VolunteersPage(),
        '/safety': (context) => const SafetyStatusPage(),
        '/contacts': (context) =>  EmergencyContactsPage(),
        '/first_aid': (context) =>  FirstAidPage(),
        '/offline_alerts': (context) => const OfflineAlertPage(),
      },
    );
  }
}

