class BodyMetrics {
  final Sex sex;
  final double heightCm;
  final double weightKg;
  final DateTime? dob;
  final ActivityLevel activityLevel;
  final GoalType goalType;
  final List<String> dietaryRestrictions;

  const BodyMetrics({
    this.sex = Sex.unknown,
    this.heightCm = 0.0,
    this.weightKg = 0.0,
    this.dob,
    this.activityLevel = ActivityLevel.sedentary,
    this.goalType = GoalType.maintainWeight,
    this.dietaryRestrictions = const [],
  });

  int get age {
    if (dob == null) return 0;
    final now = DateTime.now();
    int years = now.year - dob!.year;
    if (now.month < dob!.month ||
        (now.month == dob!.month && now.day < dob!.day)) {
      years--;
    }
    return years;
  }

  double get bmi {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  double get bmr {
    if (sex == Sex.male) {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    }
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
  }

  double get tdee {
    const multipliers = {
      ActivityLevel.sedentary: 1.2,
      ActivityLevel.lightlyActive: 1.375,
      ActivityLevel.moderatelyActive: 1.55,
      ActivityLevel.veryActive: 1.725,
      ActivityLevel.extremelyActive: 1.9,
    };
    // Fall back to sedentary multiplier for unknown — TDEE of 0 is nonsensical.
    return bmr * (multipliers[activityLevel] ?? 1.2);
  }

  // Maps to the user_body_metrics table schema.
  Map<String, dynamic> toMap() {
    return {
      'sex': _pascal(sex.name),
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'dob': dob?.toIso8601String().split('T').first,
      'activity_level': _pascal(activityLevel.name),
      'goal_type': _pascal(goalType.name),
      'dietary_restrictions': dietaryRestrictions.join(','),
    };
  }

  factory BodyMetrics.fromMap(Map<String, dynamic> map) {
    return BodyMetrics(
      sex: Sex.values.firstWhere(
        (e) => _pascal(e.name) == map['sex'],
        orElse: () => Sex.unknown,
      ),
      // Postgres returns `numeric` columns as strings (e.g. "170.00") to
      // preserve precision. _toDouble handles both num and String inputs.
      heightCm: _toDouble(map['height_cm']),
      weightKg: _toDouble(map['weight_kg']),
      dob: map['dob'] != null ? DateTime.parse(map['dob'] as String) : null,
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => _pascal(e.name) == map['activity_level'],
        orElse: () => ActivityLevel.sedentary,
      ),
      goalType: GoalType.values.firstWhere(
        (e) => _pascal(e.name) == map['goal_type'],
        orElse: () => GoalType.maintainWeight,
      ),
      dietaryRestrictions: map['dietary_restrictions'] != null
          ? (map['dietary_restrictions'] as String)
              .split(',')
              .where((s) => s.isNotEmpty)
              .toList()
          : [],
    );
  }

  BodyMetrics copyWith({
    Sex? sex,
    double? heightCm,
    double? weightKg,
    DateTime? dob,
    ActivityLevel? activityLevel,
    GoalType? goalType,
    List<String>? dietaryRestrictions,
  }) {
    return BodyMetrics(
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      dob: dob ?? this.dob,
      activityLevel: activityLevel ?? this.activityLevel,
      goalType: goalType ?? this.goalType,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
    );
  }

  @override
  String toString() => 'BodyMetrics(sex: $sex, heightCm: $heightCm, '
      'weightKg: $weightKg, dob: $dob, activityLevel: $activityLevel, '
      'goalType: $goalType, dietaryRestrictions: $dietaryRestrictions)';
}

String _pascal(String s) => s[0].toUpperCase() + s.substring(1);

// Accepts a num, a numeric String ("170.00"), or null. Returns 0.0 on
// anything unparseable so the UI can still render with a safe default.
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

enum Sex { unknown, male, female }

enum ActivityLevel {
  unknown,
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extremelyActive,
}

enum GoalType { unknown, loseWeight, maintainWeight, gainMuscle }

// ---- Thai display labels ----------------------------------------------------
//
// IMPORTANT: these are for SHOWING the value on screen only. The raw enum
// `.name` (e.g. "sedentary", "loseWeight") is still what gets sent to and
// parsed from the backend in toMap()/fromMap(). Never swap the backend code
// to use these labels, or the API calls will break.

extension SexLabel on Sex {
  String get label {
    switch (this) {
      case Sex.male:
        return 'ชาย';
      case Sex.female:
        return 'หญิง';
      case Sex.unknown:
        return 'ไม่ระบุ';
    }
  }
}

extension ActivityLevelLabel on ActivityLevel {
  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'ไม่ค่อยเคลื่อนไหว';
      case ActivityLevel.lightlyActive:
        return 'เคลื่อนไหวเล็กน้อย';
      case ActivityLevel.moderatelyActive:
        return 'เคลื่อนไหวปานกลาง';
      case ActivityLevel.veryActive:
        return 'เคลื่อนไหวมาก';
      case ActivityLevel.extremelyActive:
        return 'เคลื่อนไหวมากที่สุด';
      case ActivityLevel.unknown:
        return 'ไม่ระบุ';
    }
  }
}

extension GoalTypeLabel on GoalType {
  String get label {
    switch (this) {
      case GoalType.loseWeight:
        return 'ลดน้ำหนัก';
      case GoalType.maintainWeight:
        return 'รักษาน้ำหนัก';
      case GoalType.gainMuscle:
        return 'เพิ่มกล้ามเนื้อ';
      case GoalType.unknown:
        return 'ไม่ระบุ';
    }
  }
}
