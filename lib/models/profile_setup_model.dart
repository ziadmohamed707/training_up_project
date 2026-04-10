class ProfileSetupModel {
  int? age;
  double? currentWeight;
  double? goalWeight;
  double? height;
  String? fitnessLevel;
  String? goal;
  String? weightUnit; // kg or lbs
  String? heightUnit; // cm or feet

  ProfileSetupModel({
    this.age,
    this.currentWeight,
    this.goalWeight,
    this.height,
    this.fitnessLevel,
    this.goal,
    this.weightUnit = 'kg',
    this.heightUnit = 'cm',
  });

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'current_weight': currentWeight,
      'goal_weight': goalWeight,
      'height': height,
      'fitness_level': fitnessLevel,
      'goal': goal,
      'weight_unit': weightUnit,
      'height_unit': heightUnit,
    };
  }
}
