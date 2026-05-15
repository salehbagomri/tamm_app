import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../../core/widgets/tamm_theme_selector.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../../../../shared/repositories/auth_repository.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    if (isGuest) {
      return Scaffold(
        backgroundColor: context.colors.bgPrimary,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 80,
                    color: context.colors.textFaint,
                  ),
                  AppSpacing.gapMd,
                  Text(
                    'سجّل دخولك لإدارة حسابك',
                    style: AppTextStyles.body(context.colors.textPrimary),
                  ),
                  AppSpacing.gapLg,
                  TammButton(
                    label: 'تسجيل الدخول',
                    onPressed: () => context.push('/login'),
                  ),
                  AppSpacing.gapSm2,
                  TammButton(
                    label: 'إنشاء حساب',
                    type: TammButtonType.secondary,
                    onPressed: () => context.push('/register'),
                  ),
                  AppSpacing.gapXl,
                  const TammThemeSelector(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(userProfileProvider);
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: profileAsync.when(
              data: (p) => Column(
                children: [
                  const SizedBox(height: 20),
                  if (p?.avatarUrl != null && p!.avatarUrl!.isNotEmpty)
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: context.colors.blueDark,
                      backgroundImage: CachedNetworkImageProvider(p.avatarUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: context.colors.blueDark,
                      child: Text(
                        p?.fullName.isNotEmpty == true ? p!.fullName[0] : '?',
                        style: AppTextStyles.body(context.colors.textPrimary),
                      ),
                    ),
                  AppSpacing.gapSm2,
                  Text(
                    p?.fullName ?? '',
                    style: AppTextStyles.body(context.colors.textPrimary),
                  ),
                  Text(
                    p?.phone ?? '',
                    style: AppTextStyles.body(context.colors.textSecond),
                  ),
                  AppSpacing.gapMd,
                  TammButton(
                    label: 'تعديل الحساب',
                    type: TammButtonType.secondary,
                    icon: Icons.edit_outlined,
                    width: 160,
                    onPressed: () => context.push('/profile/edit'),
                  ),
                  AppSpacing.gapXl,
                  _ProfileItem(
                    icon: Icons.receipt_long_outlined,
                    label: AppStrings.myOrders,
                    onTap: () => context.push('/customer/orders'),
                  ),
                  const SizedBox(height: 10),
                  _ProfileItem(
                    icon: Icons.devices_outlined,
                    label: AppStrings.myDevices,
                    onTap: () => context.push('/customer/devices'),
                  ),
                  const SizedBox(height: 10),
                  const TammThemeSelector(),
                  const Spacer(),
                  _ProfileItem(
                    icon: Icons.logout,
                    label: 'تسجيل الخروج',
                    onTap: () => AuthRepository.confirmSignOut(context, ref),
                  ),
                  AppSpacing.gapMd,
                  TammButton(
                    label: 'حذف الحساب',
                    type: TammButtonType.danger,
                    icon: Icons.delete_forever_outlined,
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                  AppSpacing.gapMd,
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateWidget(
                message: e is AppException
                    ? e.message
                    : 'حدث خطأ في تحميل بيانات الحساب',
                onRetry: () => ref.refresh(userProfileProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgSurface,
        title: Text(
          'حذف الحساب نهائياً',
          style: AppTextStyles.body(context.colors.textPrimary),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء وسيتم مسح كافة البيانات المرتبطة بك.',
          style: AppTextStyles.body(context.colors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'إلغاء',
              style: AppTextStyles.body(context.colors.textSecond),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
            ),
            child: Text('حذف حسابي', style: AppTextStyles.body(Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف حسابك',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
            backgroundColor: context.colors.success,
          ),
        );
        context.go('/customer/home');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : 'حدث خطأ أثناء الحذف',
              style: AppTextStyles.bodySmall(context.colors.textPrimary),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
          Icon(icon, color: context.colors.bluePrimary, size: 22),
          AppSpacing.hGapSm2,
          Text(label, style: AppTextStyles.body(context.colors.textPrimary)),
          const Spacer(),
          Icon(Icons.chevron_left, color: context.colors.textFaint, size: 20),
        ],
      ),
    );
  }
}
