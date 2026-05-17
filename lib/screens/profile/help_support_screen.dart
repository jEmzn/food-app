import 'package:app1/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Static FAQ + contact info. No backend.
///
/// We don't have `url_launcher`, so the contact email is copy-to-clipboard
/// instead of opening the mail app. Add `url_launcher` later for the real flow.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _supportEmail = 'support@example.com';

  static const List<_Faq> _faqs = [
    _Faq(
      q: 'How do I log a meal?',
      a: 'On the home screen, search a food and tap the + icon to add it to '
          'today\'s log. You can change the meal type (breakfast/lunch/dinner) '
          'before saving.',
    ),
    _Faq(
      q: 'How are calories calculated?',
      a: 'For each food we look up nutrition from our catalog. If the food '
          'isn\'t cached, our AI estimates it on first lookup and caches the '
          'result for next time.',
    ),
    _Faq(
      q: 'Why do my body metrics keep coming back?',
      a: 'The app stores body metrics on our server. Edits create a new record '
          '— the latest one is always shown. Older records are kept for history.',
    ),
    _Faq(
      q: 'How do I reset my password?',
      a: 'On the login screen, tap "Forgot password" and enter your email. '
          'You\'ll get a reset link from Firebase.',
    ),
    _Faq(
      q: 'Is my data private?',
      a: 'Your account is authenticated by Firebase. Body metrics and meals '
          'are linked to your user ID and only visible to you.',
    ),
  ];

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _supportEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Frequently asked questions',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            elevation: 0,
            child: Column(
              children: _faqs
                  .map((f) => ExpansionTile(
                        title: Text(f.q,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500)),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(f.a,
                                style: GoogleFonts.inter(color: Colors.grey[800])),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text('Still need help?',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Email support'),
              subtitle: const Text(_supportEmail),
              trailing: const Icon(Icons.copy),
              onTap: () => _copyEmail(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
}
