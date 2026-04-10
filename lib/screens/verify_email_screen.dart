// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../services/api_service.dart';
// import '../utils/app_styles.dart';
// import '../widgets/custom_button.dart';

// class VerifyEmailScreen extends StatefulWidget {
//   final String email;

//   const VerifyEmailScreen({super.key, required this.email});

//   @override
//   State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
// }

// class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
//   final List<TextEditingController> _controllers = List.generate(
//     6,
//     (index) => TextEditingController(),
//   );
//   final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
//   final _apiService = ApiService();
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     for (var controller in _controllers) {
//       controller.dispose();
//     }
//     for (var node in _focusNodes) {
//       node.dispose();
//     }
//     super.dispose();
//   }

//   String get _code {
//     return _controllers.map((c) => c.text).join();
//   }

//   Future<void> _verifyEmail() async {
//     if (_code.length != 6) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter the complete code'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     final result = await _apiService.verifyEmail(
//       email: widget.email,
//       code: _code,
//     );

//     if (!mounted) return;

//     setState(() {
//       _isLoading = false;
//     });

//     if (result['success']) {
//       Navigator.of(
//         context,
//       ).pushNamedAndRemoveUntil('/profile-setup', (route) => false);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(result['error'] ?? 'Verification failed'),
//           backgroundColor: AppColors.error,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.arrow_back),
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'VERIFY ACCOUNT',
//                   style: AppTextStyles.heading2.copyWith(
//                     fontSize: 28,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 RichText(
//                   text: TextSpan(
//                     text:
//                         'Verify your account by entering verification code we sent to ',
//                     style: AppTextStyles.bodyMedium.copyWith(
//                       color: AppColors.textSecondary,
//                     ),
//                     children: [
//                       TextSpan(
//                         text: widget.email,
//                         style: const TextStyle(
//                           color: AppColors.textPrimary,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 60),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: List.generate(6, (index) {
//                     return _buildCodeBox(index);
//                   }),
//                 ),
//                 const SizedBox(height: 20),
//                 Center(
//                   child: TextButton(
//                     onPressed: () {
//                       // TODO: Implement resend code
//                     },
//                     child: const Text(
//                       'Resend',
//                       style: TextStyle(
//                         color: AppColors.textPrimary,
//                         fontWeight: FontWeight.bold,
//                         decoration: TextDecoration.underline,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const Spacer(),
//                 CustomButton(
//                   text: 'VERIFY',
//                   onPressed: _verifyEmail,
//                   isLoading: _isLoading,
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCodeBox(int index) {
//     return Container(
//       width: 50,
//       height: 50,
//       decoration: BoxDecoration(
//         color: AppColors.background,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: _controllers[index].text.isNotEmpty
//               ? AppColors.primary
//               : Colors.transparent,
//           width: 2,
//         ),
//       ),
//       child: TextField(
//         controller: _controllers[index],
//         focusNode: _focusNodes[index],
//         textAlign: TextAlign.center,
//         keyboardType: TextInputType.number,
//         maxLength: 1,
//         style: AppTextStyles.heading2,
//         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//         decoration: const InputDecoration(
//           counterText: '',
//           border: InputBorder.none,
//         ),
//         onChanged: (value) {
//           if (value.isNotEmpty && index < 5) {
//             _focusNodes[index + 1].requestFocus();
//           } else if (value.isEmpty && index > 0) {
//             _focusNodes[index - 1].requestFocus();
//           }
//           setState(() {});
//         },
//       ),
//     );
//   }
// }
