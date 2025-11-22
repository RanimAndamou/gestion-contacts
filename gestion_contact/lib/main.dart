import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/accounts_page.dart';
import 'services/accounts_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await AccountsDb.database;

  runApp(MyApp());
}

// ---------------- GO ROUTER CONFIGURATION ----------------
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/login',                               // ← أضفتها هنا
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => SignupScreen(),
    ),
    GoRoute(
      path: '/accounts',
      builder: (context, state) => const AccountsPage(),
    ),
    GoRoute(
      path: '/database-view',
      builder: (context, state) {
        final dbPath = state.extra as String; // récupérer le paramètre
        return DatabaseViewPage(dbPath: dbPath);
      },
    ),
  ],
);

// ---------------- MAIN APP ----------------
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,          // Use GoRouter
      debugShowCheckedModeBanner: false,
    );
  }
}


