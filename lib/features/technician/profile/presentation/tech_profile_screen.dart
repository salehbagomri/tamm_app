import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : 'تعذر تحديث الحالة',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    final statsAsync = ref.watch(techStatsProvider);
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: techProfileAsync.when(
            data: (data) {
              final tech = data['technician'] as Map<String, dynamic>;
              final profile = tech['profiles'] as Map<String, dynamic>;

              final isAvailable = tech['status'] == 'available';
              final fullName = profile['full_name']?.toString() ?? 'غير معروف';
              final phone = profile['phone']?.toString() ?? '';
              final specialization =
                  tech['specialization']?.toString() ?? 'فني';

              return SingleChildScrollView(
                child: Column(
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

                    // بطاقة التخصص
                    Container(
                      width: double.infinity,
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.colors.bluePrimary.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.engineering_outlined,
                              color: context.colors.bluePrimary,
                              size: 22,
                            ),
                          ),
                          AppSpacing.hGapSm2,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'التخصص',
                                style: AppTextStyles.caption(
                                  context.colors.textSecond,
                                ),
                              ),
                              Text(
                                specialization,
                                style: AppTextStyles.body(
                                  context.colors.textPrimary,
                                ).copyWith(fontWeight: AppTextStyles.semiBold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    AppSpacing.gapMd,

                    // إحصاءات الأداء
                    statsAsync.when(
                      loading: () => const SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (stats) => Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إحصاءات الأداء',
                              style: AppTextStyles.bodySmall(
                                context.colors.textSecond,
                              ),
                            ),
                            AppSpacing.gapSm2,
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCell(
                                    label: 'اليوم',
                                    value: stats.today.toString(),
                                    color: context.colors.bluePrimary,
                                  ),
                                ),
                                _VerticalDivider(),
                                Expanded(
                                  child: _StatCell(
                                    label: 'هذا الأسبوع',
                                    value: stats.thisWeek.toString(),
                                    color: context.colors.warning,
                                  ),
                                ),
                                _VerticalDivider(),
                                Expanded(
                                  child: _StatCell(
                                    label: 'الإجمالي',
                                    value: stats.total.toString(),
                                    color: context.colors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    AppSpacing.gapMd,

                    // بطاقة "أرباحي والعمولات" — نقطة الدخول لشاشة الأرباح
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: AppSpacing.radiusLg,
                        onTap: () => context.push('/technician/earnings'),
                        child: Container(
                          width: double.infinity,
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
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.colors.success.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.payments_outlined,
                                  color: context.colors.success,
                                  size: 22,
                                ),
                              ),
                              AppSpacing.hGapSm2,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'أرباحي والعمولات',
                                      style:
                                          AppTextStyles.body(
                                            context.colors.textPrimary,
                                          ).copyWith(
                                            fontWeight: AppTextStyles.semiBold,
                                          ),
                                    ),
                                    Text(
                                      'عرض العمولات المستحقة والمدفوعة',
                                      style: AppTextStyles.caption(
                                        context.colors.textSecond,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_left_outlined,
                                color: context.colors.textFaint,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    AppSpacing.gapMd,
                    const TammThemeSelector(),
                    AppSpacing.gapLg,
                    TammButton(
                      label: 'تسجيل الخروج',
                      type: TammButtonType.secondary,
                      icon: Icons.logout_outlined,
                      onPressed: () =>
                          AuthRepository.confirmSignOut(context, ref),
                    ),
                    AppSpacing.gapMd,
                  ],
                ),
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

// ─── خلية إحصاء ──────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.sectionTitle(color)),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption(context.colors.textSecond),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: context.colors.border);
  }
}
