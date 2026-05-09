import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/alert_triggered_screen.dart';
import 'services/trigger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TriggerService()),
      ],
      child: const AmaanApp(),
    ),
  );
}

class AmaanApp extends StatelessWidget {
  const AmaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amaan',
      debugShowCheckedModeBanner: false,
      theme: AmaanTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/setup': (context) => const SetupScreen(),
        '/home': (context) => const HomeScreen(),
        '/alert': (context) => const AlertTriggeredScreen(),
      },
    );
  }
}
