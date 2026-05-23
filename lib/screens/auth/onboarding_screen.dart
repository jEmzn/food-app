import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app1/config/api_config.dart';
import 'package:app1/models/body_metrics.dart';
import 'package:app1/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app1/config/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  Sex? _selectedSex;
  DateTime? _selectedDob;
  double? _height;
  double? _weight;
  ActivityLevel? _selectedActivityLevel;
  GoalType? _selectedGoal;

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  static const String _baseUrl = ApiConfig.baseUrl;
  static const Color buttonColor = AppTheme.primaryColor;

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    switch (_currentPage) {
      case 0:
        _height = double.tryParse(_heightController.text);
        _weight = double.tryParse(_weightController.text);

        if (_selectedSex != null &&
            _selectedDob != null &&
            _height != null &&
            _weight != null) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'กรุณาเลือกเพศ วันเกิด ส่วนสูง และน้ำหนัก',
              ),
            ),
          );
        }
        break;
      case 1:
        if (_selectedActivityLevel != null) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('กรุณาเลือกระดับกิจกรรมเพื่อดำเนินการต่อ'),
            ),
          );
        }
        break;
      case 2:
        if (_selectedGoal != null) {
          _finishOnboarding();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('กรุณาเลือกประเภทเป้าหมายเพื่อดำเนินการต่อ')),
          );
        }
      default:
        setState(() => _currentPage++);
        break;
    }
  }

  void onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: 'เลือกวันเกิด',
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _finishOnboarding() async {
    if (_isSubmitting) return;

    final metrics = BodyMetrics(
      sex: _selectedSex!,
      dob: _selectedDob,
      heightCm: _height!,
      weightKg: _weight!,
      activityLevel: _selectedActivityLevel!,
      goalType: _selectedGoal!,
    );

    setState(() => _isSubmitting = true);
    try {
      final token = await AuthService.getToken();
      final response = await http
          .post(
            Uri.parse('$_baseUrl/users/body-metrics'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(metrics.toMap()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'บันทึกข้อมูลไม่สำเร็จ (${response.statusCode}) กรุณาลองใหม่อีกครั้ง',
              ),
            ),
          );
          print('Error response: ${response.body}');
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ไม่สามารถบันทึกข้อมูลได้ กรุณาตรวจสอบการเชื่อมต่อแล้วลองใหม่อีกครั้ง',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getActivityDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'ออกกำลังกายเล็กน้อยหรือไม่ออกเลย';
      case ActivityLevel.lightlyActive:
        return 'ออกกำลังกายเบา ๆ 1-3 วัน/สัปดาห์';
      case ActivityLevel.moderatelyActive:
        return 'ออกกำลังกายปานกลาง 3-5 วัน/สัปดาห์';
      case ActivityLevel.veryActive:
        return 'ออกกำลังกายหนัก 6-7 วัน/สัปดาห์';
      case ActivityLevel.extremelyActive:
        return 'ออกกำลังกายหนักมาก และทำงานที่ใช้แรงกาย หรือฝึกซ้อม 2 รอบ/วัน';
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
                },
              )
            : null,
        title: Text(
          'ขั้นตอนที่ ${_currentPage + 1} จาก 3',
          style: GoogleFonts.mali(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
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
                onPressed: _isSubmitting ? null : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: AppTheme.backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: GoogleFonts.mali(fontSize: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_currentPage < 2 ? 'ถัดไป' : 'เสร็จสิ้น'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'บอกเราเกี่ยวกับตัวคุณ',
            style: GoogleFonts.mali(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'ข้อมูลนี้จะช่วยให้เราปรับประสบการณ์ให้เหมาะกับคุณ',
            style: GoogleFonts.mali(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            'ส่วนสูง (ซม.)',
            'กรอกส่วนสูงของคุณ',
            'ซม.',
            _heightController,
            TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'น้ำหนัก (กก.)',
            'กรอกน้ำหนักของคุณ',
            'กก.',
            _weightController,
            TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildDobAndGenderRow(),
        ],
      ),
    );
  }

  Widget _buildDobAndGenderRow() {
    final dobLabel = _selectedDob != null
        ? '${_selectedDob!.day.toString().padLeft(2, '0')}/'
            '${_selectedDob!.month.toString().padLeft(2, '0')}/'
            '${_selectedDob!.year}'
        : 'เลือกวันที่';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'วันเกิด',
                style: GoogleFonts.mali(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDob,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        dobLabel,
                        style: GoogleFonts.mali(
                          fontSize: 14,
                          color: _selectedDob != null
                              ? Colors.black
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เพศ',
              style: GoogleFonts.mali(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedSex == Sex.male
                        ? Colors.blue[400]
                        : Colors.white,
                    foregroundColor: _selectedSex == Sex.male
                        ? Colors.white
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  onPressed: () => setState(() => _selectedSex = Sex.male),
                  child: const Icon(Icons.male_outlined, size: 24),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedSex == Sex.female
                        ? Colors.pink[400]
                        : Colors.white,
                    foregroundColor: _selectedSex == Sex.female
                        ? Colors.white
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  onPressed: () => setState(() => _selectedSex = Sex.female),
                  child: const Icon(Icons.female_outlined, size: 24),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityLevelPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ระดับกิจกรรม',
            style: GoogleFonts.mali(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'ในแต่ละวันคุณเคลื่อนไหวมากแค่ไหน?',
            style: GoogleFonts.mali(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ...ActivityLevel.values.where((l) => l != ActivityLevel.unknown).map(
            (level) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedActivityLevel = level),
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
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.label,
                                style: GoogleFonts.mali(
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
                                style: GoogleFonts.mali(
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
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เป้าหมายของคุณ',
            style: GoogleFonts.mali(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'คุณต้องการบรรลุเป้าหมายอะไร?',
            style: GoogleFonts.mali(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: GoalType.values
                  .where((g) => g != GoalType.unknown)
                  .map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGoal = goal),
                        child: Container(
                          padding: const EdgeInsets.all(16),
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
                              goal.label,
                              style: GoogleFonts.mali(
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
          style: GoogleFonts.mali(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
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
}
