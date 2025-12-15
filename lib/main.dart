import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'auth/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthState(),
      child: const DhukutiApp(),
    ),
  );
}

class DhukutiApp extends StatefulWidget {
  const DhukutiApp({super.key});

  @override
  State<DhukutiApp> createState() => _DhukutiAppState();
}

class _DhukutiAppState extends State<DhukutiApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthState>();
    _router = createRouter(authState);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
