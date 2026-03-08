import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/tamm_button.dart';
import '../../../shared/providers/auth_providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;

  Future<void> _verifyOtp() async {
    if (_otpController.text.length < 6) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.verifyOtp(widget.phone, _otpController.text.trim());

      final profile = await repo.getProfile();
      if (!mounted) return;

      switch (profile?.role) {
        case 'manager':
          context.go('/manager/dashboard');
        case 'technician':
          context.go('/technician/tasks');
        default:
          context.go('/customer/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('رمز التحقق غير صحيح')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text(
          AppStrings.verifyBtn,
          style: GoogleFonts.harmattan(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sms_outlined,
              size: 64,
              color: AppColors.bluePrimary,
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.otpSent,
              style: GoogleFonts.harmattan(
                fontSize: 18,
                color: AppColors.textSecond,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.phone,
              style: GoogleFonts.harmattan(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: GoogleFonts.harmattan(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 12,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '------',
                hintStyle: GoogleFonts.harmattan(
                  fontSize: 32,
                  color: AppColors.textFaint,
                  letterSpacing: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
            TammButton(
              label: AppStrings.verifyBtn,
              isLoading: _loading,
              onPressed: _verifyOtp,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
