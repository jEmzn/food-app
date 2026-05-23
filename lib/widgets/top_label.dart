import 'package:app1/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopLabel extends StatelessWidget {
  final String textLabel;

  const TopLabel({super.key, required this.textLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        color: AppTheme.secondaryColor,
      ),
      // width: double.infinity
      padding: const EdgeInsetsDirectional.symmetric(vertical: 16),
      width: double.infinity,
      child: Text(
        textLabel,
        textAlign: TextAlign.center,
        style: GoogleFonts.mali(
          color: AppTheme.primarySoftColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
