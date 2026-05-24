import 'dart:typed_data';
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
  bool _cashCollected = false;
  bool _cashCollecting = false;
  bool _cashInitialized = false;

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
          .saveNotes(widget.assignmentId, _notesCtrl.text.trim());
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
        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.radiusLg),
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
              style: AppTextStyles.body(
                context.colors.bluePrimary,
              ).copyWith(fontWeight: AppTextStyles.bold),
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

  Future<void> _onComplete(String orderId, String paymentType) async {
    // P0.1: للطلبات النقدية، لا يُسمح بالإكمال قبل تأكيد استلام المبلغ.
    if (paymentType == 'cash' && !_cashCollected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أكّد استلام المبلغ النقدي أولاً قبل إكمال المهمة',
            style: AppTextStyles.body(Colors.white),
          ),
          backgroundColor: context.colors.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_notesCtrl.text.trim().isNotEmpty) {
      await ref
          .read(taskUpdateProvider(orderId).notifier)
          .saveNotes(widget.assignmentId, _notesCtrl.text.trim());
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
      ref.invalidate(completedAssignmentsProvider);
      ref.invalidate(techStatsProvider);
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

  Future<void> _confirmCashCollected() async {
    final confirmed = await _confirm('هل استلمت المبلغ النقدي من العميل؟');
    if (!confirmed || !mounted) return;
    setState(() => _cashCollecting = true);
    try {
      await ref
          .read(technicianTaskRepositoryProvider)
          .confirmCashCollected(widget.assignmentId);
      if (mounted) {
        setState(() {
          _cashCollected = true;
          _cashCollecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تأكيد استلام المبلغ ✅',
              style: AppTextStyles.body(Colors.white),
            ),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cashCollecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل تأكيد استلام المبلغ',
              style: AppTextStyles.body(Colors.white),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  // ─── منظومة رفع الصور ────────────────────────────────────────────────────

  Future<void> _addPhotosFlow(String assignmentId, int remainingSlots) async {
    if (remainingSlots <= 0) return;

    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PhotoSourceSheet(remainingSlots: remainingSlots),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final List<XFile> picked = [];

    if (source == _PhotoSource.camera) {
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (shot != null) picked.add(shot);
    } else {
      final many = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
      );
      picked.addAll(many.take(remainingSlots));
    }

    if (picked.isEmpty || !mounted) return;

    // معاينة وتأكيد قبل الرفع
    final confirmed = await _showPreviewSheet(picked);
    if (confirmed == null || confirmed.isEmpty || !mounted) return;

    final files = <({Uint8List bytes, String extension})>[];
    for (final x in confirmed) {
      final bytes = await x.readAsBytes();
      final ext = x.name.contains('.')
          ? x.name.split('.').last.toLowerCase()
          : 'jpg';
      files.add((bytes: bytes, extension: ext));
    }

    final count = await ref
        .read(photoUploadProvider(assignmentId).notifier)
        .uploadBatch(assignmentId: assignmentId, files: files);

    if (!mounted) return;
    ref.invalidate(assignmentDetailProvider(widget.assignmentId));

    final state = ref.read(photoUploadProvider(assignmentId));
    if (count == files.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 1 ? 'تم رفع الصورة' : 'تم رفع $count صور',
            style: AppTextStyles.body(Colors.white),
          ),
          backgroundColor: context.colors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.errorMessage ?? 'فشل رفع الصور',
            style: AppTextStyles.body(Colors.white),
          ),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<List<XFile>?> _showPreviewSheet(List<XFile> initial) async {
    return showModalBottomSheet<List<XFile>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PhotoPreviewSheet(initial: initial),
    );
  }

  Future<void> _confirmAndDeletePhoto(String assignmentId, String url) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgSurface,
        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.radiusLg),
        title: Text(
          'حذف الصورة',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        content: Text(
          'هل تريد حذف هذه الصورة نهائياً؟',
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
              'حذف',
              style: AppTextStyles.body(
                context.colors.error,
              ).copyWith(fontWeight: AppTextStyles.bold),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final success = await ref
        .read(photoUploadProvider(assignmentId).notifier)
        .remove(assignmentId: assignmentId, url: url);

    if (!mounted) return;
    if (success) {
      ref.invalidate(assignmentDetailProvider(widget.assignmentId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حذف الصورة',
            style: AppTextStyles.body(Colors.white),
          ),
          backgroundColor: context.colors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل حذف الصورة',
            style: AppTextStyles.body(Colors.white),
          ),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final assignmentAsync = ref.watch(
      assignmentDetailProvider(widget.assignmentId),
    );

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
          final order = (assignment['orders'] as Map<String, dynamic>?) ?? {};
          final customer = (order['profiles'] as Map<String, dynamic>?) ?? {};
          final customerName = customer['full_name']?.toString() ?? 'غير معروف';
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
          final paymentType = order['payment_type']?.toString() ?? 'cash';
          final contactPhone = order['contact_phone']?.toString() ?? '';
          final scheduledPeriod = order['scheduled_period']?.toString();
          final scheduledHour = order['scheduled_hour']?.toString();
          final managerNotes = assignment['manager_notes']?.toString();
          final cashCollectedDb =
              assignment['cash_collected'] as bool? ?? false;

          if (orderId.isNotEmpty) _orderId = orderId;

          if (!_cashInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _cashCollected = cashCollectedDb;
                  _cashInitialized = true;
                });
              }
            });
          }

          // يظهر زر تأكيد النقد فقط بعد وصول الفني وبدء العمل (لا في on_the_way).
          final showCashCard =
              paymentType == 'cash' &&
              (orderStatus == 'in_progress' || orderStatus == 'completed');

          if (!_notesInitialized && assignment['technician_notes'] != null) {
            _notesCtrl.text = assignment['technician_notes'].toString();
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
                        hasInstall:
                            (order['include_installation'] as bool? ?? false) ||
                            ((order['order_items'] as List?) ?? const []).any(
                              (item) =>
                                  (item
                                      as Map<
                                        String,
                                        dynamic
                                      >)['include_installation'] ==
                                  true,
                            ),
                        preferredDate: preferredDate,
                        scheduledPeriod: scheduledPeriod,
                        scheduledHour: scheduledHour,
                      ),
                      AppSpacing.gapMd,

                      // ── تعليمات المشرف (خاصة بالفني) ────────────────────
                      if (managerNotes != null && managerNotes.isNotEmpty) ...[
                        _buildManagerNotes(context, managerNotes),
                        AppSpacing.gapMd,
                      ],

                      // ── Timeline ─────────────────────────────────────────
                      _buildTimeline(context, orderStatus),
                      AppSpacing.gapMd,

                      // ── بطاقة العميل ─────────────────────────────────────
                      _buildCustomerCard(
                        context,
                        customerName,
                        customerPhone,
                        contactPhone,
                      ),
                      AppSpacing.gapMd,

                      // ── بطاقة العنوان ────────────────────────────────────
                      _buildAddressCard(context, address, orderLat, orderLng),

                      // ── عناصر الطلب ──────────────────────────────────────
                      if (order['order_items'] != null &&
                          (order['order_items'] as List).isNotEmpty) ...[
                        AppSpacing.gapMd,
                        _buildItemsSection(
                          context,
                          order['order_items'] as List,
                        ),
                      ],

                      // ── ملاحظات العميل ───────────────────────────────────
                      if (customerNotes != null &&
                          customerNotes.isNotEmpty) ...[
                        AppSpacing.gapMd,
                        _buildCustomerNotes(context, customerNotes),
                      ],

                      // ── الدفع النقدي عند الاستلام ────────────────────────
                      if (showCashCard) ...[
                        AppSpacing.gapMd,
                        _buildCashPaymentCard(context, totalAmount),
                      ],

                      // ── صور العمل (أثناء التنفيذ وبعده) ─────────────────
                      if (orderStatus == 'in_progress' ||
                          orderStatus == 'completed') ...[
                        AppSpacing.gapMd,
                        _buildPhotosSection(
                          context,
                          assignmentId: assignment['id'] as String,
                          photoUrls:
                              (assignment['photo_urls'] as List?)
                                  ?.cast<String>() ??
                              [],
                          canAdd: orderStatus == 'in_progress',
                        ),
                      ],

                      // ── ملاحظات الفني بعد الإكمال ────────────────────────
                      if (orderStatus == 'completed' &&
                          assignment['technician_notes'] != null &&
                          (assignment['technician_notes'] as String)
                              .isNotEmpty) ...[
                        AppSpacing.gapMd,
                        _buildTechNotesSummary(
                          context,
                          assignment['technician_notes'] as String,
                        ),
                      ],

                      AppSpacing.gapXl,
                    ],
                  ),
                ),
              ),

              // ── شريط الأفعال ──────────────────────────────────────────────
              if (orderId.isNotEmpty)
                _buildBottomBar(context, orderStatus, orderId, paymentType),
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
    required bool hasInstall,
    String? preferredDate,
    String? scheduledPeriod,
    String? scheduledHour,
  }) {
    final typeLabel = switch (orderType) {
      'product' => hasInstall ? 'توصيل وتركيب منتج' : 'توصيل منتج',
      'product_and_service' => 'منتج مع تركيب',
      'quote_request' => 'عرض سعر',
      'service' => 'خدمة',
      _ => 'مهمة',
    };

    final dateStr = preferredDate != null ? _formatDate(preferredDate) : null;
    final hasAppointment =
        scheduledPeriod != null &&
        scheduledHour != null &&
        scheduledPeriod.isNotEmpty &&
        scheduledHour.isNotEmpty;

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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _InfoChip(
                icon: Icons.build_circle_outlined,
                label: typeLabel,
                color: context.colors.bluePrimary,
              ),
              if (dateStr != null)
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: dateStr,
                  color: context.colors.textSecond,
                ),
              if (hasAppointment)
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  label: '$scheduledHour $scheduledPeriod',
                  color: context.colors.textSecond,
                ),
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
              color: done ? context.colors.bluePrimary : context.colors.border,
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
              style:
                  AppTextStyles.caption(
                    isCurrent
                        ? context.colors.bluePrimary
                        : isDone
                        ? context.colors.textSecond
                        : context.colors.textFaint,
                  ).copyWith(
                    fontWeight: isCurrent
                        ? AppTextStyles.semiBold
                        : FontWeight.normal,
                  ),
            ),
          ],
        );
      }),
    );
  }

  // ─── بطاقة العميل ────────────────────────────────────────────────────────

  Widget _buildCustomerCard(
    BuildContext context,
    String name,
    String phone,
    String contactPhone,
  ) {
    // Prefer contact_phone from order if present and different from profile phone
    final showContact = contactPhone.isNotEmpty && contactPhone != phone;
    final displayPhone = showContact ? contactPhone : phone;
    final hasPhone = displayPhone.isNotEmpty;

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
                  style: AppTextStyles.body(
                    context.colors.textPrimary,
                  ).copyWith(fontWeight: AppTextStyles.semiBold),
                ),
                if (hasPhone)
                  Text(
                    displayPhone,
                    style: AppTextStyles.bodySmall(context.colors.textSecond),
                    textDirection: TextDirection.ltr,
                  )
                else
                  Text(
                    'لا يوجد رقم هاتف',
                    style: AppTextStyles.bodySmall(context.colors.textFaint),
                  ),
                if (showContact && phone.isNotEmpty)
                  Text(
                    'رقم الملف: $phone',
                    style: AppTextStyles.caption(context.colors.textFaint),
                    textDirection: TextDirection.ltr,
                  ),
              ],
            ),
          ),
          if (hasPhone)
            IconButton(
              icon: Icon(
                Icons.call_outlined,
                color: context.colors.success,
                size: AppSpacing.iconMd,
              ),
              onPressed: () => _makePhoneCall(displayPhone),
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
                      style: AppTextStyles.caption(context.colors.success),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              hasCoords ? Icons.navigation_outlined : Icons.map_outlined,
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
          final serviceName =
              (item['service_types'] as Map<String, dynamic>?)?['name']
                  as String?;
          final productName =
              (item['products'] as Map<String, dynamic>?)?['name'] as String?;
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
                      color: context.colors.bluePrimary.withValues(alpha: 0.08),
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
                                  color: context.colors.success.withValues(
                                    alpha: 0.1,
                                  ),
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
                      style: AppTextStyles.bodySmall(context.colors.textSecond),
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

  static const _maxPhotos = 6;

  Widget _buildPhotosSection(
    BuildContext context, {
    required String assignmentId,
    required List<String> photoUrls,
    required bool canAdd,
  }) {
    final uploadState = ref.watch(photoUploadProvider(assignmentId));
    final isUploading = uploadState.status == PhotoUploadStatus.uploading;
    final remaining = _maxPhotos - photoUrls.length;
    final canStillAdd = canAdd && remaining > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'صور إنجاز العمل',
              style: AppTextStyles.cardTitle(context.colors.textPrimary),
            ),
            AppSpacing.hGapSm,
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.colors.bgSurface2,
                borderRadius: AppSpacing.radiusFull,
              ),
              child: Text(
                '${photoUrls.length} / $_maxPhotos',
                style: AppTextStyles.caption(context.colors.textSecond),
              ),
            ),
            const Spacer(),
            if (canStillAdd)
              TextButton.icon(
                onPressed: isUploading
                    ? null
                    : () => _addPhotosFlow(assignmentId, remaining),
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
                        Icons.add_a_photo_outlined,
                        size: 18,
                        color: context.colors.bluePrimary,
                      ),
                label: Text(
                  isUploading
                      ? 'جاري الرفع ${uploadState.done}/${uploadState.total}'
                      : 'إضافة',
                  style: AppTextStyles.bodySmall(context.colors.bluePrimary),
                ),
              ),
          ],
        ),
        AppSpacing.gapSm,
        if (photoUrls.isEmpty)
          _EmptyPhotosCard(
            canAdd: canStillAdd,
            isUploading: isUploading,
            onAdd: () => _addPhotosFlow(assignmentId, remaining),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoUrls.length,
              separatorBuilder: (_, __) => AppSpacing.hGapSm2,
              itemBuilder: (_, i) => _PhotoThumb(
                url: photoUrls[i],
                onLongPress: canAdd
                    ? () => _confirmAndDeletePhoto(assignmentId, photoUrls[i])
                    : null,
              ),
            ),
          ),
        if (canAdd && photoUrls.isNotEmpty) ...[
          AppSpacing.gapXs,
          Text(
            '💡 اضغط مطوّلاً على الصورة للحذف',
            style: AppTextStyles.caption(context.colors.textFaint),
          ),
        ],
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
                  style: AppTextStyles.body(
                    context.colors.textPrimary,
                  ).copyWith(fontWeight: AppTextStyles.semiBold),
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

  // ─── تعليمات المشرف ───────────────────────────────────────────────────────

  Widget _buildManagerNotes(BuildContext context, String notes) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.warning.withValues(alpha: 0.08),
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(
          color: context.colors.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: context.colors.warning,
            size: AppSpacing.iconXs + 2,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعليمات المشرف:',
                  style: AppTextStyles.body(
                    context.colors.textPrimary,
                  ).copyWith(fontWeight: AppTextStyles.semiBold),
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

  // ─── بطاقة الدفع النقدي ───────────────────────────────────────────────────

  Widget _buildCashPaymentCard(BuildContext context, double totalAmount) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: _cashCollected
            ? context.colors.success.withValues(alpha: 0.06)
            : context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(
          color: _cashCollected
              ? context.colors.success.withValues(alpha: 0.3)
              : context.colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                color: _cashCollected
                    ? context.colors.success
                    : context.colors.warning,
                size: AppSpacing.iconXs + 2,
              ),
              AppSpacing.hGapSm,
              Text(
                'الدفع النقدي عند الاستلام',
                style: AppTextStyles.body(
                  context.colors.textPrimary,
                ).copyWith(fontWeight: AppTextStyles.semiBold),
              ),
              const Spacer(),
              if (totalAmount > 0)
                Text(
                  '${totalAmount.toInt()} ر.س',
                  style: AppTextStyles.cardTitle(context.colors.bluePrimary),
                ),
            ],
          ),
          AppSpacing.gapSm,
          if (_cashCollected)
            Row(
              children: [
                Icon(
                  Icons.check_circle_outlined,
                  color: context.colors.success,
                  size: 16,
                ),
                AppSpacing.hGapXs,
                Text(
                  'تم استلام المبلغ النقدي',
                  style: AppTextStyles.bodySmall(context.colors.success),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cashCollecting ? null : _confirmCashCollected,
                icon: _cashCollecting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.bluePrimary,
                        ),
                      )
                    : Icon(
                        Icons.check_outlined,
                        size: 16,
                        color: context.colors.bluePrimary,
                      ),
                label: Text(
                  _cashCollecting
                      ? 'جاري التأكيد...'
                      : 'تأكيد استلام المبلغ النقدي',
                  style: AppTextStyles.bodySmall(context.colors.bluePrimary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.colors.bluePrimary),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.radiusLg,
                  ),
                ),
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
                  style: AppTextStyles.body(
                    context.colors.textPrimary,
                  ).copyWith(fontWeight: AppTextStyles.semiBold),
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
    String paymentType,
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
              _buildStatusAction(
                context,
                orderStatus,
                orderId,
                isLoading,
                paymentType,
              ),
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
    String paymentType,
  ) {
    final blockedForCash = paymentType == 'cash' && !_cashCollected;
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TammTextField(
            controller: _notesCtrl,
            focusNode: _notesFocus,
            label: 'ملاحظات ميدانية',
            hint: 'اكتب ملاحظاتك عن العمل المنجز...',
            maxLines: 4,
          ),
          AppSpacing.gapMd,
          if (blockedForCash) ...[
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: context.colors.warning,
                ),
                AppSpacing.hGapXs,
                Expanded(
                  child: Text(
                    'أكّد استلام المبلغ النقدي أولاً لإكمال المهمة',
                    style: AppTextStyles.caption(context.colors.warning),
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
          ],
          _GradientButton(
            label: blockedForCash
                ? 'أكّد استلام النقد أولاً'
                : 'اكتملت المهمة ✅',
            gradient: blockedForCash
                ? LinearGradient(
                    colors: [
                      context.colors.textFaint,
                      context.colors.textFaint.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      context.colors.success,
                      context.colors.success.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            isLoading: isLoading,
            onPressed: (isLoading || blockedForCash)
                ? null
                : () => _onComplete(orderId, paymentType),
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
              style: AppTextStyles.body(
                context.colors.success,
              ).copyWith(fontWeight: AppTextStyles.semiBold),
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
  final VoidCallback? onLongPress;
  const _PhotoThumb({required this.url, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showFullScreen(context),
          onLongPress: onLongPress,
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
        ),
        if (onLongPress != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onLongPress,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_outlined,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
      ],
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

// ─── Empty photos card ────────────────────────────────────────────────────────

class _EmptyPhotosCard extends StatelessWidget {
  final bool canAdd;
  final bool isUploading;
  final VoidCallback onAdd;
  const _EmptyPhotosCard({
    required this.canAdd,
    required this.isUploading,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 36,
            color: context.colors.textFaint,
          ),
          AppSpacing.gapSm,
          Text(
            canAdd ? 'وثّق العمل بصور قبل الإنهاء' : 'لا توجد صور مرفوعة',
            style: AppTextStyles.bodySmall(context.colors.textSecond),
            textAlign: TextAlign.center,
          ),
          if (canAdd) ...[
            AppSpacing.gapSm,
            OutlinedButton.icon(
              onPressed: isUploading ? null : onAdd,
              icon: Icon(
                Icons.add_a_photo_outlined,
                size: 18,
                color: context.colors.bluePrimary,
              ),
              label: Text(
                'التقط أول صورة',
                style: AppTextStyles.bodySmall(context.colors.bluePrimary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.colors.bluePrimary),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppSpacing.radiusLg,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Source picker bottom sheet ───────────────────────────────────────────────

enum _PhotoSource { camera, gallery }

class _PhotoSourceSheet extends StatelessWidget {
  final int remainingSlots;
  const _PhotoSourceSheet({required this.remainingSlots});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'أضف صورة لتوثيق العمل',
              style: AppTextStyles.cardTitle(context.colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXs,
            Text(
              'يمكنك إضافة حتى $remainingSlots ${remainingSlots == 1 ? "صورة" : "صور"} إضافية',
              style: AppTextStyles.caption(context.colors.textSecond),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapMd,
            _SourceOption(
              icon: Icons.photo_camera_outlined,
              label: 'الكاميرا',
              hint: 'التقط صورة الآن',
              color: context.colors.bluePrimary,
              onTap: () => Navigator.of(context).pop(_PhotoSource.camera),
            ),
            AppSpacing.gapSm,
            _SourceOption(
              icon: Icons.photo_library_outlined,
              label: 'المعرض',
              hint: 'اختر صوراً (متعدد)',
              color: context.colors.success,
              onTap: () => Navigator.of(context).pop(_PhotoSource.gallery),
            ),
            AppSpacing.gapSm,
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: AppTextStyles.body(context.colors.textSecond),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final Color color;
  final VoidCallback onTap;
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.hint,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.radiusLg,
        onTap: onTap,
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: AppSpacing.iconMd),
              ),
              AppSpacing.hGapSm2,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.body(
                        context.colors.textPrimary,
                      ).copyWith(fontWeight: AppTextStyles.semiBold),
                    ),
                    Text(
                      hint,
                      style: AppTextStyles.caption(context.colors.textSecond),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_outlined,
                color: context.colors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Preview sheet (before upload) ────────────────────────────────────────────

class _PhotoPreviewSheet extends StatefulWidget {
  final List<XFile> initial;
  const _PhotoPreviewSheet({required this.initial});

  @override
  State<_PhotoPreviewSheet> createState() => _PhotoPreviewSheetState();
}

class _PhotoPreviewSheetState extends State<_PhotoPreviewSheet> {
  late final List<XFile> _files = List<XFile>.from(widget.initial);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  'معاينة قبل الرفع',
                  style: AppTextStyles.cardTitle(context.colors.textPrimary),
                ),
                AppSpacing.hGapSm,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.bluePrimary.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.radiusFull,
                  ),
                  child: Text(
                    '${_files.length}',
                    style: AppTextStyles.caption(
                      context.colors.bluePrimary,
                    ).copyWith(fontWeight: AppTextStyles.bold),
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            SizedBox(
              height: 130,
              child: _files.isEmpty
                  ? Center(
                      child: Text(
                        'لم تتبقَّ صور',
                        style: AppTextStyles.bodySmall(
                          context.colors.textFaint,
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _files.length,
                      separatorBuilder: (_, __) => AppSpacing.hGapSm2,
                      itemBuilder: (_, i) {
                        final x = _files[i];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: AppSpacing.radiusLg,
                              child: FutureBuilder<Uint8List>(
                                future: x.readAsBytes(),
                                builder: (_, snap) {
                                  if (!snap.hasData) {
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: context.colors.bgSurface2,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return Image.memory(
                                    snap.data!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _files.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            AppSpacing.gapMd,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(<XFile>[]),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppSpacing.radiusLg,
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: AppTextStyles.body(context.colors.textSecond),
                    ),
                  ),
                ),
                AppSpacing.hGapSm,
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _files.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_files),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colors.bluePrimary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppSpacing.radiusLg,
                      ),
                    ),
                    icon: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'رفع ${_files.length} ${_files.length == 1 ? "صورة" : "صور"}',
                      style: AppTextStyles.button(Colors.white),
                    ),
                  ),
                ),
              ],
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
        Text(label, style: AppTextStyles.caption(color)),
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
                  : Text(label, style: AppTextStyles.button(Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
