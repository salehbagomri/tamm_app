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
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _loading = true);
    try {
      if (status == 'completed') {
        final updates = {'status': status, 'technician_notes': _notesCtrl.text};
        await ref
            .read(assignmentRepositoryProvider)
            .updateAssignmentData(widget.assignmentId, updates);
      } else {
        await ref
            .read(assignmentRepositoryProvider)
            .updateAssignmentStatus(widget.assignmentId, status);
      }
      ref.invalidate(myAssignmentsProvider);
      if (status == 'completed') setState(() => _completed = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            const SizedBox(height: 16),
            TammTextField(
              controller: _notesCtrl,
              label: 'ملاحظات الفني',
              hint: 'اكتب تفاصيل وإصلاحات المهمة هنا...',
              maxLines: 4,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: TammButton(
                    label: AppStrings.startTask,
                    isOutlined: true,
                    isLoading: _loading,
                    onPressed: () => _updateStatus('started'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TammButton(
                    label: AppStrings.endTask,
                    isLoading: _loading,
                    onPressed: () => _updateStatus('completed'),
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
