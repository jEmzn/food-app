import 'package:app1/config/app_theme.dart';
import 'package:app1/config/routes.dart';
import 'package:app1/services/auth_service.dart';
import 'package:app1/widgets/top_label.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _fallbackProfileImage = 'assets/images/test_profile.jpg';

  // `isLogout` below flags the destructive option by its index, so reordering
  // or translating these labels is safe.
  late final List<_ProfileOption> _options = [
    _ProfileOption('ข้อมูลโปรไฟล์', Icons.person_outline,
        () => _go(AppRoutes.profileInfoRoute)),
    _ProfileOption(
        'ประวัติ', Icons.history, () => _go(AppRoutes.historyRoute)),
    _ProfileOption(
        'ให้คะแนนแอป', Icons.star_outline, () => _go(AppRoutes.rateAppRoute)),
    _ProfileOption('การตั้งค่า', Icons.settings_outlined,
        () => _go(AppRoutes.settingsRoute)),
    _ProfileOption(
        'ช่วยเหลือและสนับสนุน', Icons.help_outline, () => _go(AppRoutes.helpRoute)),
    _ProfileOption('เกี่ยวกับ', Icons.info_outline, () => _go(AppRoutes.aboutRoute)),
    _ProfileOption('ออกจากระบบ', Icons.logout, _confirmLogout),
  ];

  // Push a named route. Used by all the profile menu options.
  void _go(String route) {
    Navigator.of(context).pushNamed(route);
  }

  // Avatar tap: still a placeholder until we add image upload.
  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เร็ว ๆ นี้')),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ออกจากระบบ?', style: GoogleFonts.mali()),
        content: Text(
          'คุณจะต้องเข้าสู่ระบบอีกครั้งเพื่อเข้าถึงบัญชีของคุณ',
          style: GoogleFonts.mali(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'ออกจากระบบ',
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.initialRoute,
        (_) => false,
      );
    }
  }

  ImageProvider _resolveAvatar(User? user) {
    final url = user?.photoURL;
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }
    return const AssetImage(_fallbackProfileImage);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : 'ผู้ใช้';
    final email = user?.email ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 50.0,
        bottom: 80.0,
        left: AppTheme.spacingL,
        right: AppTheme.spacingL,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingL),
          const TopLabel(textLabel: 'โปรไฟล์ของฉัน'),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 35),
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: _resolveAvatar(user),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: Colors.black54,
                        width: 4,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: _showComingSoon,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.mode_edit_outline_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            displayName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: AppTheme.subtleText, fontWeight: FontWeight.w400),
            ),
          ],
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spacingL),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              color: AppTheme.surfaceColor,
              boxShadow: AppTheme.cardShadow,
            ),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
              shrinkWrap: true,
              itemCount: _options.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                ),
                child: Divider(thickness: 1, color: Colors.grey[300]),
              ),
              itemBuilder: (context, index) {
                final option = _options[index];
                // Logout is always the last option (see _options above).
                final isLogout = index == _options.length - 1;
                return ListTile(
                  leading: Icon(
                    option.icon,
                    color: isLogout
                        ? Colors.red[600]
                        : AppTheme.primaryDarkColor,
                  ),
                  title: Text(
                    option.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isLogout
                          ? Colors.red[600]
                          : AppTheme.onSurfaceColor,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: option.onTap,
                );
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class _ProfileOption {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileOption(this.label, this.icon, this.onTap);
}
