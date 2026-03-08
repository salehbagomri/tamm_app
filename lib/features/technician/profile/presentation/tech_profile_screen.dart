import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../shared/providers/auth_providers.dart';

class TechProfileScreen extends ConsumerWidget {
  const TechProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: profileAsync.when(
            data: (p) => Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.blueDark,
                  child: Text(
                    p?.fullName.isNotEmpty == true ? p!.fullName[0] : '?',
                    style: GoogleFonts.harmattan(
                      fontSize: 32,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  p?.fullName ?? '',
                  style: GoogleFonts.harmattan(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  p?.phone ?? '',
                  style: GoogleFonts.harmattan(
                    fontSize: 16,
                    color: AppColors.textSecond,
                  ),
                ),
                const Spacer(),
                TammButton(
                  label: 'تسجيل الخروج',
                  isOutlined: true,
                  icon: Icons.logout,
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ),
    );
  }
}
