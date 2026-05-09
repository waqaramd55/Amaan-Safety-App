import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/contact.dart';
import '../services/preferences_service.dart';
import '../services/email_service.dart';
import '../core/theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final PreferencesService _prefs = PreferencesService();
  final List<Contact> _contacts = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController(text: 'help me');
  final TextEditingController _smtpEmailController = TextEditingController();
  final TextEditingController _smtpPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final contacts = await _prefs.getContacts();
    final keyword = await _prefs.getKeyword();
    final smtpEmail = await _prefs.getSmtpEmail();
    final smtpPassword = await _prefs.getSmtpPassword();
    setState(() {
      _contacts.addAll(contacts);
      _keywordController.text = keyword;
      _smtpEmailController.text = smtpEmail ?? '';
      _smtpPasswordController.text = smtpPassword ?? '';
    });
  }

  void _addContact() {
    if (_contacts.length >= 5) {
      _showSnackBar('Maximum 5 contacts allowed');
      return;
    }

    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      setState(() {
        _contacts.add(Contact(
          name: _nameController.text,
          phoneNumber: _phoneController.text,
          email: _emailController.text,
        ));
        _nameController.clear();
        _phoneController.clear();
        _emailController.clear();
      });
      _showSnackBar('Contact added successfully!', success: true);
    } else {
      _showSnackBar('Please fill in Name and Phone Number');
    }
  }

  Future<void> _saveAndContinue() async {
    if (_contacts.isEmpty) {
      _showSnackBar('Please add at least one contact');
      return;
    }

    await _prefs.saveContacts(_contacts);
    await _prefs.saveKeyword(_keywordController.text);
    await _prefs.saveSmtpSettings(_smtpEmailController.text, _smtpPasswordController.text);
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _testEmail() async {
    if (_smtpEmailController.text.isEmpty || _smtpPasswordController.text.isEmpty) {
      _showSnackBar('Please enter SMTP Email and Password first');
      return;
    }

    _showSnackBar('Sending test email...');

    // Save temporary settings for test
    await _prefs.saveSmtpSettings(_smtpEmailController.text, _smtpPasswordController.text);
    
    final emailService = EmailService();
    bool success = await emailService.sendEmergencyEmail(
      _smtpEmailController.text, 
      "This is a test email from AMAAN Safety App. Your settings are working!"
    );

    if (mounted) {
      _showSnackBar(
        success ? 'Test Email Sent! ✅' : 'Email Failed! Check your App Password ❌',
        success: success,
      );
    }
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Safety Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Emergency Contacts', 'Add up to 5 trusted people to alert in danger.'),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address (Optional)',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('ADD TO LIST'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_contacts.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'YOUR CONTACTS',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _contacts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      title: Text(_contacts[index].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${_contacts[index].phoneNumber}${_contacts[index].email.isNotEmpty ? '\n${_contacts[index].email}' : ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => setState(() => _contacts.removeAt(index)),
                      ),
                    ),
                  );
                },
              ),
            ],
            
            const SizedBox(height: 32),
            _buildSectionHeader('Voice Keyword', 'A word you can say to trigger an alert instantly.'),
            const SizedBox(height: 16),
            TextField(
              controller: _keywordController,
              decoration: const InputDecoration(
                labelText: 'Panic Keyword',
                prefixIcon: Icon(Icons.mic_none_rounded),
              ),
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Email System (SMTP)', 'To send automatic emails, we need your sender credentials.'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tip: For Gmail, use an "App Password" from your Google Security settings.',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _smtpEmailController,
              decoration: const InputDecoration(
                labelText: 'Your Email (Sender)',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _smtpPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'App Password',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _testEmail,
              icon: const Icon(Icons.mark_email_read_outlined),
              label: const Text('TEST CONNECTION'),
              style: TextButton.styleFrom(foregroundColor: AmaanTheme.primaryColor),
            ),
            
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _saveAndContinue,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                backgroundColor: AmaanTheme.secondaryColor,
              ),
              child: const Text('SAVE & START PROTECTING'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AmaanTheme.primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}

