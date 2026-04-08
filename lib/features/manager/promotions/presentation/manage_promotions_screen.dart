import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../shared/providers/promotion_providers.dart';

class ManagePromotionsScreen extends ConsumerWidget {
  const ManagePromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(allPromotionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text(
          'إدارة العروض (السلايدر)',
          style: GoogleFonts.harmattan(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.bgSurface,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.bluePrimary,
        child: const Icon(Icons.add),
        onPressed: () => context.push('/manager/promotion/form'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الترتيب الحالي للعروض',
                style: GoogleFonts.harmattan(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: promosAsync.when(
                  data: (promos) {
                    if (promos.isEmpty) {
                      return const TammEmptyState(
                        icon: Icons.campaign,
                        message: 'لا توجد عروض مضافة',
                      );
                    }
                    return ListView.separated(
                      itemCount: promos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = promos[i];
                        return TammCard(
                          onTap: () => context.push(
                            '/manager/promotion/form',
                            extra: p,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: p.gradientColors),
                                  borderRadius: AppSpacing.radiusSm,
                                ),
                                child: Icon(p.icon, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.title,
                                      style: GoogleFonts.harmattan(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      p.subtitle,
                                      style: GoogleFonts.harmattan(
                                        fontSize: 14,
                                        color: AppColors.textSecond,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: p.isActive,
                                onChanged: (v) async {
                                  await ref
                                      .read(promotionRepositoryProvider)
                                      .updatePromotion(p.id, {'is_active': v});
                                  ref.invalidate(allPromotionsProvider);
                                  ref.invalidate(activePromotionsProvider);
                                },
                                activeColor: AppColors.success,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const TammLoading(),
                  error: (e, _) => TammEmptyState(
                      icon: Icons.error_outline, message: '$e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
