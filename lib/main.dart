import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'auth/auth_state.dart';
import 'providers/user_provider.dart';
import 'providers/market_provider.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prefer edge-to-edge without coloring system bars (avoids deprecated
  // Window.setStatusBarColor / setNavigationBarColor on Android 15+).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await Firebase.initializeApp();
  await FCMService().initNotifications();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MarketProvider()),
      ],
      child: const SuvhaInvestmentApp(),
    ),
  );
}

class SuvhaInvestmentApp extends StatefulWidget {
  const SuvhaInvestmentApp({super.key});

  @override
  State<SuvhaInvestmentApp> createState() => _SuvhaInvestmentAppState();
}

class _SuvhaInvestmentAppState extends State<SuvhaInvestmentApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthState>();
    _router = createRouter(authState);
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0B5F4B);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Suvha Investment',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
