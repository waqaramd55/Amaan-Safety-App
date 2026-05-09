import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';
import 'preferences_service.dart';

class EmailService {
  final PreferencesService _prefs = PreferencesService();

  Future<bool> sendEmergencyEmail(String recipientEmail, String message) async {
    final senderEmail = await _prefs.getSmtpEmail();
    final senderPassword = await _prefs.getSmtpPassword();

    if (senderEmail == null || senderPassword == null || 
        senderEmail.isEmpty || senderPassword.isEmpty) {
      return false;
    }

    final smtpServer = _getSmtpServer(senderEmail, senderPassword);

    final emailMessage = Message()
      ..from = Address(senderEmail, 'AMAAN Safety App')
      ..recipients.add(recipientEmail)
      ..subject = 'EMERGENCY ALERT! [Amaan App]'
      ..text = message;

    try {
      // Add a 15-second timeout to prevent hanging
      await send(emailMessage, smtpServer).timeout(
        const Duration(seconds: 15),
      );
      return true;
    } catch (e) {
      debugPrint('Email error: $e');
      return false;
    }
  }

  SmtpServer _getSmtpServer(String email, String password) {
    final lowerEmail = email.toLowerCase();
    if (lowerEmail.contains('gmail.com')) {
      return gmail(email, password);
    } else if (lowerEmail.contains('outlook.com') || 
               lowerEmail.contains('hotmail.com') ||
               lowerEmail.contains('live.com') ||
               lowerEmail.contains('msn.com')) {
      return hotmail(email, password);
    } else if (lowerEmail.contains('yahoo.com')) {
      return yahoo(email, password);
    } else {
      // Generic fallback for other providers
      String domain = email.split('@').last;
      return SmtpServer('smtp.$domain',
          username: email, password: password, port: 587);
    }
  }
}
