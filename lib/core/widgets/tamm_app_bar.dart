import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class TammAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final PreferredSizeWidget? bottom;

  const TammAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: GoogleFonts.harmattan(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      automaticallyImplyLeading: showBack,
      actions: actions,
      bottom: bottom,
    );
  }
}
