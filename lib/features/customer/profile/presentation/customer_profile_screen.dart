import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/auth_providers.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});
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
                const SizedBox(height: 32),
                _ProfileItem(
                  icon: Icons.receipt_long,
                  label: AppStrings.myOrders,
                  onTap: () => context.push('/customer/orders'),
                ),
                const SizedBox(height: 10),
                _ProfileItem(
                  icon: Icons.devices,
                  label: AppStrings.myDevices,
                  onTap: () => context.push('/customer/devices'),
                ),
                const Spacer(),
                _ProfileItem(
                  icon: Icons.logout,
                  label: 'تسجيل الخروج',
                  onTap: () async {
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

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return TammCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.bluePrimary, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.harmattan(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          const Icon(Icons.chevron_left, color: AppColors.textFaint, size: 20),
        ],
      ),
    );
  }
}
