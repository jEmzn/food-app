import 'package:app1/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// About: app name, version, and credits. Fully static.
///
/// Version is hardcoded to match `pubspec.yaml`. When you add
/// `package_info_plus`, replace _appVersion with PackageInfo.fromPlatform().
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _appName = 'Food App';
  static const String _appVersion = '0.1.0';
  static const String _description =
      'ติดตามมื้ออาหาร แคลอรี และโภชนาการของคุณ ด้วยความช่วยเหลือจาก AI';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('เกี่ยวกับ', style: GoogleFonts.mali()),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.restaurant_menu,
                  color: Colors.white, size: 56),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(_appName,
                style: GoogleFonts.mali(
                    fontSize: 24, fontWeight: FontWeight.w600)),
          ),
          Center(
            child: Text('เวอร์ชัน $_appVersion',
                style: GoogleFonts.mali(color: Colors.grey[600])),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.white,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_description,
                  style: GoogleFonts.mali(color: Colors.grey[800])),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('สร้างด้วย'),
                  subtitle:
                      const Text('Flutter • Firebase Auth • PostgreSQL backend'),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.psychology_alt_outlined),
                  title: const Text('ข้อมูลโภชนาการขับเคลื่อนโดย'),
                  subtitle: const Text('OpenRouter (AI) + แคตตาล็อกอาหารที่แคชไว้'),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('จัดทำโดย'),
                  subtitle: const Text('นักศึกษาที่กำลังเรียนรู้ Flutter'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('© 2026 Food App',
                style: GoogleFonts.mali(
                    color: Colors.grey[600], fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
