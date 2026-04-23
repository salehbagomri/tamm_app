import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';

/// يتحقق من تسجيل الدخول. إذا Guest → يعرض Bottom Sheet ويُرجع false.
Future<bool> requireAuth(BuildContext context, WidgetRef ref) async {
  if (Supabase.instance.client.auth.currentUser != null) return true;

  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textFaint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.lock_outline, color: AppColors.blueSky, size: 48),
            const SizedBox(height: 16),
            Text(
              'سجّل دخولك للمتابعة',
              style: GoogleFonts.harmattan(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تحتاج تسجيل الدخول للإضافة للسلة وإتمام الطلبات',
              style: GoogleFonts.harmattan(fontSize: 14, color: AppColors.textSecond),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bluePrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('تسجيل الدخول',
                  style: GoogleFonts.harmattan(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('لاحقاً',
                style: GoogleFonts.harmattan(fontSize: 14, color: AppColors.textSecond)),
            ),
          ],
        ),
      ),
    ),
  );
  return false;
}
