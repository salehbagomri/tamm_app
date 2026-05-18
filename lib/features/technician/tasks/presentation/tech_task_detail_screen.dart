import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_text_field.dart';
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
    if (ok) ref.invalidate(myAssignmentsProvider);
  }

  Future<void> _onStartWork(String orderId) async {
    final confirmed = await _confirm(
      'هل وصلت لموقع العميل وبدأت العمل؟',
    );
    if (!confirmed || !mounted) return;
    final ok = await ref
        .read(taskUpdateProvider(orderId).notifier)
        .updateStatus(orderId, 'in_progress');
    if (ok) ref.invalidate(myAssignmentsProvider);
  }

  Future<void> _onComplete(String orderId) async {
    // Save notes first if any
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
    final tasksAsync = ref.watch(myAssignmentsProvider);
    final assignmentList = tasksAsync.value ?? [];
    final assignment = assignmentList.firstWhere(
      (e) => e['id'] == widget.assignmentId,
      orElse: () => <String, dynamic>{},
    );

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

    // Track orderId for focus-based auto-save
    if (orderId.isNotEmpty) _orderId = orderId;

    // Initialize notes controller once from existing data
    if (!_notesInitialized && order['technician_notes'] != null) {
      _notesCtrl.text = order['technician_notes'].toString();
      _notesInitialized = true;
    }

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: TammAppBar(
        title: orderNumber.isNotEmpty ? 'طلب #$orderNumber' : 'تفاصيل المهمة',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  _buildStatusBadge(context, orderStatus),
                  AppSpacing.gapMd,

                  // Customer card
                  _buildCustomerCard(context, customerName, customerPhone),
                  AppSpacing.gapMd,

                  // Address card
                  _buildAddressCard(
                    context,
                    address,
                    orderLat,
                    orderLng,
                  ),

                  // Order items
                  if (order['order_items'] != null &&
                      (order['order_items'] as List).isNotEmpty) ...[
                    AppSpacing.gapMd,
                    _buildItemsSection(
                      context,
                      order['order_items'] as List,
                    ),
                  ],

                  // Customer notes
                  if (customerNotes != null &&
                      customerNotes.isNotEmpty) ...[
                    AppSpacing.gapMd,
                    _buildCustomerNotes(context, customerNotes),
                  ],

                  // Completed: show existing technician notes
                  if (orderStatus == 'completed' &&
                      order['technician_notes'] != null &&
                      (order['technician_notes'] as String).isNotEmpty) ...[
                    AppSpacing.gapMd,
                    _buildTechNotesSummary(
                      context,
                      order['technician_notes'] as String,
                    ),
                  ],

                  AppSpacing.gapXl,
                ],
              ),
            ),
          ),

          // Fixed bottom action bar
          if (orderId.isNotEmpty)
            _buildBottomBar(context, orderStatus, orderId),
        ],
      ),
    );
  }

  // ─── Section widgets ──────────────────────────────────────────────────────

  Widget _buildStatusBadge(BuildContext context, String status) {
    final (label, color) = _statusMeta(context, status);
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingSm,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outlined, color: color, size: AppSpacing.iconMd),
          AppSpacing.hGapSm2,
          Text(
            label,
            style: AppTextStyles.body(color).copyWith(
              fontWeight: AppTextStyles.semiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    String name,
    String phone,
  ) {
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
                if (phone.isNotEmpty) ...[
                  AppSpacing.gapXs,
                  Text(
                    phone,
                    style: AppTextStyles.bodySmall(context.colors.textSecond),
                    textDirection: TextDirection.ltr,
                  ),
                ] else
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isProduct ? 'منتج' : 'خدمة'} × ${item['quantity']}',
                          style: AppTextStyles.body(
                            context.colors.textPrimary,
                          ).copyWith(fontWeight: AppTextStyles.semiBold),
                        ),
                        if (includeInst) ...[
                          AppSpacing.gapXs,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs / 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.success.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: AppSpacing.radiusXs,
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
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

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

  // ─── Bottom action bar ────────────────────────────────────────────────────

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

  (String, Color) _statusMeta(BuildContext context, String status) =>
      switch (status) {
        'assigned' => ('تم التعيين — في انتظار توجهك', context.colors.bluePrimary),
        'on_the_way' => ('أنت في الطريق للعميل', context.colors.warning),
        'in_progress' => ('جاري تنفيذ المهمة', context.colors.bluePrimary),
        'completed' => ('تمت المهمة بنجاح', context.colors.success),
        _ => ('حالة غير معروفة', context.colors.textFaint),
      };
}

// ─── Gradient button ──────────────────────────────────────────────────────────

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
