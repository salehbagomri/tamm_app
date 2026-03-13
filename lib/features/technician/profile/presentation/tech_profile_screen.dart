import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/repositories/auth_repository.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../shared/providers/manager_providers.dart';
import '../../../../shared/providers/technician_providers.dart';

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
      backgroundColor: AppColors.bgPrimary,
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
                  if (profile['avatar_url'] != null && profile['avatar_url'].toString().isNotEmpty)
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.blueDark,
                      backgroundImage: CachedNetworkImageProvider(profile['avatar_url'].toString()),
                    )
                  else
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.blueDark,
                      child: Text(
                        fullName.isNotEmpty ? fullName[0] : '?',
                        style: GoogleFonts.harmattan(
                          fontSize: 32,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    fullName,
                    style: GoogleFonts.harmattan(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    phone,
                    style: GoogleFonts.harmattan(
                      fontSize: 16,
                      color: AppColors.textSecond,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status Toggle Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
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
                              style: GoogleFonts.harmattan(
                                fontSize: 16,
                                color: AppColors.textSecond,
                              ),
                            ),
                            Text(
                              isAvailable
                                  ? 'متاح لاستلام المهام'
                                  : 'غير متاح حالياً',
                              style: GoogleFonts.harmattan(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isAvailable
                                    ? AppColors.success
                                    : AppColors.warning,
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
                                activeThumbColor: AppColors.success,
                                onChanged: _toggleAvailability,
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats Card
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
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
                              const Icon(
                                Icons.engineering_rounded,
                                color: AppColors.bluePrimary,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'التخصص',
                                style: GoogleFonts.harmattan(
                                  color: AppColors.textSecond,
                                ),
                              ),
                              Text(
                                specialization,
                                style: GoogleFonts.harmattan(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
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
                              const Icon(
                                Icons.task_alt_rounded,
                                color: AppColors.success,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'المهام المنجزة',
                                style: GoogleFonts.harmattan(
                                  color: AppColors.textSecond,
                                ),
                              ),
                              Text(
                                completedCount.toString(),
                                style: GoogleFonts.harmattan(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                  TammButton(
                    label: 'تسجيل الخروج',
                    type: TammButtonType.secondary,
                    icon: Icons.logout,
                    onPressed: () => AuthRepository.confirmSignOut(context, ref),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('حدث خطأ: $e')),
          ),
        ),
      ),
    );
  }
}
