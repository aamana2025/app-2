import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/subscription_provider.dart';
import 'router/app_router.dart';
import 'package:flutter/services.dart';
import 'screens/startup_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    // Load authentication data before app starts
    _initializeAuth();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    // Ensure Android recent-apps shows the correct app name and color
    SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(
        label: 'Aamana classroom',
        primaryColor: 0xFF0A84FF,
      ),
    );
  }

  Future<void> _initializeAuth() async {
    try {
      // Load pending ID and login data from storage on app start
      await _authProvider.loadPendingId();
      await _authProvider.loadStoredLoginData();
      print('Main: Authentication initialization completed');
    } catch (e) {
      print('Main: Error during authentication initialization: $e');
      // Don't let initialization errors crash the app
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return StartupScreen(
            child: MaterialApp.router(
              title: 'Aamana classroom',
              debugShowCheckedModeBanner: false,
              theme: appTheme,
              routerConfig: AppRouter.router,
              builder: (context, child) {
                // Global responsiveness: clamp system text scaling and adapt slightly to screen size
                final mq = MediaQuery.of(context);
                final double shortest = mq.size.shortestSide;
                final double uiScale = (shortest / 360.0).clamp(0.85, 1.15);
                final double textScale =
                    (mq.textScaleFactor * uiScale).clamp(0.9, 1.2);
                return MediaQuery(
                  data: mq.copyWith(textScaleFactor: textScale),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              locale: const Locale('ar', 'SA'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ar', 'SA'),
              ],
            ),
          );
        },
      ),
    );
  }
}

final ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  primaryColor: const Color(0xFF0A84FF),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF0A84FF), // Blue (keep)
    secondary: Color(0xFF8E44AD),
    surface: Color(0xFFF2F2F7), // Light grey for cards
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black, fontSize: 18),
    bodyMedium: TextStyle(color: Colors.black87, fontSize: 16),
    bodySmall:
        TextStyle(color: Color(0xFF6B7280), fontSize: 14), // light grey text
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF2F2F7),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
  ),
);
