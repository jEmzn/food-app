import 'package:app1/config/routes.dart';
import 'package:app1/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app1/screens/auth/register_sheet.dart';
import 'package:app1/config/app_theme.dart';
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

class LoginSheet extends StatefulWidget {
  const LoginSheet({super.key});

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  bool _rememberMe = false;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.50,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Expanded(
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
                      'Welcome to FoodApp',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Discover delicious meals and manage your orders with ease.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Email',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
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
                      controller: _passwordController,
                      obscureText: true,
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
                          side: BorderSide(
                            color: Colors.grey[500]!,
                            width: 1.5,
                          ),
                          onChanged: (bool? value) => {
                            setState(() {
                              _rememberMe = value ?? false;
                            }),
                          },
                        ),
                        Text(
                          'Remember Me',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () async {
                            final email = _emailController.text.trim();
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Enter your email above first, then tap Forgot Password.',
                                  ),
                                ),
                              );
                              return;
                            }
                            try {
                              await AuthService.sendPasswordReset(email);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password reset email sent. Check your inbox.',
                                    ),
                                  ),
                                );
                              }
                            } on FirebaseAuthException catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AuthService.friendlyError(e),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            'forgot Password?',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: GoogleFonts.inter(fontSize: 16),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_emailController.text.trim().isEmpty ||
                                  _passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter your email and password',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setState(() => _isLoading = true);
                              try {
                                await AuthService.login(
                                  _emailController.text.trim(),
                                  _passwordController.text,
                                );
                                // Send users with no/incomplete metrics to
                                // onboarding; otherwise straight to the app.
                                // On network failure, fall through to /main —
                                // the home screen handles the missing-target
                                // state gracefully.
                                String nextRoute = AppRoutes.mainRoute;
                                try {
                                  final metrics =
                                      await AuthService.fetchBodyMetrics();
                                  debugPrint(
                                    '[login] metrics=$metrics needsOnboarding='
                                    '${AuthService.bodyMetricsNeedOnboarding(metrics)}',
                                  );
                                  if (AuthService.bodyMetricsNeedOnboarding(
                                    metrics,
                                  )) {
                                    nextRoute = AppRoutes.onboardRoute;
                                  }
                                } catch (e) {
                                  debugPrint(
                                    '[login] fetchBodyMetrics failed: $e — '
                                    'routing to onboarding to be safe',
                                  );
                                  // If we can't tell, send the user to
                                  // onboarding rather than the empty home —
                                  // they can re-enter and it will be saved.
                                  nextRoute = AppRoutes.onboardRoute;
                                }
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, nextRoute);
                                }
                              } on FirebaseAuthException catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AuthService.friendlyError(e),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', ''),
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Login'),
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
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 50, bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
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
                          builder: (context) => const RegisterSheet(),
                        ),
                      },
                      child: Text(
                        'Sign up',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
