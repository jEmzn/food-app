import 'dart:io';

import 'package:app1/config/app_theme.dart';
import 'package:app1/config/routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app1/services/auth_service.dart';
import 'package:app1/widgets/top_label.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _fallbackProfileImage = 'assets/images/test_profile.jpg';

  final ImagePicker _picker = ImagePicker();

  // True while an avatar upload is in flight, so we can show a spinner over the
  // avatar and block a second tap from starting a parallel upload.
  bool _uploadingAvatar = false;

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

  // Avatar edit tap: ask where to get the photo, pick it, then upload.
  Future<void> _changeAvatar() async {
    if (_uploadingAvatar) return; // already uploading — ignore extra taps

    // Let the user choose between the camera and the photo gallery.
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('ถ่ายรูป', style: GoogleFonts.mali()),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('เลือกจากคลังภาพ', style: GoogleFonts.mali()),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return; // user dismissed the sheet

    // Everything below can throw — pickImage included (e.g. a
    // MissingPluginException if the app wasn't fully rebuilt after adding the
    // image_picker plugin). Keep it all inside try/catch so any failure shows
    // a message instead of silently doing nothing.
    try {
      // Downscale + compress on-device so we don't upload huge originals.
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return; // user cancelled the picker

      setState(() => _uploadingAvatar = true);

      await AuthService.uploadAvatar(File(picked.path));
      if (!mounted) return;
      // uploadAvatar already refreshed Firebase photoURL; rebuild to show it.
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตรูปโปรไฟล์แล้ว')),
      );
    } catch (e) {
      if (!mounted) return;
      // Surface the real error text so problems (no plugin, server down, auth)
      // are visible while developing instead of failing silently.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
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
      // CachedNetworkImageProvider is a drop-in ImageProvider that caches to
      // disk. The avatar URL carries a ?v=<timestamp> cache-buster after each
      // upload, so a new picture is a new cache key and still updates.
      return CachedNetworkImageProvider(url);
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
                    // While uploading, dim the avatar and show a spinner so the
                    // user knows their new photo is being saved.
                    child: _uploadingAvatar
                        ? Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black38,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: _uploadingAvatar ? null : _changeAvatar,
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
