import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/trigger_service.dart';
import '../core/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isProtectionActive = true;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
      final triggerService = Provider.of<TriggerService>(context, listen: false);
      triggerService.onTrigger = () {
        Navigator.pushNamed(context, '/alert');
      };
      triggerService.init();
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.sms,
      Permission.microphone,
    ].request();
  }

  void _toggleProtection() async {
    if (!_isProtectionActive) {
      await _requestPermissions();
    }
    if (!mounted) return;
    
    setState(() {
      _isProtectionActive = !_isProtectionActive;
    });
    
    final triggerService = Provider.of<TriggerService>(context, listen: false);
    if (_isProtectionActive) {
      triggerService.resumeAll();
    } else {
      triggerService.stopAll();
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final triggerService = Provider.of<TriggerService>(context);

    return Scaffold(
      backgroundColor: AmaanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'AMAAN',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AmaanTheme.primaryColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/setup'),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AmaanTheme.primaryColor, AmaanTheme.secondaryColor],
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
                child: _user?.photoURL == null ? const Icon(Icons.person, size: 40, color: AmaanTheme.primaryColor) : null,
              ),
              accountName: Text(_user?.displayName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(_user?.email ?? 'No email'),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Setup Contacts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/setup');
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: _logout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large Toggle Button
              GestureDetector(
                onTap: _toggleProtection,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isProtectionActive
                          ? [Colors.redAccent, AmaanTheme.primaryColor]
                          : [Colors.green, Colors.greenAccent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isProtectionActive ? Colors.red : Colors.green).withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isProtectionActive ? Icons.shield_rounded : Icons.check_circle_outline,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isProtectionActive ? 'PROTECTED' : "I'M SAFE",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(target: _isProtectionActive ? 1 : 0)
               .shimmer(duration: 2.seconds),
              
              const SizedBox(height: 48),
              
              // Status Indicators
              _StatusItem(
                icon: Icons.mic_none_rounded,
                label: 'Keyword listening...',
                isActive: triggerService.isListening && _isProtectionActive,
              ),
              const SizedBox(height: 16),
              _StatusItem(
                icon: Icons.vibration_rounded,
                label: 'Shake detection active',
                isActive: triggerService.isShakeActive && _isProtectionActive,
              ),
              
              const SizedBox(height: 48),
              
              // Emergency Numbers Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                  ],
                ),
                child: Column(
                  children: [
                    Text('EMERGENCY SERVICES', 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _EmergencyBtn(label: 'Police (15)', icon: Icons.local_police, number: '15'),
                        _EmergencyBtn(label: 'Ambulance (115)', icon: Icons.medical_services, number: '115'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _EmergencyBtn(label: 'Women Protection (1043)', icon: Icons.woman, number: '1043'),
                        _EmergencyBtn(label: 'Cyber Crime (1991)', icon: Icons.security, number: '1991'),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/alert'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('TRIGGER MANUAL ALERT'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _StatusItem({required this.icon, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? AmaanTheme.primaryColor : Colors.grey, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black87 : Colors.grey,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _EmergencyBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final String number;

  const _EmergencyBtn({required this.label, required this.icon, required this.number});

  Future<void> _launchDialer() async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launchDialer,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: AmaanTheme.primaryColor.withValues(alpha: 0.1),
            child: Icon(icon, color: Colors.red),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}


