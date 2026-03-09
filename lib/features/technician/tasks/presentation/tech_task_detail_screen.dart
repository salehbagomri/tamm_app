import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_success_badge.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/providers/manager_providers.dart';
import '../../../../shared/providers/technician_providers.dart';
import '../../../../shared/providers/order_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class TechTaskDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  const TechTaskDetailScreen({super.key, required this.assignmentId});
  @override
  ConsumerState<TechTaskDetailScreen> createState() =>
      _TechTaskDetailScreenState();
}

class _TechTaskDetailScreenState extends ConsumerState<TechTaskDetailScreen> {
  bool _loading = false;
  bool _completed = false;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tasksAsync = ref.read(myAssignmentsProvider);
      final assignmentList = tasksAsync.value ?? [];
      final assignment = assignmentList.firstWhere(
        (e) => e['id'] == widget.assignmentId,
        orElse: () => <String, dynamic>{},
      );
      if (assignment['technician_notes'] != null) {
        _notesCtrl.text = assignment['technician_notes'].toString();
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status, [String? orderId]) async {
    setState(() => _loading = true);
    try {
      if (status == 'completed') {
        final updates = {'status': status, 'technician_notes': _notesCtrl.text};
        await ref
            .read(assignmentRepositoryProvider)
            .updateAssignmentData(widget.assignmentId, updates);

        if (orderId != null) {
          await ref
              .read(orderRepositoryProvider)
              .updateOrderStatus(orderId, 'completed');
        }
      } else {
        await ref
            .read(assignmentRepositoryProvider)
            .updateAssignmentStatus(widget.assignmentId, status);
        if (orderId != null && status == 'started') {
          await ref
              .read(orderRepositoryProvider)
              .updateOrderStatus(orderId, 'in_progress');
        }
      }
      ref.invalidate(myAssignmentsProvider);

      if (status == 'started') {
        if (mounted) Navigator.pop(context);
      } else if (status == 'completed') {
        setState(() => _completed = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;

    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      if (!await launchUrl(launchUri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر فتح تطبيق الاتصال')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح تطبيق الاتصال')));
      }
    }
  }

  Future<void> _openMaps(String address) async {
    if (address.isEmpty) return;
    final query = Uri.encodeComponent(address);
    final Uri launchUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    try {
      if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تعذر فتح الخرائط')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح الخرائط')));
      }
    }
  }

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
    final orderNumber = order['order_number']?.toString() ?? '';
    final notes = order['notes']?.toString();
    final isStarted = assignment['status'] == 'started';

    if (_completed) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TammSuccessBadge(message: 'تمّ الإنجاز ✓'),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: TammButton(
                  label: 'رجوع للمهام',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'تفاصيل المهمة'),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppSpacing.radiusLg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'طلب #$orderNumber',
                        style: const TextStyle(
                          color: AppColors.bluePrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isStarted
                              ? AppColors.warning.withValues(alpha: 0.2)
                              : AppColors.bluePrimary.withValues(alpha: 0.2),
                          borderRadius: AppSpacing.radiusSm,
                        ),
                        child: Text(
                          isStarted ? 'قيد التنفيذ' : 'جديدة',
                          style: TextStyle(
                            color: isStarted
                                ? AppColors.warning
                                : AppColors.bluePrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.bgPrimary,
                      child: Icon(Icons.person, color: AppColors.blueDark),
                    ),
                    title: Text(
                      customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(customerPhone),
                    trailing: IconButton(
                      icon: const Icon(Icons.call, color: AppColors.success),
                      onPressed: () => _makePhoneCall(customerPhone),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.bgPrimary,
                      child: Icon(Icons.location_on, color: AppColors.blueDark),
                    ),
                    title: const Text(
                      'العنوان',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(address),
                    trailing: IconButton(
                      icon: const Icon(Icons.map, color: AppColors.bluePrimary),
                      onPressed: () => _openMaps(address),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (notes != null && notes.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: AppSpacing.radiusLg,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.speaker_notes,
                      color: AppColors.textSecond,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ملاحظات العميل:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notes,
                            style: const TextStyle(color: AppColors.textSecond),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TammTextField(
              controller: _notesCtrl,
              label: 'ملاحظات الفني',
              hint: 'اكتب تفاصيل وإصلاحات المهمة هنا...',
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TammButton(
                    label: AppStrings.startTask,
                    isOutlined: true,
                    isLoading: _loading,
                    onPressed: () => _updateStatus('started', order['id']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TammButton(
                    label: AppStrings.endTask,
                    isLoading: _loading,
                    onPressed: () => _updateStatus('completed', order['id']),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
