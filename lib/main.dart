import 'package:flutter/material.dart';
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
  await Firebase.initializeApp();
  await FCMService().initNotifications();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MarketProvider()),
      ],
      child: const SuvhaInvestorApp(),
    ),
  );
}

class SuvhaInvestorApp extends StatefulWidget {
  const SuvhaInvestorApp({super.key});

  @override
  State<SuvhaInvestorApp> createState() => _SuvhaInvestorAppState();
}

class _SuvhaInvestorAppState extends State<SuvhaInvestorApp> {
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
      title: 'Suvha Investor',
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
