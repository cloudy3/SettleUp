import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:provider/provider.dart";
import "package:settle_up/screens/home_screen.dart";
import "package:settle_up/screens/onboarding_scren.dart";
import "firebase_options.dart";
import "package:settle_up/screens/auth_screen.dart";
import "package:settle_up/providers/providers.dart";
import "package:settle_up/services/services.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize connectivity service
  await ConnectivityService().initialize();

  // Fetch initial route
  final initialRoute = await getInitialRoute();

  runApp(MyApp(initialRoute: initialRoute));
}

Future<String> getInitialRoute() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return "/auth"; // User not signed in
  }

  // Fetch onboarding status from Firestore
  final userDoc = await FirebaseFirestore.instance
      .collection("Users")
      .doc(user.uid)
      .get();

  if (!userDoc.exists || !(userDoc.data()?["onboardingCompleted"] ?? false)) {
    return "/onboarding"; // Onboarding not completed
  }

  return "/home"; // Onboarding completed
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => OfflineProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return _ConnectivityWrapper(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: "Splitwise Clone",
              theme: themeProvider.currentTheme,
              initialRoute: initialRoute,
              routes: {
                "/auth": (context) => const AuthScreen(),
                "/onboarding": (context) => const OnboardingScreen(),
                "/home": (context) => const HomeScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper to handle connectivity changes and update offline provider
class _ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const _ConnectivityWrapper({required this.child});

  @override
  State<_ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<_ConnectivityWrapper> {
  late final ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();

    // Listen to connectivity changes and update offline provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectivityService.connectivityStream.listen((isOnline) {
        if (mounted) {
          final offlineProvider = context.read<OfflineProvider>();
          offlineProvider.updateOnlineStatus(isOnline);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme =>
      _isDarkMode ? ThemeData.dark() : ThemeData.light();

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.deepPurple,
    primaryColor: Colors.blue.shade900,
    scaffoldBackgroundColor: Colors.grey.shade100,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue.shade900,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue.shade900,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      shadowColor: Colors.grey[300],
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade900,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade800,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.grey.shade700),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.grey.shade600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
      ),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.deepPurple,
    primaryColor: Colors.deepPurple.shade900,
    scaffoldBackgroundColor: const Color.fromARGB(255, 4, 0, 53),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.deepPurple,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue.shade900,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[800],
      shadowColor: Colors.grey[700],
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple.shade100,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple.shade200,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.grey.shade400),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.grey.shade500),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
    ),
  );
}
