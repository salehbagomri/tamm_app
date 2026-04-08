import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/models/promotion.dart';
import '../../../../shared/providers/promotion_providers.dart';
import '../../../../core/widgets/tamm_shimmer.dart';

class PromoSlider extends ConsumerStatefulWidget {
  const PromoSlider({super.key});

  @override
  ConsumerState<PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends ConsumerState<PromoSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  
  // Fallback constant promos in case of error or empty
  final List<Promotion> _fallbackPromos = const [
    Promotion(
      id: 'fallback_1',
      title: 'اشترِ وركّب في طلب واحد',
      subtitle: 'اختر مكيفك وحدد موعد التركيب',
      iconName: 'handyman',
      gradientStart: '#0A3540',
      gradientEnd: '#0E6C8C',
      destination: '/customer/store',
      sortOrder: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer(1); // Default to length 1 initially
  }

  void _startTimer(int length) {
    _timer?.cancel();
    if (length <= 1) return; // Don't slide if 1 or 0 promos
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted) return;
      if (_currentPage < length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(activePromotionsProvider);

    return promosAsync.when(
      data: (promos) {
        final displayPromos = promos.isNotEmpty ? promos : _fallbackPromos;
        
        // Ensure timer understands new length based on state update
        if (_timer == null || !_timer!.isActive && displayPromos.length > 1) {
          _startTimer(displayPromos.length);
        }

        return _buildSlider(context, displayPromos);
      },
      loading: () => const TammShimmer(
        height: 160,
        width: double.infinity,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      error: (_, __) => _buildSlider(context, _fallbackPromos),
    );
  }

  Widget _buildSlider(BuildContext context, List<Promotion> promos) {
    if (promos.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              return _buildPromoBanner(context, promo);
            },
          ),
        ),
        if (promos.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              promos.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.blueSky
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPromoBanner(BuildContext context, Promotion promo) {
    return GestureDetector(
      onTap: () => context.push(promo.destination),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: promo.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppSpacing.radiusLg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    promo.title,
                    style: GoogleFonts.harmattan(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    promo.subtitle,
                    style: GoogleFonts.harmattan(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                promo.icon,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
