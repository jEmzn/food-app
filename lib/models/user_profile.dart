class UserProfile {
  String? id;
  final String name;
  final String email;
  final String password;
  final int age;
  final double heightCm;
  final double weightKg;
  final Gender gender;
  final ActivityLevel activityLevel;
  final GoalType goaltype;
  final List<String> dietaryRestrictions;

  UserProfile({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.age = 0,
    this.heightCm = 0.0,
    this.weightKg = 0.0,
    this.gender = Gender.unknown,
    this.activityLevel = ActivityLevel.sedentary,
    this.goaltype = GoalType.maintainWeight,
    this.dietaryRestrictions = const [],
  });

  // Calculate BMI
  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  // Determine Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
  double get bmr {
    if (gender == Gender.male) {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  // Calculate Total Daily Energy Expenditure (TDEE)
  double get tdee {
    double multiplier;
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        multiplier = 1.2;
        break;
      case ActivityLevel.lightlyActive:
        multiplier = 1.375;
        break;
      case ActivityLevel.moderatelyActive:
        multiplier = 1.55;
        break;
      case ActivityLevel.veryActive:
        multiplier = 1.725;
        break;
      case ActivityLevel.extremelyActive:
        multiplier = 1.9;
        break;
      case ActivityLevel.unknown:
        multiplier = 0;
        break;
    }
    return bmr * multiplier;
  }

  // CopyWith for immutability updates
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    int? age,
    double? heightCm,
    double? weightKg,
    Gender? gender,
    ActivityLevel? activityLevel,
    GoalType? goaltype,
    List<String>? dietaryRestrictions,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goaltype: goaltype ?? this.goaltype,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'gender': gender.toString().split('.').last,
      'activityLevel': activityLevel.toString().split('.').last,
      'goaltype': goaltype.toString().split('.').last,
      'dietaryRestrictions': dietaryRestrictions,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      age: map['age']?.toInt() ?? 0,
      heightCm: map['heightCm']?.toDouble() ?? 0.0,
      weightKg: map['weightKg']?.toDouble() ?? 0.0,
      gender: Gender.values.firstWhere(
        (e) => e.toString().split('.').last == map['gender'],
        orElse: () => Gender.male,
      ),
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.toString().split('.').last == map['activityLevel'],
        orElse: () => ActivityLevel.sedentary,
      ),
      goaltype: GoalType.values.firstWhere(
        (e) => e.toString().split('.').last == map['goalType'],
        orElse: () => GoalType.maintainWeight,
      ),
      dietaryRestrictions: List<String>.from(map['dietaryRestrictions'] ?? []),
    );
  }

  @override
  String toString() {
    return '''UserProfile(
      id: $id, 
      name: $name, 
      email: $email,
      password: $password, 
      age: $age, 
      heightCm: $heightCm,
      weightKg: $weightKg, 
      gender: $gender, 
      activityLevel: $activityLevel, 
      goaltype: $goaltype, 
      dietaryRestrictions: $dietaryRestrictions)''';
  }
}

enum Gender { unknown, male, female }

enum ActivityLevel {
  unknown, // Default value for uninitialized state
  sedentary, // Little or no exercise
  lightlyActive, // Light exercise/sports 1-3 days/week
  moderatelyActive, // Moderate exercise/sports 3-5 days/week
  veryActive, // Hard exercise/sports 6-7 days/week
  extremelyActive, // Very hard exercise/physical job
}

enum GoalType { unknown, loseWeight, maintainWeight, gainMuscle }
