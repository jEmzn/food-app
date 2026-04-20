import 'package:app1/data/daos/user_doa.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app1/models/user_profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app1/config/app_theme.dart';

/*
  Stateful Widget for Onboarding Screen
  methods to include:
  - dispose()
    - Dispose controllers to prevent memory leaks
  - nextPage()
    - Navigate to the next page in the PageView
  - build()
    - Scaffold with AppBar and PageView
 */

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Temporary State Viariables
  Gender? _selectedGender;
  int? _age;
  double? _height;
  double? _weight;
  ActivityLevel? _selectedActivityLevel;
  GoalType? _selectedGoal;

  // Text Editing Controllers
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  static const Color buttonColor = AppTheme.primaryColor;

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    switch (_currentPage) {
      case 0:
        // get and save measurements
        _height = double.tryParse(_heightController.text);
        _weight = double.tryParse(_weightController.text);
        _age = int.tryParse(_ageController.text);

        setState(() {
          _age = _age;
          _height = _height;
          _weight = _weight;
        });

        if (_selectedGender != null &&
            _age != null &&
            _height != null &&
            _weight != null) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please select gender and enter valid age, height, and weight',
              ),
            ),
          );
        }
        break;
      case 1:
        // Validate activity level
        if (_selectedActivityLevel != null) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select activity level to proceed'),
            ),
          );
        }
        break;
      case 2:
        // Validate goal type
        if (_selectedGoal != null) {
          _finishOnboarding();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select goal type to proceed')),
          );
        }

      default:
        setState(() {
          _currentPage++;
        });
        break;
    }
  }

  void onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _finishOnboarding() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final profile = UserProfile(
      id: firebaseUser?.uid ?? '',
      name: firebaseUser?.displayName ?? '',
      email: firebaseUser?.email ?? '',
      password: '',
      age: _age!,
      heightCm: _height!,
      weightKg: _weight!,
      gender: _selectedGender!,
      activityLevel: _selectedActivityLevel!,
      goaltype: _selectedGoal!,
    );

    await UserDOA().insertUser(profile);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  String _formatEnum(String enumString) {
    return enumString.split('.').last.replaceAll('_', ' ');
  }

  String _getActivityDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Little or no exercise';
      case ActivityLevel.lightlyActive:
        return 'Light exercise/sports 1-3 days/week';
      case ActivityLevel.moderatelyActive:
        return 'Moderate exercise/sports 3-5 days/week';
      case ActivityLevel.veryActive:
        return 'Hard exercise/sports 6-7 days a week';
      case ActivityLevel.extremelyActive:
        return 'Very hard exercise/sports & physical job or 2x training';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  setState(() {
                    _currentPage--;
                  });
                },
              )
            : null,
        title: Text(
          'Step ${_currentPage + 1} of 3',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // body: Center(child: Text('Onboarding Screen')),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: onPageChanged,
              children: [
                _buildMeasurementPage(),
                _buildActivityLevelPage(),
                _buildGoalTypePage(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: AppTheme.backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: GoogleFonts.inter(fontSize: 16),
                ),
                child: Text(_currentPage < 2 ? 'Next' : 'Finish'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementPage() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about yourself',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This information will help us personalize your experience',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          _buildTextField(
            'Height (cm)',
            'Enter your height',
            'cm',
            _heightController,
            TextInputType.number,
          ),
          SizedBox(height: 16),
          _buildTextField(
            'Weight (kg)',
            'Enter your weight',
            'kg',
            _weightController,
            TextInputType.number,
          ),
          SizedBox(height: 16),
          _ageAndGenderCard(),
        ],
      ),
    );
  }

  Widget _buildActivityLevelPage() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Level',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'How active are you on a daily basis?',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ...ActivityLevel.values.map(
            (level) => Padding(
              padding: EdgeInsetsGeometry.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedActivityLevel = level;
                }),
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedActivityLevel == level
                        ? buttonColor
                        : AppTheme.backgroundColor,
                    border: Border.all(
                      color: _selectedActivityLevel == level
                          ? buttonColor
                          : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatEnum(level.toString()),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: _selectedActivityLevel == level
                                      ? AppTheme.backgroundColor
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getActivityDescription(level),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _selectedActivityLevel == level
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedActivityLevel == level)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.check_circle,
                              color: AppTheme.backgroundColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTypePage() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Goal',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'What so you want to achieve?',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: GoalType.values
                  .map(
                    (goal) => Padding(
                      padding: EdgeInsetsGeometry.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGoal = goal),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedGoal == goal
                                ? buttonColor
                                : AppTheme.backgroundColor,
                            border: Border.all(
                              color: _selectedGoal == goal
                                  ? buttonColor
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              _formatEnum(goal.toString()),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: _selectedGoal == goal
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    String suffix,
    TextEditingController controller,
    TextInputType inputType,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _ageAndGenderCard() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Age',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter your age',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _age = int.tryParse(value);
                  });
                },
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gender',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[100]!,
                    // spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedGender == Gender.male
                          ? Colors.blue[400]
                          : Colors.white,
                      foregroundColor: _selectedGender == Gender.male
                          ? Colors.white
                          : Colors.grey,
                      padding: EdgeInsets.only(top: 15, bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedGender = Gender.male;
                      });
                    },
                    child: Icon(Icons.male_outlined, size: 24),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedGender == Gender.female
                          ? Colors.pink[400]
                          : Colors.white,
                      foregroundColor: _selectedGender == Gender.female
                          ? Colors.white
                          : Colors.grey,
                      padding: EdgeInsets.only(top: 15, bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedGender = Gender.female;
                      });
                    },
                    child: Icon(Icons.female_outlined, size: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
