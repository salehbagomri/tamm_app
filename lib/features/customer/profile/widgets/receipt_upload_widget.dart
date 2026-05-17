import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/providers/order_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class ReceiptUploadWidget extends ConsumerStatefulWidget {
  final String orderId;
  final String? initialReceiptUrl;

  const ReceiptUploadWidget({
    super.key,
    required this.orderId,
    this.initialReceiptUrl,
  });

  @override
  ConsumerState<ReceiptUploadWidget> createState() =>
      _ReceiptUploadWidgetState();
}

class _ReceiptUploadWidgetState extends ConsumerState<ReceiptUploadWidget> {
  bool _isUploading = false;
  String? _receiptUrl;

  @override
  void initState() {
    super.initState();
    _receiptUrl = widget.initialReceiptUrl;
  }

  Future<void> _pickAndUpload() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SourcePickerSheet(),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(orderRepositoryProvider).uploadReceipt(
        orderId: widget.orderId,
        bytes: bytes,
      );
      if (mounted) {
        setState(() {
          _receiptUrl = url;
          _isUploading = false;
        });
        ref.invalidate(orderDetailProvider(widget.orderId));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : 'فشل في رفع الصورة',
              style: AppTextStyles.body(context.colors.bgSurface),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سند التحويل',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        AppSpacing.gapSm,
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUpload,
          child: _DashedBorderContainer(
            color: _receiptUrl != null
                ? context.colors.success
                : context.colors.bluePrimary,
            child: _buildContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isUploading) {
      return SizedBox(
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: context.colors.bluePrimary,
              strokeWidth: 2.5,
            ),
            AppSpacing.gapSm2,
            Text(
              'جاري الرفع...',
              style: AppTextStyles.bodySmall(context.colors.textSecond),
            ),
          ],
        ),
      );
    }

    if (_receiptUrl != null) {
      return SizedBox(
        height: 160,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: AppSpacing.radiusLg,
              child: Image.network(
                _receiptUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _UploadPlaceholder(
                  hasReceipt: true,
                  color: context.colors.success,
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: context.colors.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: context.colors.bgSurface,
                  size: AppSpacing.iconXs,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: context.colors.success.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusLgValue),
                  ),
                ),
                child: Text(
                  'تم رفع السند ✓  —  اضغط للتغيير',
                  style: AppTextStyles.caption(context.colors.bgSurface),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.upload_file_outlined,
            size: AppSpacing.iconXxl,
            color: context.colors.bluePrimary,
          ),
          AppSpacing.gapSm,
          Text(
            'إرفاق سند التحويل',
            style: AppTextStyles.body(
              context.colors.bluePrimary,
            ).copyWith(fontWeight: AppTextStyles.semiBold),
          ),
          AppSpacing.gapXs,
          Text(
            'اضغط لرفع صورة السند',
            style: AppTextStyles.caption(context.colors.textSecond),
          ),
        ],
      ),
    );
  }
}

// ─── Dashed border container ─────────────────────────────────────────────────

class _DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final Color color;

  const _DashedBorderContainer({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: AppSpacing.radiusLg,
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const radius = AppSpacing.radiusLgValue;
    const dashWidth = 6.0;
    const dashGap = 4.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(radius),
        ),
      );

    double distance = 0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end.toDouble()), paint);
        distance += dashWidth + dashGap;
      }
      distance = 0;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

// ─── Source picker bottom sheet ───────────────────────────────────────────────

class _SourcePickerSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppSpacing.sheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: AppSpacing.radiusFull,
              ),
            ),
            AppSpacing.gapMd,
            Text(
              'اختر المصدر',
              style: AppTextStyles.cardTitle(context.colors.textPrimary),
            ),
            AppSpacing.gapMd,
            _SourceTile(
              icon: Icons.photo_library_outlined,
              label: 'من المعرض 🖼',
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            AppSpacing.gapSm2,
            _SourceTile(
              icon: Icons.camera_alt_outlined,
              label: 'التقاط صورة 📷',
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            AppSpacing.gapSm,
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.radiusLg,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.cardPaddingSm,
        decoration: BoxDecoration(
          color: context.colors.bgSurface2,
          borderRadius: AppSpacing.radiusLg,
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.colors.bluePrimary, size: AppSpacing.iconMd),
            AppSpacing.hGapSm2,
            Text(
              label,
              style: AppTextStyles.body(
                context.colors.textPrimary,
              ).copyWith(fontWeight: AppTextStyles.medium),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fallback placeholder ─────────────────────────────────────────────────────

class _UploadPlaceholder extends StatelessWidget {
  final bool hasReceipt;
  final Color color;

  const _UploadPlaceholder({required this.hasReceipt, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          hasReceipt ? Icons.broken_image_outlined : Icons.upload_file_outlined,
          size: AppSpacing.iconXl,
          color: color,
        ),
      ),
    );
  }
}
