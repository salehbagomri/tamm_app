import 'package:flutter/material.dart';
import '../constants/app_text_styles.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

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
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.sectionTitle(context.colors.textPrimary),
      ),
      automaticallyImplyLeading: showBack,
      actions: actions,
      bottom: bottom,
    );
  }
}
