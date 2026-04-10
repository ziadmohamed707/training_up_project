import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/api_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_styles.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfileScreen({super.key, this.initialData = const {}});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _weightController;
  late final TextEditingController _targetWeightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;

  String _weightUnit = 'KG';
  String _heightUnit = 'CM';
  String _gender = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    _fullNameController = TextEditingController(
      text: (data['full_name'] ?? 'Yasso').toString(),
    );
    _phoneController = TextEditingController(
      text: (data['phone'] ?? '+966 543214321').toString(),
    );
    _emailController = TextEditingController(
      text: (data['email'] ?? 'Yasso@gmail.com').toString(),
    );
    _weightController = TextEditingController(
      text: (data['weight'] ?? '55').toString(),
    );
    _targetWeightController = TextEditingController(
      text: (data['goal_weight'] ?? data['goal'] ?? '60').toString(),
    );
    _heightController = TextEditingController(
      text: (data['height'] ?? '170').toString(),
    );
    _ageController = TextEditingController(
      text: (data['age'] ?? '21').toString(),
    );

    final wUnit = (data['weight_unit'] ?? 'kg').toString().toUpperCase();
    final hUnit = (data['height_unit'] ?? 'cm').toString().toUpperCase();
    if (wUnit == 'LBS' || wUnit == 'KG') _weightUnit = wUnit;
    if (hUnit == 'FEET' || hUnit == 'CM') _heightUnit = hUnit;
    _gender = (data['gender'] ?? 'Female').toString();

    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    try {
      final box = Hive.box(AppConstants.hiveAppBox);
      final raw = box.get(AppConstants.keyCachedProfileData);
      if (raw is! Map) return;

      final data = Map<String, dynamic>.from(raw);
      if (data.isEmpty || !mounted) return;

      _fullNameController.text = (data['full_name'] ?? _fullNameController.text)
          .toString();
      _phoneController.text = (data['phone'] ?? _phoneController.text)
          .toString();
      _emailController.text = (data['email'] ?? _emailController.text)
          .toString();
      _weightController.text = (data['weight'] ?? _weightController.text)
          .toString();
      _targetWeightController.text =
          (data['goal_weight'] ?? _targetWeightController.text).toString();
      _heightController.text = (data['height'] ?? _heightController.text)
          .toString();
      _ageController.text = (data['age'] ?? _ageController.text).toString();

      final wUnit = (data['weight_unit'] ?? '').toString().toUpperCase();
      final hUnit = (data['height_unit'] ?? '').toString().toUpperCase();
      final gender = (data['gender'] ?? '').toString().trim();

      setState(() {
        if (wUnit == 'LBS' || wUnit == 'KG') {
          _weightUnit = wUnit;
        }
        if (hUnit == 'FEET' || hUnit == 'CM') {
          _heightUnit = hUnit;
        }
        if (gender.isNotEmpty) {
          _gender = gender;
        }
      });
    } catch (e) {
      debugPrint('Edit profile hive load failed: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      'EDIT PROFILE',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6C20D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 72,
                        color: Color(0xFF6E5720),
                      ),
                    ),
                    Positioned(
                      bottom: 28,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.52),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _label('Full Name'),
              _field(_fullNameController, suffix: const Icon(Icons.check)),
              _label('Phone'),
              _field(_phoneController, keyboardType: TextInputType.phone),
              _label('Email address'),
              _field(
                _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _label('Weight'),
              _field(
                _weightController,
                keyboardType: TextInputType.number,
                suffix: _unitSwitcher(
                  left: 'LBS',
                  right: 'KG',
                  selected: _weightUnit,
                  onChanged: (value) => setState(() => _weightUnit = value),
                ),
              ),
              _label('Target Weight'),
              _field(
                _targetWeightController,
                keyboardType: TextInputType.number,
                suffix: _unitSwitcher(
                  left: 'LBS',
                  right: 'KG',
                  selected: _weightUnit,
                  onChanged: (value) => setState(() => _weightUnit = value),
                ),
              ),
              _label('Height'),
              _field(
                _heightController,
                keyboardType: TextInputType.number,
                suffix: _unitSwitcher(
                  left: 'FEET',
                  right: 'CM',
                  selected: _heightUnit,
                  onChanged: (value) => setState(() => _heightUnit = value),
                ),
              ),
              _label('Gender'),
              _genderField(),
              _label('Age'),
              _field(_ageController, keyboardType: TextInputType.number),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8CCFE3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'SAVE',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Text(
        text,
        style: AppTextStyles.bodyLarge.copyWith(
          fontSize: 30,
          color: const Color(0xFF343434),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        border: Border.all(color: const Color(0xFFD8D8D8)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          suffixIcon: suffix,
        ),
      ),
    );
  }

  Widget _genderField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        border: Border.all(color: const Color(0xFFD8D8D8)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.transgender),
        title: Text(_gender, style: AppTextStyles.bodyLarge),
        trailing: const Icon(Icons.keyboard_arrow_down),
        onTap: () async {
          final value = await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            builder: (ctx) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ['Female', 'Male']
                      .map(
                        (item) => ListTile(
                          title: Text(item),
                          trailing: item == _gender
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(ctx).pop(item),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          );

          if (value == null) return;
          setState(() {
            _gender = value;
          });
        },
      ),
    );
  }

  Widget _unitSwitcher({
    required String left,
    required String right,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    Widget item(String label) {
      final active = selected == label;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(label),
          child: Container(
            height: 34,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFD0D0D0) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 120,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFECECEC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [item(left), item(right)]),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final api = ApiService();

      // Parse age and weight
      final age = int.tryParse(_ageController.text) ?? 21;
      final weight = num.tryParse(_weightController.text) ?? 55;
      final height = num.tryParse(_heightController.text) ?? 170;

      // Call API to update profile with all fields
      await api.updateProfile(
        phone: _phoneController.text,
        email: _emailController.text,
        fullName: _fullNameController.text,
        age: age,
        weight: weight,
        height: height,
        goal: null, // Goal can be added later in a separate update
      );

      final updatedData = <String, dynamic>{
        ...widget.initialData,
        'full_name': _fullNameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'current_weight': _weightController.text,
        'goal_weight': _targetWeightController.text,
        'height': _heightController.text,
        'weight_unit': _weightUnit.toLowerCase(),
        'height_unit': _heightUnit.toLowerCase(),
        'gender': _gender,
        'age': _ageController.text,
      };

      final box = Hive.box(AppConstants.hiveAppBox);
      await box.put(
        AppConstants.keyCachedProfileData,
        Map<String, dynamic>.from(updatedData),
      );
      // Save local-only fields separately so API cache refresh cannot erase them
      await box.put(AppConstants.keyLocalProfileExtras, <String, dynamic>{
        'gender': _gender,
        'goal_weight': _targetWeightController.text,
        'weight_unit': _weightUnit.toLowerCase(),
        'height_unit': _heightUnit.toLowerCase(),
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop(updatedData);
    } catch (e) {
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
