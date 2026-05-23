import 'package:app1/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// In-memory app preferences. Resets when the app is killed because we don't
/// have `shared_preferences` installed yet.
///
/// TODO: when you add `shared_preferences: ^2.x.x` to pubspec.yaml, replace
/// these fields with reads/writes to SharedPreferences so the values persist.
class AppPrefs {
  AppPrefs._();
  static final AppPrefs instance = AppPrefs._();

  bool notificationsEnabled = true;
  bool darkMode = false; // not wired to ThemeMode yet — reminder for later
  WeightUnit weightUnit = WeightUnit.kg;
}

enum WeightUnit { kg, lb }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = AppPrefs.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('การตั้งค่า', style: GoogleFonts.mali()),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Group(title: 'การแจ้งเตือน', children: [
            SwitchListTile(
              title: const Text('เตือนมื้ออาหาร'),
              subtitle: const Text('แจ้งเตือนรายวันให้บันทึกมื้ออาหารของคุณ'),
              value: _prefs.notificationsEnabled,
              onChanged: (v) =>
                  setState(() => _prefs.notificationsEnabled = v),
            ),
          ]),
          _Group(title: 'การแสดงผล', children: [
            SwitchListTile(
              title: const Text('โหมดมืด'),
              subtitle: const Text('เร็ว ๆ นี้ — ปุ่มนี้ยังไม่มีผล'),
              value: _prefs.darkMode,
              onChanged: (v) => setState(() => _prefs.darkMode = v),
            ),
          ]),
          _Group(title: 'หน่วย', children: [
            // RadioGroup is the modern (Flutter 3.32+) replacement for the
            // deprecated `groupValue`/`onChanged` props on RadioListTile.
            // The group manages selection for all child Radios with matching type.
            RadioGroup<WeightUnit>(
              groupValue: _prefs.weightUnit,
              onChanged: (v) =>
                  setState(() => _prefs.weightUnit = v ?? WeightUnit.kg),
              child: const Column(
                children: [
                  RadioListTile<WeightUnit>(
                    title: Text('กิโลกรัม (กก.)'),
                    value: WeightUnit.kg,
                  ),
                  RadioListTile<WeightUnit>(
                    title: Text('ปอนด์ (lb)'),
                    value: WeightUnit.lb,
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Text(
            'หมายเหตุ: การตั้งค่าจะรีเซ็ตเมื่อรีสตาร์ทแอป จนกว่าจะเพิ่ม shared_preferences',
            style: GoogleFonts.mali(
                color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Text(title,
                style: GoogleFonts.mali(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Card(color: Colors.white, elevation: 0, child: Column(children: children)),
        ],
      ),
    );
  }
}
