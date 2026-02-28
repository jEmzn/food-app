import 'package:app1/config/app_theme.dart';
import 'package:app1/widgets/top_label.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const List<String> profileOptions = [
    'Profile info',
    'History',
    'Rate the App',
    'Settings',
    'Help & Support',
    'About',
    'Logout',
  ];

  static int numOptions = profileOptions.length;

  static const List<IconData> profileOptionIcons = [
    Icons.person_outline,
    Icons.history,
    Icons.star_outline,
    Icons.settings_outlined,
    Icons.help_outline,
    Icons.info_outline,
    Icons.logout,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 50.0,
        bottom: 80.0,
        left: 24.0,
        right: 24.0,
      ),
      child: Column(
        children: [
          SizedBox(height: 20),
          TopLabel(textLabel: 'My Profile'),
          SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 35),
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Profile image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/test_profile.jpg'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: Colors.black54,
                        style: BorderStyle.solid,
                        width: 4,
                      ),
                    ),
                  ),
                  // Edit icon with background
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.mode_edit_outline_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Kitty Kit',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 30),
            padding: EdgeInsets.all(0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              color: Colors.white,
            ),
            child: ListView(
              physics: const NeverScrollableScrollPhysics(), // Disable Scolling
              padding: EdgeInsets.all(0),
              shrinkWrap: true,
              children: profileOptions.map((option) {
                return Column(
                  children: [
                    if (profileOptions.indexOf(option) != 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Divider(thickness: 2, color: Colors.grey[155]),
                      )
                    else
                      SizedBox(height: 12),
                    ListTile(
                      leading: Icon(
                        profileOptionIcons[profileOptions.indexOf(option)],
                        color: AppTheme.primaryDarkColor,
                      ),
                      title: Text(
                        option,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Handle option tap
                      },
                    ),
                    if (profileOptions.indexOf(option) == numOptions - 1)
                      SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }
}
