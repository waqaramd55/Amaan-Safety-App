import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/preferences_service.dart';
import '../services/location_service.dart';
import '../services/audio_service.dart';
import '../services/email_service.dart';
import 'package:sms_sender_background/sms_sender.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import '../core/theme.dart';

class AlertTriggeredScreen extends StatefulWidget {
  const AlertTriggeredScreen({super.key});

  @override
  State<AlertTriggeredScreen> createState() => _AlertTriggeredScreenState();
}

class _AlertTriggeredScreenState extends State<AlertTriggeredScreen> {
  int _countdown = 5;
  Timer? _timer;
  bool _isAlertSent = false;
  String _sentMessage = "";
  final Map<String, String> _contactStatuses = {};
  
  final PreferencesService _prefs = PreferencesService();
  final LocationService _locationService = LocationService();
  final AudioService _audioService = AudioService();
  final EmailService _emailService = EmailService();
  final SmsSender smsSender = SmsSender();
  List<dynamic> _contacts = [];

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        _triggerAlert();
      }
    });
  }

  Future<void> _triggerAlert() async {
    setState(() => _countdown = 0);
    
    try {
      await _audioService.playAlarm();
      await _audioService.startRecording();
    } catch (e) {
      debugPrint('Media services error: $e');
    }

    String locationLink = "Location unavailable";
    try {
      // Add a timeout to location so it doesn't block the alert
      Position? position = await _locationService.getCurrentLocation().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      if (position != null) {
        locationLink = _locationService.getGoogleMapsLink(position);
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
        
    try {
      _contacts = await _prefs.getContacts();
      _sentMessage = "EMERGENCY! I need help. My current location: $locationLink";

      if (_contacts.isEmpty) {
        debugPrint('No contacts found to alert!');
      }

      // 4. Automatic background SMS (Android only)
      for (var contact in _contacts) {
        setState(() => _contactStatuses[contact.phoneNumber] = 'Sending SMS...');
        _sendSMS(contact.phoneNumber, _sentMessage, auto: true); // Don't await individual sends
      }

      // 5. Automatic background Email
      for (var contact in _contacts) {
        if (contact.email.isNotEmpty) {
          setState(() => _contactStatuses[contact.phoneNumber + '_email'] = 'Sending Email...');
          _emailService.sendEmergencyEmail(contact.email, _sentMessage).then((success) {
            if (mounted) {
              setState(() => _contactStatuses[contact.phoneNumber + '_email'] = 
                success ? 'Email Sent Automatically ✅' : 'Email Failed ❌');
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Alert processing error: $e');
    }

    setState(() => _isAlertSent = true);
  }

  Future<void> _sendSMS(String phoneNumber, String message, {bool auto = false}) async {
    if (Platform.isAndroid) {
      try {
        if (await Permission.sms.request().isGranted) {
          bool success = await smsSender.sendSms(
            phoneNumber: phoneNumber,
            message: message,
          );
          if (success) {
            setState(() => _contactStatuses[phoneNumber] = 'SMS Sent Automatically ✅');
            if (auto) return;
            return;
          } else {
             setState(() => _contactStatuses[phoneNumber] = 'Background SMS Failed ❌');
          }
        } else {
           setState(() => _contactStatuses[phoneNumber] = 'SMS Permission Denied ❌');
        }
      } catch (e) {
        debugPrint('SMS Sender error: $e');
      }
    }

    // Fallback for iOS or if background SMS fails
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{'body': message},
    );
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
    }
  }

  Widget _buildStatusRow(String status) {
    bool isSuccess = status.contains('✅');
    bool isError = status.contains('❌');
    
    return Row(
      children: [
        Icon(
          isSuccess ? Icons.check_circle_outline : 
          isError ? Icons.error_outline : Icons.sync_rounded,
          size: 16,
          color: isSuccess ? Colors.green : isError ? Colors.red : Colors.orange,
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSuccess ? Colors.green : isError ? Colors.red : Colors.orange,
          ),
        ),
      ],
    );
  }

  void _cancelAlert() {
    _timer?.cancel();
    _audioService.stopAlarm();
    _audioService.stopRecording();
    Navigator.pop(context);
  }

  void _imSafe() {
    _audioService.stopAlarm();
    _audioService.stopRecording();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isAlertSent ? Colors.white : AmaanTheme.errorColor.withValues(alpha: 0.05),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isAlertSent) ...[
                Icon(Icons.warning_rounded, size: 80, color: AmaanTheme.errorColor),
                const SizedBox(height: 24),
                Text(
                  'ALERT TRIGGERED',
                  style: GoogleFonts.outfit(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: AmaanTheme.errorColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Contacting emergency contacts in...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 40),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: _countdown / 5,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(AmaanTheme.errorColor),
                      ),
                    ),
                    Text(
                      '$_countdown',
                      style: GoogleFonts.outfit(
                        fontSize: 80, 
                        fontWeight: FontWeight.bold, 
                        color: AmaanTheme.errorColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _cancelAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: const Text('ABORT ALERT'),
                ),
              ] else ...[
                const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                Text(
                  'ALERTS DISPATCHED',
                  style: GoogleFonts.outfit(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.green,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      final smsStatus = _contactStatuses[contact.phoneNumber] ?? 'Pending...';
                      final emailStatus = _contactStatuses[contact.phoneNumber + '_email'] ?? 'Pending...';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(contact.phoneNumber, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                            const Divider(height: 24),
                            _buildStatusRow(smsStatus),
                            if (contact.email.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildStatusRow(emailStatus),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _imSafe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text("I'M SAFE NOW"),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
