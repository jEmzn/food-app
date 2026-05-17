import 'package:app1/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Rate the App: in-app star rating + comment.
///
/// No backend call — your API has no /feedback endpoint yet. When you add
/// `url_launcher` you can replace _submit with a launchUrl call to your
/// real Play Store / App Store listing. For now we just thank the user.
class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});
  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _stars = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a star rating first')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thanks for rating!'),
        content: Text(
          'You gave $_stars / 5. Your feedback helps us improve.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Rate the App', style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text('Enjoying the app?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Tap a star to leave a rating.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey[700])),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _stars;
                return IconButton(
                  iconSize: 40,
                  icon: Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: filled ? Colors.amber : Colors.grey[400],
                  ),
                  onPressed: () => setState(() => _stars = i + 1),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comment,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Tell us more (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _submit, child: const Text('Submit')),
          ],
        ),
      ),
    );
  }
}
