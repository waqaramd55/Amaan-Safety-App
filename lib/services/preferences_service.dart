import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import 'dart:convert';

class PreferencesService {
  static const String _contactsKey = 'emergency_contacts';
  static const String _keywordKey = 'panic_keyword';
  static const String _smtpEmailKey = 'smtp_email';
  static const String _smtpPasswordKey = 'smtp_password';


  Future<void> saveContacts(List<Contact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      contacts.map((c) => c.toMap()).toList(),
    );
    await prefs.setString(_contactsKey, encodedData);
  }

  Future<List<Contact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_contactsKey);
    if (encodedData == null) return [];
    final List<dynamic> decodedData = json.decode(encodedData);
    return decodedData.map((item) => Contact.fromMap(item)).toList();
  }

  Future<void> saveKeyword(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keywordKey, keyword.toLowerCase());
  }

  Future<String> getKeyword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keywordKey) ?? 'help me';
  }

  Future<bool> isSetupComplete() async {
    final contacts = await getContacts();
    return contacts.isNotEmpty;
  }

  Future<void> saveSmtpSettings(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_smtpEmailKey, email);
    await prefs.setString(_smtpPasswordKey, password);
  }

  Future<String?> getSmtpEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_smtpEmailKey);
  }

  Future<String?> getSmtpPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_smtpPasswordKey);
  }
}
