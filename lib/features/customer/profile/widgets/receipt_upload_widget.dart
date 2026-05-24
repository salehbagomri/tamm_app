import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/providers/notification_providers.dart';
import '../../../../shared/providers/order_providers.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

enum _PickSource { gallery, camera, pdf }

class ReceiptUploadWidget extends ConsumerStatefulWidget {
  final String orderId;
  final String orderNumber;
  final String? initialReceiptUrl;

  const ReceiptUploadWidget({
    super.key,
    required this.orderId,
    required this.orderNumber,
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
    final source = await showModalBottomSheet<_PickSource>(
      context: context,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SourcePickerSheet(),
    );
    if (source == null || !mounted) return;

    Uint8List? bytes;
    String ext = 'jpg';

    if (source == _PickSource.pdf) {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.single.bytes == null) return;
      bytes = result.files.single.bytes!;
      ext = 'pdf';
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source == _PickSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      bytes = await picked.readAsBytes();
    }

    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      final url = await ref
          .read(orderRepositoryProvider)
          .uploadReceipt(orderId: widget.orderId, bytes: bytes, extension: ext);

      // Notify manager — non-blocking
      ref
          .read(notificationRepositoryProvider)
          .notifyManagerReceiptUploaded(
            orderId: widget.orderId,
            orderNumber: widget.orderNumber,
          )
          .ignore();

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
              e is AppException ? e.message : 'فشل في رفع السند',
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
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isUploading) {
      return Container(
        width: double.infinity,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          borderRadius: AppSpacing.radiusLg,
          border: Border.all(color: context.colors.border),
        ),
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
      return _buildSuccessCard(context);
    }

    return GestureDetector(
      onTap: _pickAndUpload,
      child: _DashedBorderContainer(
        color: context.colors.bluePrimary,
        child: SizedBox(
          width: double.infinity,
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
                'اضغط لرفع صورة أو ملف PDF',
                style: AppTextStyles.caption(context.colors.textSecond),
              ),
              AppSpacing.gapMd,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.success.withValues(alpha: 0.07),
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(
          color: context.colors.success.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.success,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: context.colors.bgSurface,
              size: AppSpacing.iconLg,
            ),
          ),
          AppSpacing.gapSm2,
          Text(
            'تم إرفاق السند بنجاح ✓',
            style: AppTextStyles.cardTitle(context.colors.success),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapXs,
          Text(
            'سيتم مراجعته من قبل الفريق',
            style: AppTextStyles.bodySmall(context.colors.textSecond),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapMd,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _pickAndUpload,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.colors.success),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppSpacing.radius,
                ),
                minimumSize: const Size(0, AppSpacing.buttonHeightSm),
              ),
              child: Text(
                'استبدال السند',
                style: AppTextStyles.button(context.colors.success),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dashed border container ──────────────────────────────────────────────────

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
        child: Padding(padding: AppSpacing.cardPadding, child: child),
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
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashGap;
      }
      distance = 0;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

// ─── Source picker sheet ──────────────────────────────────────────────────────

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
              'إرفاق السند',
              style: AppTextStyles.cardTitle(context.colors.textPrimary),
            ),
            AppSpacing.gapMd,
            _SourceTile(
              icon: Icons.photo_library_outlined,
              label: 'صورة من المعرض 🖼',
              onTap: () => Navigator.of(context).pop(_PickSource.gallery),
            ),
            AppSpacing.gapSm2,
            _SourceTile(
              icon: Icons.camera_alt_outlined,
              label: 'التقاط صورة 📷',
              onTap: () => Navigator.of(context).pop(_PickSource.camera),
            ),
            AppSpacing.gapSm2,
            _SourceTile(
              icon: Icons.picture_as_pdf_outlined,
              label: 'ملف PDF 📄',
              onTap: () => Navigator.of(context).pop(_PickSource.pdf),
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
            Icon(
              icon,
              color: context.colors.bluePrimary,
              size: AppSpacing.iconMd,
            ),
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
