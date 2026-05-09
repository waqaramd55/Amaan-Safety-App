import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/preferences_service.dart';
import '../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PreferencesService _prefs = PreferencesService();

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    
    final user = FirebaseAuth.instance.currentUser;
    final setupComplete = await _prefs.isSetupComplete();
    
    if (mounted) {
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(
          context,
          setupComplete ? '/home' : '/setup',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AmaanTheme.primaryColor, AmaanTheme.secondaryColor],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'logo',
              child: Image.asset(
                'assets/images/logo.png',
                height: 180,
                width: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.security, size: 100, color: Colors.white),
              ),
            ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack).fadeIn(),
            const SizedBox(height: 32),
            Text(
              'AMAAN',
              style: GoogleFonts.outfit(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
            const SizedBox(height: 12),
            Text(
              'Your Safety, Our Priority',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 800.ms),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              strokeWidth: 2,
            ).animate().fadeIn(delay: 1200.ms),
          ],
        ),
      ),
    );
  }
}

