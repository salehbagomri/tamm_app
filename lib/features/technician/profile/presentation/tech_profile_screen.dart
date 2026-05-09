import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/repositories/auth_repository.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../shared/providers/manager_providers.dart';
import '../../../../shared/providers/technician_providers.dart';
import '../../../../core/widgets/tamm_theme_selector.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class TechProfileScreen extends ConsumerStatefulWidget {
  const TechProfileScreen({super.key});

  @override
  ConsumerState<TechProfileScreen> createState() => _TechProfileScreenState();
}

class _TechProfileScreenState extends ConsumerState<TechProfileScreen> {
  bool _isToggling = false;

  Future<void> _toggleAvailability(bool isAvailable) async {
    setState(() => _isToggling = true);
    try {
      await ref
          .read(technicianRepositoryProvider)
          .updateMyAvailability(isAvailable);
      ref.invalidate(myTechnicianProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تحديث الحالة: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final techProfileAsync = ref.watch(myTechnicianProfileProvider);
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: techProfileAsync.when(
            data: (data) {
              final tech = data['technician'] as Map<String, dynamic>;
              final profile = tech['profiles'] as Map<String, dynamic>;
              final completedCount = data['completed_count'] as int;

              final isAvailable = tech['status'] == 'available';
              final fullName = profile['full_name']?.toString() ?? 'غير معروف';
              final phone = profile['phone']?.toString() ?? '';
              final specialization =
                  tech['specialization']?.toString() ?? 'فني';

              return Column(
                children: [
                  const SizedBox(height: 20),
                  if (profile['avatar_url'] != null &&
                      profile['avatar_url'].toString().isNotEmpty)
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: context.colors.blueDark,
                      backgroundImage: CachedNetworkImageProvider(
                        profile['avatar_url'].toString(),
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: context.colors.blueDark,
                      child: Text(
                        fullName.isNotEmpty ? fullName[0] : '?',
                        style: AppTextStyles.body(context.colors.textPrimary),
                      ),
                    ),
                  AppSpacing.gapSm2,
                  Text(
                    fullName,
                    style: AppTextStyles.body(context.colors.textPrimary),
                  ),
                  Text(
                    phone,
                    style: AppTextStyles.body(context.colors.textSecond),
                  ),
                  AppSpacing.gapLg,

                  // Status Toggle Card
                  Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: context.colors.bgSurface,
                      borderRadius: AppSpacing.radiusLg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الحالة الحالية',
                              style: AppTextStyles.body(
                                context.colors.textSecond,
                              ),
                            ),
                            Text(
                              isAvailable
                                  ? 'متاح لاستلام المهام'
                                  : 'غير متاح حالياً',
                              style: AppTextStyles.body(
                                context.colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        _isToggling
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Switch(
                                value: isAvailable,
                                activeThumbColor: context.colors.success,
                                onChanged: _toggleAvailability,
                              ),
                      ],
                    ),
                  ),

                  AppSpacing.gapMd,

                  // Stats Card
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: AppSpacing.cardPadding,
                          decoration: BoxDecoration(
                            color: context.colors.bgSurface,
                            borderRadius: AppSpacing.radiusLg,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.engineering_rounded,
                                color: context.colors.bluePrimary,
                                size: 32,
                              ),
                              AppSpacing.gapSm,
                              Text(
                                'التخصص',
                                style: AppTextStyles.body(
                                  context.colors.textSecond,
                                ),
                              ),
                              Text(
                                specialization,
                                style: AppTextStyles.body(
                                  context.colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Container(
                          padding: AppSpacing.cardPadding,
                          decoration: BoxDecoration(
                            color: context.colors.bgSurface,
                            borderRadius: AppSpacing.radiusLg,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.task_alt_rounded,
                                color: context.colors.success,
                                size: 32,
                              ),
                              AppSpacing.gapSm,
                              Text(
                                'المهام المنجزة',
                                style: AppTextStyles.body(
                                  context.colors.textSecond,
                                ),
                              ),
                              Text(
                                completedCount.toString(),
                                style: AppTextStyles.body(
                                  context.colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  AppSpacing.gapMd,
                  const TammThemeSelector(),
                  const Spacer(),
                  TammButton(
                    label: 'تسجيل الخروج',
                    type: TammButtonType.secondary,
                    icon: Icons.logout,
                    onPressed: () =>
                        AuthRepository.confirmSignOut(context, ref),
                  ),
                  AppSpacing.gapMd,
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateWidget(
              message: e is AppException
                  ? e.message
                  : 'حدث خطأ في تحميل الملف الشخصي',
              onRetry: () => ref.invalidate(myTechnicianProfileProvider),
            ),
          ),
        ),
      ),
    );
  }
}
