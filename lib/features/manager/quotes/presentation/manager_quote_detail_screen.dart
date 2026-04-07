import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../customer/services/data/quote_repository.dart';
import 'manager_quotes_screen.dart';

class ManagerQuoteDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ManagerQuoteDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<ManagerQuoteDetailScreen> createState() => _ManagerQuoteDetailScreenState();
}

class _ManagerQuoteDetailScreenState extends ConsumerState<ManagerQuoteDetailScreen> {
  final _priceController = TextEditingController();
  final _detailsController = TextEditingController();
  final _durationController = TextEditingController();
  
  File? _attachedFile;
  String? _attachedFileName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    _detailsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _priceController.text.trim().isNotEmpty && 
           _detailsController.text.trim().isNotEmpty &&
           double.tryParse(_priceController.text.trim()) != null;
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    
    // Show options: camera, gallery, or file
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إرفاق ملف',
              style: GoogleFonts.harmattan(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: AppColors.bluePrimary),
              ),
              title: Text('اختر صورة من المعرض', style: GoogleFonts.harmattan(fontSize: 16, color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.success),
              ),
              title: Text('التقط صورة', style: GoogleFonts.harmattan(fontSize: 16, color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    XFile? picked;
    if (source == 'gallery') {
      picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    } else if (source == 'camera') {
      picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    }

    if (picked != null) {
      setState(() {
        _attachedFile = File(picked!.path);
        _attachedFileName = picked.name;
      });
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachedFile = null;
      _attachedFileName = null;
    });
  }

  Future<void> _sendQuote() async {
    if (!_isFormValid()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final repo = ref.read(quoteRepositoryProvider);
      final price = double.parse(_priceController.text.trim());
      
      // Upload attachment if exists
      String? attachmentUrl;
      if (_attachedFile != null) {
        attachmentUrl = await repo.uploadAttachment(
          orderId: widget.orderId,
          file: _attachedFile!,
        );
      }
      
      await repo.sendQuote(
        orderId: widget.orderId,
        price: price,
        details: _detailsController.text.trim(),
        duration: _durationController.text.trim().isNotEmpty ? _durationController.text.trim() : null,
        attachmentUrl: attachmentUrl,
      );
      
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(managerQuotesProvider);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('تم الإرسال بنجاح'),
              ],
            ),
            content: const Text('تم إرسال عرض السعر للعميل. سيتم إشعارك عند قبوله أو رفضه.'),
            actions: [
              TammButton(
                label: 'العودة للطلبات',
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.pop();
                },
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const TammAppBar(title: 'تفاصيل العرض'),
      body: orderAsync.when(
        data: (order) => _buildBody(order),
        loading: () => const TammLoading(),
        error: (err, stack) => Center(child: Text('حدث خطأ: $err')),
      ),
    );
  }

  Widget _buildBody(Order order) {
    final isPending = order.quoteStatus == 'pending';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                if (order.customerProfile != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withValues(alpha: 0.05),
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: AppColors.bluePrimary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.bluePrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: AppColors.bluePrimary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerProfile!['full_name'] ?? 'عميل',
                                style: GoogleFonts.harmattan(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (order.customerProfile!['phone'] != null)
                                Text(
                                  order.customerProfile!['phone'],
                                  style: GoogleFonts.harmattan(
                                    fontSize: 14,
                                    color: AppColors.textSecond,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 1. Customer Request Details
                Text(
                  'تفاصيل الطلب',
                  style: GoogleFonts.harmattan(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: AppSpacing.radiusLg,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(title: 'رقم الطلب', value: '#${order.orderNumber}'),
                      const SizedBox(height: 8),
                      _DetailRow(title: 'الحالة', value: order.statusLabel),
                      const Divider(height: 24, color: AppColors.border),
                      Text(
                        'وصف الاحتياج:',
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecond,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.notes ?? 'لا يوجد وصف',
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 20, color: AppColors.bluePrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.address,
                              style: GoogleFonts.harmattan(
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Manager Response Form or Display Sent Details
                Text(
                  isPending ? 'تقديم عرض السعر' : 'العرض المُرسل',
                  style: GoogleFonts.harmattan(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (isPending) ...[
                  // Edit Form for Pending
                  TammTextField(
                    label: 'السعر الإجمالي (ر.س)',
                    hint: '500',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState((){}),
                  ),
                  const SizedBox(height: 16),
                  TammTextField(
                    label: 'تفاصيل العرض وما يشمله',
                    hint: 'يشمل التركيب والمواد الأساسية والضمان...',
                    controller: _detailsController,
                    maxLines: 4,
                    onChanged: (val) => setState((){}),
                  ),
                  const SizedBox(height: 16),
                  TammTextField(
                    label: 'مدة التنفيذ التقديرية (اختياري)',
                    hint: 'مثال: ٣ أيام عمل',
                    controller: _durationController,
                  ),
                  const SizedBox(height: 20),

                  // Attachment Section
                  Text(
                    'إرفاق ملف (اختياري)',
                    style: GoogleFonts.harmattan(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecond,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_attachedFile != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: AppSpacing.radiusSm,
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _attachedFileName?.endsWith('.pdf') == true
                                ? Icons.picture_as_pdf
                                : Icons.image,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _attachedFileName ?? 'ملف مرفق',
                                  style: GoogleFonts.harmattan(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'جاهز للإرسال',
                                  style: GoogleFonts.harmattan(
                                    fontSize: 12,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                            onPressed: _removeAttachment,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file, color: AppColors.bluePrimary),
                      label: Text(
                        'إرفاق صورة العرض أو PDF',
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          color: AppColors.bluePrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        side: BorderSide(color: AppColors.bluePrimary.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusSm),
                      ),
                    ),
                  ],
                ] else ...[
                  // Read-only Display for Sent/Accepted/Rejected
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: AppColors.bluePrimary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(
                          title: 'السعر المُرسل', 
                          value: '${order.quotePrice?.toInt() ?? 0} ر.س',
                          isBoldValue: true,
                          valueColor: AppColors.blueSky,
                        ),
                        const Divider(height: 24, color: AppColors.border),
                        _DetailRow(
                          title: 'مدة التنفيذ', 
                          value: order.quoteDuration ?? 'لم تحدد',
                        ),
                        const Divider(height: 24, color: AppColors.border),
                        Text(
                          'تفاصيل العرض:',
                          style: GoogleFonts.harmattan(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecond,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.quoteDetails ?? '',
                          style: GoogleFonts.harmattan(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                        // Show attachment if exists
                        if (order.quoteAttachmentUrl != null) ...[
                          const Divider(height: 24, color: AppColors.border),
                          Row(
                            children: [
                              const Icon(Icons.attach_file, size: 18, color: AppColors.bluePrimary),
                              const SizedBox(width: 8),
                              Text(
                                'مرفق مع العرض',
                                style: GoogleFonts.harmattan(
                                  fontSize: 16,
                                  color: AppColors.bluePrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (order.quoteStatus == 'rejected' && order.rejectionReason != null) ...[
                          const Divider(height: 24, color: AppColors.border),
                          Text(
                            'سبب الرفض من العميل:',
                            style: GoogleFonts.harmattan(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.rejectionReason!,
                            style: GoogleFonts.harmattan(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 3. Sticky Button
        if (isPending)
          Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: TammButton(
              label: 'إرسال العرض للعميل',
              icon: Icons.send,
              isLoading: _isSubmitting,
              onPressed: _isFormValid() ? _sendQuote : null,
            ),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isBoldValue;
  final Color? valueColor;

  const _DetailRow({
    required this.title,
    required this.value,
    this.isBoldValue = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.harmattan(
            fontSize: 16,
            color: AppColors.textSecond,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.harmattan(
            fontSize: isBoldValue ? 20 : 16,
            fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
