import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/providers/technician_providers.dart';

class TechTaskDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  const TechTaskDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<TechTaskDetailScreen> createState() =>
      _TechTaskDetailScreenState();
}

class _TechTaskDetailScreenState extends ConsumerState<TechTaskDetailScreen> {
  final _notesCtrl = TextEditingController();
  final _notesFocus = FocusNode();
  String? _orderId;
  bool _notesInitialized = false;

  @override
  void initState() {
    super.initState();
    _notesFocus.addListener(_onNotesFocusChange);
  }

  void _onNotesFocusChange() {
    if (!_notesFocus.hasFocus &&
        _notesCtrl.text.trim().isNotEmpty &&
        _orderId != null) {
      ref
          .read(taskUpdateProvider(_orderId!).notifier)
          .saveNotes(_orderId!, _notesCtrl.text.trim());
    }
  }

  @override
  void dispose() {
    _notesFocus.removeListener(_onNotesFocusChange);
    _notesFocus.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ─── Confirmation dialog ──────────────────────────────────────────────────

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusLg,
        ),
        title: Text(
          'تأكيد',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        content: Text(
          message,
          style: AppTextStyles.body(context.colors.textSecond),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'إلغاء',
              style: AppTextStyles.body(context.colors.textSecond),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'تأكيد',
              style: AppTextStyles.body(context.colors.bluePrimary)
                  .copyWith(fontWeight: AppTextStyles.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Status update handlers ───────────────────────────────────────────────

  Future<void> _onStartHeading(String orderId) async {
    final confirmed = await _confirm('هل أنت متأكد أنك بدأت التوجه للعميل؟');
    if (!confirmed || !mounted) return;
    final ok = await ref
        .read(taskUpdateProvider(orderId).notifier)
        .updateStatus(orderId, 'on_the_way');
    if (ok) {
      ref.invalidate(myAssignmentsProvider);
      ref.invalidate(assignmentDetailProvider(widget.assignmentId));
    }
  }

  Future<void> _onStartWork(String orderId) async {
    final confirmed = await _confirm('هل وصلت لموقع العميل وبدأت العمل؟');
    if (!confirmed || !mounted) return;
    final ok = await ref
        .read(taskUpdateProvider(orderId).notifier)
        .updateStatus(orderId, 'in_progress');
    if (ok) {
      ref.invalidate(myAssignmentsProvider);
      ref.invalidate(assignmentDetailProvider(widget.assignmentId));
    }
  }

  Future<void> _onComplete(String orderId) async {
    if (_notesCtrl.text.trim().isNotEmpty) {
      await ref
          .read(taskUpdateProvider(orderId).notifier)
          .saveNotes(orderId, _notesCtrl.text.trim());
    }
    if (!mounted) return;
    final confirmed = await _confirm(
      'هل اكتملت المهمة بالكامل؟ لا يمكن التراجع عن هذا',
    );
    if (!confirmed || !mounted) return;
    final ok = await ref
        .read(taskUpdateProvider(orderId).notifier)
        .updateStatus(orderId, 'completed');
    if (!mounted) return;
    if (ok) {
      ref.invalidate(myAssignmentsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إكمال المهمة بنجاح ✅',
            style: AppTextStyles.body(Colors.white),
          ),
          backgroundColor: context.colors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  // ─── External launches ────────────────────────────────────────────────────

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (!await launchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تعذر فتح تطبيق الاتصال',
                style: AppTextStyles.body(Colors.white),
              ),
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _pickAndUploadPhoto(String assignmentId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1280,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    final ok = await ref
        .read(photoUploadProvider(assignmentId).notifier)
        .upload(assignmentId: assignmentId, bytes: bytes, extension: ext);

    if (!mounted) return;
    if (ok) {
      ref.invalidate(assignmentDetailProvider(widget.assignmentId));
    } else {
      final err = ref.read(photoUploadProvider(assignmentId)).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          err ?? 'فشل رفع الصورة',
          style: AppTextStyles.body(Colors.white),
        ),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _openMaps(String address, {double? lat, double? lng}) async {
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
    } else if (address.isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );
    } else {
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final assignmentAsync =
        ref.watch(assignmentDetailProvider(widget.assignmentId));

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: const TammAppBar(title: 'تفاصيل المهمة'),
      body: assignmentAsync.when(
        loading: () => const TammLoading(),
        error: (e, _) => ErrorStateWidget(
          message: e is AppException ? e.message : 'تعذر تحميل تفاصيل المهمة',
          onRetry: () =>
              ref.invalidate(assignmentDetailProvider(widget.assignmentId)),
        ),
        data: (assignment) {
          final order =
              (assignment['orders'] as Map<String, dynamic>?) ?? {};
          final customer =
              (order['profiles'] as Map<String, dynamic>?) ?? {};
          final customerName =
              customer['full_name']?.toString() ?? 'غير معروف';
          final customerPhone = customer['phone']?.toString() ?? '';
          final address = order['address']?.toString() ?? 'غير متوفر';
          final orderLat = order['latitude'] as double?;
          final orderLng = order['longitude'] as double?;
          final orderNumber = order['order_number']?.toString() ?? '';
          final customerNotes = order['notes']?.toString();
          final orderStatus = order['status']?.toString() ?? 'assigned';
          final orderId = order['id']?.toString() ?? '';
          final orderType = order['order_type']?.toString() ?? 'service';
          final totalAmount =
              (order['total_amount'] as num?)?.toDouble() ?? 0.0;
          final preferredDate = order['preferred_date'] as String?;

          if (orderId.isNotEmpty) _orderId = orderId;

          if (!_notesInitialized && order['technician_notes'] != null) {
            _notesCtrl.text = order['technician_notes'].toString();
            _notesInitialized = true;
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── ملخص الطلب ──────────────────────────────────────
                      _buildOrderSummary(
                        context,
                        orderNumber: orderNumber,
                        orderType: orderType,
                        totalAmount: totalAmount,
                        preferredDate: preferredDate,
                      ),
                      AppSpacing.gapMd,

                      // ── Timeline ─────────────────────────────────────────
                      _buildTimeline(context, orderStatus),
                      AppSpacing.gapMd,

                      // ── بطاقة العميل ─────────────────────────────────────
                      _buildCustomerCard(
                          context, customerName, customerPhone),
                      AppSpacing.gapMd,

                      // ── بطاقة العنوان ────────────────────────────────────
                      _buildAddressCard(
                          context, address, orderLat, orderLng),

                      // ── عناصر الطلب ──────────────────────────────────────
                      if (order['order_items'] != null &&
                          (order['order_items'] as List).isNotEmpty) ...[
                        AppSpacing.gapMd,
                        _buildItemsSection(
                            context, order['order_items'] as List),
                      ],

                      // ── ملاحظات العميل ───────────────────────────────────
                      if (customerNotes != null &&
                          customerNotes.isNotEmpty) ...[
                        AppSpacing.gapMd,
                        _buildCustomerNotes(context, customerNotes),
                      ],

                      // ── صور العمل (أثناء التنفيذ وبعده) ─────────────────
                      if (orderStatus == 'in_progress' ||
                          orderStatus == 'completed') ...[
                        AppSpacing.gapMd,
                        _buildPhotosSection(
                          context,
                          assignmentId: assignment['id'] as String,
                          photoUrls: (assignment['photo_urls'] as List?)
                                  ?.cast<String>() ??
                              [],
                          canAdd: orderStatus == 'in_progress',
                        ),
                      ],

                      // ── ملاحظات الفني (بعد الاكتمال) ────────────────────
                      if (orderStatus == 'completed' &&
                          order['technician_notes'] != null &&
                          (order['technician_notes'] as String)
                              .isNotEmpty) ...[
                        AppSpacing.gapMd,
                        _buildTechNotesSummary(
                            context, order['technician_notes'] as String),
                      ],

                      AppSpacing.gapXl,
                    ],
                  ),
                ),
              ),

              // ── شريط الأفعال ──────────────────────────────────────────────
              if (orderId.isNotEmpty)
                _buildBottomBar(context, orderStatus, orderId),
            ],
          );
        },
      ),
    );
  }

  // ─── ملخص الطلب ──────────────────────────────────────────────────────────

  Widget _buildOrderSummary(
    BuildContext context, {
    required String orderNumber,
    required String orderType,
    required double totalAmount,
    String? preferredDate,
  }) {
    final typeLabel = switch (orderType) {
      'product' => 'منتج',
      'quote_request' => 'عرض سعر',
      _ => 'خدمة',
    };

    final dateStr = preferredDate != null
        ? _formatDate(preferredDate)
        : null;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طلب #$orderNumber',
                style: AppTextStyles.cardTitle(context.colors.textPrimary),
              ),
              if (totalAmount > 0)
                Text(
                  '${totalAmount.toInt()} ر.س',
                  style: AppTextStyles.cardTitle(context.colors.bluePrimary),
                ),
            ],
          ),
          AppSpacing.gapXs,
          Row(
            children: [
              _InfoChip(
                icon: Icons.build_circle_outlined,
                label: typeLabel,
                color: context.colors.bluePrimary,
              ),
              if (dateStr != null) ...[
                AppSpacing.hGapSm,
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: dateStr,
                  color: context.colors.textSecond,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Timeline ─────────────────────────────────────────────────────────────

  Widget _buildTimeline(BuildContext context, String orderStatus) {
    const steps = [
      ('assigned', 'تعيين', Icons.assignment_outlined),
      ('on_the_way', 'في الطريق', Icons.directions_car_outlined),
      ('in_progress', 'جاري التنفيذ', Icons.build_outlined),
      ('completed', 'مكتمل', Icons.task_alt_outlined),
    ];

    final currentIdx = switch (orderStatus) {
      'assigned' => 0,
      'on_the_way' => 1,
      'in_progress' => 2,
      'completed' => 3,
      _ => 0,
    };

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // خط الوصل
          final lineIdx = i ~/ 2;
          final done = lineIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: done
                  ? context.colors.bluePrimary
                  : context.colors.border,
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final (_, label, icon) = steps[stepIdx];
        final isDone = stepIdx < currentIdx;
        final isCurrent = stepIdx == currentIdx;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone || isCurrent
                    ? context.colors.bluePrimary
                    : context.colors.border.withValues(alpha: 0.4),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDone || isCurrent
                    ? Colors.white
                    : context.colors.textFaint,
              ),
            ),
            AppSpacing.gapXs,
            Text(
              label,
              style: AppTextStyles.caption(
                isCurrent
                    ? context.colors.bluePrimary
                    : isDone
                        ? context.colors.textSecond
                        : context.colors.textFaint,
              ).copyWith(
                fontWeight:
                    isCurrent ? AppTextStyles.semiBold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  // ─── بطاقة العميل ────────────────────────────────────────────────────────

  Widget _buildCustomerCard(
      BuildContext context, String name, String phone) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.avatarMd,
            height: AppSpacing.avatarMd,
            decoration: BoxDecoration(
              color: context.colors.bluePrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outlined,
              color: context.colors.bluePrimary,
              size: AppSpacing.iconMd,
            ),
          ),
          AppSpacing.hGapSm2,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body(context.colors.textPrimary)
                      .copyWith(fontWeight: AppTextStyles.semiBold),
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style:
                        AppTextStyles.bodySmall(context.colors.textSecond),
                    textDirection: TextDirection.ltr,
                  )
                else
                  Text(
                    'لا يوجد رقم هاتف',
                    style: AppTextStyles.bodySmall(context.colors.textFaint),
                  ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.call_outlined,
                color: context.colors.success,
                size: AppSpacing.iconMd,
              ),
              onPressed: () => _makePhoneCall(phone),
            ),
        ],
      ),
    );
  }

  // ─── بطاقة العنوان ────────────────────────────────────────────────────────

  Widget _buildAddressCard(
    BuildContext context,
    String address,
    double? lat,
    double? lng,
  ) {
    final hasCoords = lat != null && lng != null;
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.avatarMd,
            height: AppSpacing.avatarMd,
            decoration: BoxDecoration(
              color: context.colors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              color: context.colors.error,
              size: AppSpacing.iconMd,
            ),
          ),
          AppSpacing.hGapSm2,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address,
                  style: AppTextStyles.body(context.colors.textPrimary),
                ),
                if (hasCoords) ...[
                  AppSpacing.gapXs,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.success.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.radiusFull,
                    ),
                    child: Text(
                      '📍 موقع GPS متوفر',
                      style:
                          AppTextStyles.caption(context.colors.success),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              hasCoords
                  ? Icons.navigation_outlined
                  : Icons.map_outlined,
              color: hasCoords
                  ? context.colors.success
                  : context.colors.bluePrimary,
              size: AppSpacing.iconMd,
            ),
            tooltip: hasCoords ? 'ابدأ الملاحة' : 'فتح الخرائط',
            onPressed: () => _openMaps(address, lat: lat, lng: lng),
          ),
        ],
      ),
    );
  }

  // ─── عناصر الطلب ──────────────────────────────────────────────────────────

  Widget _buildItemsSection(BuildContext context, List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'العناصر المطلوب تنفيذها',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        AppSpacing.gapSm,
        ...items.map((item) {
          final isProduct = item['item_type'] == 'product';
          final includeInst = item['include_installation'] ?? false;

          // اسم الخدمة أو المنتج الفعلي
          final serviceName = (item['service_types'] as Map<String, dynamic>?)?['name'] as String?;
          final productName = (item['products'] as Map<String, dynamic>?)?['name'] as String?;
          final itemName = isProduct
              ? (productName ?? 'منتج')
              : (serviceName ?? 'خدمة');

          final qty = item['quantity'] as int? ?? 1;
          final unitPrice = (item['unit_price'] as num?)?.toDouble();

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: AppSpacing.cardPaddingSm,
              decoration: BoxDecoration(
                color: context.colors.bgSurface,
                borderRadius: AppSpacing.radiusLg,
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colors.bluePrimary
                          .withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isProduct
                          ? Icons.inventory_2_outlined
                          : Icons.build_outlined,
                      color: context.colors.bluePrimary,
                      size: 16,
                    ),
                  ),
                  AppSpacing.hGapSm2,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: AppTextStyles.body(
                            context.colors.textPrimary,
                          ).copyWith(fontWeight: AppTextStyles.semiBold),
                        ),
                        Row(
                          children: [
                            Text(
                              'الكمية: $qty',
                              style: AppTextStyles.caption(
                                context.colors.textSecond,
                              ),
                            ),
                            if (includeInst) ...[
                              AppSpacing.hGapSm,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colors.success
                                      .withValues(alpha: 0.1),
                                  borderRadius: AppSpacing.radiusFull,
                                ),
                                child: Text(
                                  'شامل التركيب',
                                  style: AppTextStyles.caption(
                                    context.colors.success,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (unitPrice != null && unitPrice > 0)
                    Text(
                      '${unitPrice.toInt()} ر.س',
                      style: AppTextStyles.bodySmall(
                        context.colors.textSecond,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── صور العمل ───────────────────────────────────────────────────────────

  Widget _buildPhotosSection(
    BuildContext context, {
    required String assignmentId,
    required List<String> photoUrls,
    required bool canAdd,
  }) {
    final uploadState = ref.watch(photoUploadProvider(assignmentId));
    final isUploading = uploadState.status == PhotoUploadStatus.uploading;
    const maxPhotos = 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'صور إنجاز العمل',
              style: AppTextStyles.cardTitle(context.colors.textPrimary),
            ),
            if (canAdd && photoUrls.length < maxPhotos)
              TextButton.icon(
                onPressed: isUploading
                    ? null
                    : () => _pickAndUploadPhoto(assignmentId),
                icon: isUploading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.bluePrimary,
                        ),
                      )
                    : Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 18,
                        color: context.colors.bluePrimary,
                      ),
                label: Text(
                  isUploading ? 'جاري الرفع...' : 'إضافة صورة',
                  style: AppTextStyles.bodySmall(context.colors.bluePrimary),
                ),
              ),
          ],
        ),
        AppSpacing.gapSm,
        if (photoUrls.isEmpty)
          Container(
            width: double.infinity,
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: AppSpacing.radiusLg,
              border: Border.all(
                color: context.colors.border,
                style: canAdd ? BorderStyle.solid : BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: 32,
                  color: context.colors.textFaint,
                ),
                AppSpacing.gapXs,
                Text(
                  canAdd ? 'أضف صورة لتوثيق العمل' : 'لا توجد صور مرفوعة',
                  style: AppTextStyles.bodySmall(context.colors.textFaint),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoUrls.length,
              separatorBuilder: (_, __) => AppSpacing.hGapSm2,
              itemBuilder: (_, i) => _PhotoThumb(url: photoUrls[i]),
            ),
          ),
      ],
    );
  }

  // ─── ملاحظات العميل ───────────────────────────────────────────────────────

  Widget _buildCustomerNotes(BuildContext context, String notes) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.speaker_notes_outlined,
            color: context.colors.textSecond,
            size: AppSpacing.iconXs + 2,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظات العميل:',
                  style: AppTextStyles.body(context.colors.textPrimary)
                      .copyWith(fontWeight: AppTextStyles.semiBold),
                ),
                AppSpacing.gapXs,
                Text(
                  notes,
                  style: AppTextStyles.body(context.colors.textSecond),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ملاحظات الفني بعد الإكمال ───────────────────────────────────────────

  Widget _buildTechNotesSummary(BuildContext context, String notes) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.success.withValues(alpha: 0.06),
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(
          color: context.colors.success.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.fact_check_outlined,
            color: context.colors.success,
            size: AppSpacing.iconXs + 2,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظات الفني:',
                  style: AppTextStyles.body(context.colors.textPrimary)
                      .copyWith(fontWeight: AppTextStyles.semiBold),
                ),
                AppSpacing.gapXs,
                Text(
                  notes,
                  style: AppTextStyles.body(context.colors.textSecond),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── شريط الأفعال ────────────────────────────────────────────────────────

  Widget _buildBottomBar(
    BuildContext context,
    String orderStatus,
    String orderId,
  ) {
    final submitState = ref.watch(taskUpdateProvider(orderId));
    final isLoading = submitState.status == TaskUpdateStatus.loading;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                LinearProgressIndicator(
                  color: context.colors.bluePrimary,
                  backgroundColor: context.colors.border,
                ),
                AppSpacing.gapSm,
              ],
              if (submitState.errorMessage != null) ...[
                Text(
                  submitState.errorMessage!,
                  style: AppTextStyles.bodySmall(context.colors.error),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapSm,
              ],
              _buildStatusAction(context, orderStatus, orderId, isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAction(
    BuildContext context,
    String orderStatus,
    String orderId,
    bool isLoading,
  ) {
    return switch (orderStatus) {
      'assigned' => _GradientButton(
        label: 'بدأت التوجه 🚗',
        gradient: LinearGradient(
          colors: [context.colors.bluePrimary, context.colors.blueMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        isLoading: isLoading,
        onPressed: isLoading ? null : () => _onStartHeading(orderId),
      ),
      'on_the_way' => _GradientButton(
        label: 'وصلت وبدأت العمل 🔧',
        gradient: LinearGradient(
          colors: [
            context.colors.warning,
            context.colors.warning.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        isLoading: isLoading,
        onPressed: isLoading ? null : () => _onStartWork(orderId),
      ),
      'in_progress' => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TammTextField(
            controller: _notesCtrl,
            focusNode: _notesFocus,
            label: 'ملاحظات ميدانية',
            hint: 'اكتب ملاحظاتك عن العمل المنجز...',
            maxLines: 4,
          ),
          AppSpacing.gapMd,
          _GradientButton(
            label: 'اكتملت المهمة ✅',
            gradient: LinearGradient(
              colors: [
                context.colors.success,
                context.colors.success.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            isLoading: isLoading,
            onPressed: isLoading ? null : () => _onComplete(orderId),
          ),
        ],
      ),
      'completed' => Container(
        width: double.infinity,
        padding: AppSpacing.cardPaddingSm,
        decoration: BoxDecoration(
          color: context.colors.success.withValues(alpha: 0.1),
          borderRadius: AppSpacing.radiusLg,
          border: Border.all(
            color: context.colors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outlined,
              color: context.colors.success,
              size: AppSpacing.iconMd,
            ),
            AppSpacing.hGapSm,
            Text(
              '✅ تم إنجاز هذه المهمة',
              style: AppTextStyles.body(context.colors.success)
                  .copyWith(fontWeight: AppTextStyles.semiBold),
            ),
          ],
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ─── Photo Thumb ─────────────────────────────────────────────────────────────

class _PhotoThumb extends StatelessWidget {
  final String url;
  const _PhotoThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreen(context),
      child: ClipRRect(
        borderRadius: AppSpacing.radiusLg,
        child: Image.network(
          url,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  width: 120,
                  height: 120,
                  color: context.colors.bgSurface,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.bluePrimary,
                    ),
                  ),
                ),
          errorBuilder: (_, __, ___) => Container(
            width: 120,
            height: 120,
            color: context.colors.bgSurface,
            child: Icon(
              Icons.broken_image_outlined,
              color: context.colors.textFaint,
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption(color),
        ),
      ],
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GradientButton({
    required this.label,
    required this.gradient,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: AppSpacing.radiusLg,
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppSpacing.radiusLg,
        ),
        child: InkWell(
          borderRadius: AppSpacing.radiusLg,
          onTap: isLoading ? null : onPressed,
          child: SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeight,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: AppSpacing.iconMd,
                      height: AppSpacing.iconMd,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: AppTextStyles.button(Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
