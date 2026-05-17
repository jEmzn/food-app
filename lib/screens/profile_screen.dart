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

  late final List<_ProfileOption> _options = [
    _ProfileOption('Profile info', Icons.person_outline,
        () => _go(AppRoutes.profileInfoRoute)),
    _ProfileOption(
        'History', Icons.history, () => _go(AppRoutes.historyRoute)),
    _ProfileOption(
        'Rate the App', Icons.star_outline, () => _go(AppRoutes.rateAppRoute)),
    _ProfileOption('Settings', Icons.settings_outlined,
        () => _go(AppRoutes.settingsRoute)),
    _ProfileOption(
        'Help & Support', Icons.help_outline, () => _go(AppRoutes.helpRoute)),
    _ProfileOption('About', Icons.info_outline, () => _go(AppRoutes.aboutRoute)),
    _ProfileOption('Logout', Icons.logout, _confirmLogout),
  ];

  // Push a named route. Used by all the profile menu options.
  void _go(String route) {
    Navigator.of(context).pushNamed(route);
  }

  // Avatar tap: still a placeholder until we add image upload.
  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out?', style: GoogleFonts.poppins()),
        content: Text(
          'You will need to sign in again to access your account.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign out',
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
        : 'User';
    final email = user?.email ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 50.0,
        bottom: 80.0,
        left: 24.0,
        right: 24.0,
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const TopLabel(textLabel: 'My Profile'),
          const SizedBox(height: 18),
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
          const SizedBox(height: 12),
          Text(
            displayName,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          Container(
            margin: const EdgeInsets.only(top: 30),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              color: Colors.white,
            ),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shrinkWrap: true,
              itemCount: _options.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(thickness: 1, color: Colors.grey[300]),
              ),
              itemBuilder: (context, index) {
                final option = _options[index];
                final isLogout = option.label == 'Logout';
                return ListTile(
                  leading: Icon(
                    option.icon,
                    color: isLogout
                        ? Colors.red[600]
                        : AppTheme.primaryDarkColor,
                  ),
                  title: Text(
                    option.label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isLogout ? Colors.red[600] : Colors.black,
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
