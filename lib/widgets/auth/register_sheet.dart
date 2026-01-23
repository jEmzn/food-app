import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app1/widgets/auth/login_sheet.dart';
/*
    Why DraggableScrollableSheet here?
      A widget that creates a scrollable sheet that can be dragged to resize.

      The [DraggableScrollableSheet] creates a sheet that grows and shrinks in
      response to the user dragging a specific scrollable child within it.
    
      This implementation typically relies on a builder function that provides a
      [ScrollController] which must be attached to the scrollable widget (e.g.,
      [ListView] or [SingleChildScrollView]) inside the sheet. This link allows
      the sheet to distinguish between dragging the sheet itself and scrolling
      the content within it.

    ### Key Properties:
      * `initialChildSize`: The initial fractional height of the sheet (0.0 to 1.0).
      * `minChildSize`: The minimum fractional height the sheet can shrink to.
      * `maxChildSize`: The maximum fractional height the sheet can expand to.
      * `builder`: A callback that builds the scrollable content.

    Why ListView here?
      A scrollable list of widgets arranged linearly.

      The ListView widget is used to create a scrollable list of items. It can
      be configured to scroll vertically or horizontally and can contain a large
      number of children, making it suitable for displaying lists of data.
    */

class RegisterSheet extends StatefulWidget {
  const RegisterSheet({super.key});

  @override
  State<RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<RegisterSheet> {
  static bool _rememberMe = false;
  static const Color primaryColor = Color(0xFF73CA31);
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.50,
      maxChildSize: 1.0,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            color: Colors.white,
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.only(
              top: 30,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            children: [
              SizedBox(height: 10),
              Image.asset('assets/login_logo.png', height: 120),
              SizedBox(height: 20),
              Text(
                'Registration',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Create your account to get started with FoodApp.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Username',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your Username',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Colors.grey[500]!),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Colors.red[400]!),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Email',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your Email',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Colors.grey[500]!),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Colors.red[400]!),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Password',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your Password',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Colors.grey[500]!),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Colors.red[400]!),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Confirm Password',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your Password',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Colors.grey[500]!),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide(color: Colors.red[400]!),
                  ),
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    checkColor: Colors.white,
                    activeColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    side: BorderSide(color: Colors.grey[500]!, width: 1.5),
                    onChanged: (bool? value) => {
                      setState(() {
                        _rememberMe = value ?? false;
                      }),
                    },
                  ),
                  Text(
                    'I agree to the Terms and Conditions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: GoogleFonts.inter(fontSize: 16),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () => {},
                child: Text('Register'),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.grey[400], thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: (Text(
                      'Or continue with',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    )),
                  ),
                  Expanded(
                    child: Divider(color: Colors.grey[400], thickness: 1),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => {},
                    icon: Image.asset(
                      'assets/images/logo/google_logo.png',
                      height: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  IconButton(
                    onPressed: () => {},
                    icon: Image.asset(
                      'assets/images/logo/facebook_logo.png',
                      height: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  IconButton(
                    onPressed: () => {},
                    icon: Image.asset(
                      'assets/images/logo/apple_logo.png',
                      height: 24,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () => {
                      Navigator.pop(context),

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const LoginSheet(),
                      ),
                    },
                    child: Text(
                      'Sign in',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
