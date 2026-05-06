import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import '../../shared/providers/theme_provider.dart';
import 'tamm_card.dart';

class TammThemeSelector extends ConsumerWidget {
  const TammThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    String getThemeName(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.system: return 'النظام';
        case ThemeMode.light: return 'فاتح';
        case ThemeMode.dark: return 'داكن';
      }
    }

    return TammCard(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: context.colors.bgSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => const _ThemeSelectionSheet(),
        );
      },
      child: Row(
        children: [
          Icon(Icons.dark_mode_outlined, color: context.colors.bluePrimary, size: 22),
          const SizedBox(width: 12),
          Text(
            'مظهر التطبيق',
            style: GoogleFonts.harmattan(
              fontSize: 16,
              color: context.colors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            getThemeName(themeMode),
            style: GoogleFonts.harmattan(
              fontSize: 14,
              color: context.colors.textSecond,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_left, color: context.colors.textFaint, size: 20),
        ],
      ),
    );
  }
}

class _ThemeSelectionSheet extends ConsumerWidget {
  const _ThemeSelectionSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'اختر مظهر التطبيق',
                style: GoogleFonts.harmattan(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildOption(context, ref, 'مظهر النظام', ThemeMode.system, themeMode, Icons.brightness_auto),
            _buildOption(context, ref, 'الوضع الفاتح', ThemeMode.light, themeMode, Icons.light_mode),
            _buildOption(context, ref, 'الوضع الداكن', ThemeMode.dark, themeMode, Icons.dark_mode),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, WidgetRef ref, String title, ThemeMode mode, ThemeMode currentMode, IconData icon) {
    final isSelected = mode == currentMode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? context.colors.bluePrimary : context.colors.textSecond),
      title: Text(
        title,
        style: GoogleFonts.harmattan(
          fontSize: 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? context.colors.bluePrimary : context.colors.textPrimary,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_circle, color: context.colors.bluePrimary) : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).setTheme(mode);
        Navigator.pop(context);
      },
    );
  }
}
