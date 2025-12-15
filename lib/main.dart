import 'package:flutter/material.dart';
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

class DhukutiApp extends StatelessWidget {
  const DhukutiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final router = createRouter(authState);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
