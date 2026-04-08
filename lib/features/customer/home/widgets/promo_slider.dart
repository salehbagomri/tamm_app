import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

class PromoSection {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String destination;

  const PromoSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.destination,
  });
}

class PromoSlider extends StatefulWidget {
  const PromoSlider({super.key});

  @override
  State<PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<PromoSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<PromoSection> _promos = const [
    PromoSection(
      title: 'اشترِ وركّب في طلب واحد',
      subtitle: 'اختر مكيفك وحدد موعد التركيب',
      icon: Icons.handyman,
      gradientColors: [AppColors.blueDark, AppColors.blueMid],
      destination: '/customer/store',
    ),
    PromoSection(
      title: 'عروض حصرية على المكيفات',
      subtitle: 'خصومات تصل إلى ٢٠٪',
      icon: Icons.local_offer,
      gradientColors: [Color(0xFF0A3540), Color(0xFF0E6C8C)],
      destination: '/customer/store',
    ),
    PromoSection(
      title: 'حلول الطاقة الشمسية',
      subtitle: 'وفّر في فاتورة الكهرباء',
      icon: Icons.solar_power,
      gradientColors: [Color(0xFF0A4020), Color(0xFF0E8C4C)],
      destination: '/customer/services?category=ac_install',
    ),
    PromoSection(
      title: 'صيانة دورية بأسعار منافسة',
      subtitle: 'اطلب صيانة لمكيفك الآن',
      icon: Icons.build_circle,
      gradientColors: [Color(0xFF2A0A40), Color(0xFF5C0E8C)],
      destination: '/customer/services?category=ac_repair',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < _promos.length - 1) {
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
            itemCount: _promos.length,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return _buildPromoBanner(context, promo);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promos.length,
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
    );
  }

  Widget _buildPromoBanner(BuildContext context, PromoSection promo) {
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
