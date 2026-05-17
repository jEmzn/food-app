import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app1/screens/auth/login_sheet.dart';
import 'package:app1/config/app_theme.dart';

const Color fade1 = Colors.white;
final Color fade2 = fade1.withValues(alpha: 0.63);
final Color fade3 = fade1.withValues(alpha: 0);
const Color buttonColor = AppTheme.primaryColor;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login-bk2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Align(alignment: Alignment.bottomCenter, child: BottomCardLogin()),
        ],
      ),
    );
  }
}

class BottomCardLogin extends StatelessWidget {
  const BottomCardLogin({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      width: BoxConstraints().maxWidth,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[fade1, fade2, fade3],
          stops: const [0.5, 0.86, 1.0],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(height: 60),
          Text(
            'Eat Well.\nLive Better',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          Text(
            'Discover the power of whole foods with a nutrition guide that fits your lifestyle, not just a diet.',
            style: GoogleFonts.inter(),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: TextStyle(fontFamily: 'roboto', fontSize: 16),
              minimumSize: Size(double.infinity, 50),
            ),
            onPressed: () => {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const LoginSheet(),
              ),
            },
            child: Text('Get Started'),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }
}
