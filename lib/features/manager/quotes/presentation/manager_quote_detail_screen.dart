import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/order.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../shared/providers/manager_providers.dart';
import '../../../customer/services/data/quote_repository.dart';
import 'manager_quotes_screen.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';

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
  
  Uint8List? _attachedBytes;
  String? _attachedFileName;
  bool _isSubmitting = false;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    // Realtime: تحديث تلقائي عند تغيير حالة الطلب (مثلاً العميل قبل أو رفض)
    _channel = Supabase.instance.client
        .channel('quote_detail_${widget.orderId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            // تحقق ان التغيير للطلب الحالي فقط
            final changedId = payload.newRecord['id']?.toString();
            if (changedId == widget.orderId || changedId == null) {
              ref.invalidate(orderDetailProvider(widget.orderId));
              ref.invalidate(managerQuotesProvider);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
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
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.bgSurface,
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
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.bluePrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library, color: context.colors.bluePrimary),
              ),
              title: Text('اختر صورة من المعرض', style: GoogleFonts.harmattan(fontSize: 16, color: context.colors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: context.colors.success),
              ),
              title: Text('التقط صورة', style: GoogleFonts.harmattan(fontSize: 16, color: context.colors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.file_present, color: context.colors.warning),
              ),
              title: Text('اختر ملف PDF', style: GoogleFonts.harmattan(fontSize: 16, color: context.colors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (source == 'file') {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );
      if (result != null && result.files.single.bytes != null) {
        final ext = result.files.single.extension?.toLowerCase() ?? '';
        final allowed = ['pdf', 'jpg', 'jpeg', 'png'];
        if (!allowed.contains(ext)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('يرجى اختيار ملف PDF أو صورة (jpg, png)'),
                backgroundColor: context.colors.error,
              ),
            );
          }
          return;
        }
        setState(() {
          _attachedBytes = result.files.single.bytes;
          _attachedFileName = result.files.single.name;
        });
      } else if (result != null && result.files.single.path != null) {
        // Fallback for mobile where bytes may be null
        final file = result.files.single;
        final ext = file.extension?.toLowerCase() ?? '';
        final allowed = ['pdf', 'jpg', 'jpeg', 'png'];
        if (!allowed.contains(ext)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('يرجى اختيار ملف PDF أو صورة (jpg, png)'),
                backgroundColor: context.colors.error,
              ),
            );
          }
          return;
        }
        final bytes = await XFile(file.path!).readAsBytes();
        setState(() {
          _attachedBytes = bytes;
          _attachedFileName = file.name;
        });
      }
    } else {
      final picker = ImagePicker();
      XFile? picked;
      if (source == 'gallery') {
        picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      } else if (source == 'camera') {
        picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      }
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _attachedBytes = bytes;
          _attachedFileName = picked!.name;
        });
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachedBytes = null;
      _attachedFileName = null;
    });
  }

  Future<void> _sendQuote() async {
    if (!_isFormValid()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final repo = ref.read(quoteRepositoryProvider);
      final price = double.parse(_priceController.text.trim());
      
      // Upload attachment if exists (non-blocking if fails)
      String? attachmentUrl;
      if (_attachedBytes != null) {
        try {
          attachmentUrl = await repo.uploadAttachment(
            orderId: widget.orderId,
            bytes: _attachedBytes!,
            fileName: _attachedFileName ?? 'attachment',
          );
        } catch (uploadError) {
          // Upload failed - continue sending quote without attachment
          debugPrint('Attachment upload failed: $uploadError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تعذر رفع المرفق، سيتم إرسال العرض بدون مرفق'),
                backgroundColor: context.colors.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
      
      final currentOrderAsync = ref.read(orderDetailProvider(widget.orderId));
      if (currentOrderAsync.value?.quoteStatus == 'rejected') {
        await repo.resendQuote(
          orderId: widget.orderId,
          price: price,
          details: _detailsController.text.trim(),
          duration: _durationController.text.trim().isNotEmpty ? _durationController.text.trim() : null,
          attachmentUrl: attachmentUrl,
        );
      } else {
        await repo.sendQuote(
          orderId: widget.orderId,
          price: price,
          details: _detailsController.text.trim(),
          duration: _durationController.text.trim().isNotEmpty ? _durationController.text.trim() : null,
          attachmentUrl: attachmentUrl,
        );
      }
      
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(managerQuotesProvider);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: context.colors.success),
                const SizedBox(width: 8),
                const Text('تم الإرسال بنجاح'),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            e is AppException ? e.message : 'حدث خطأ في إرسال العرض',
            style: GoogleFonts.harmattan(fontSize: 15),
          ),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final currentQuoteStatus = orderAsync.valueOrNull?.quoteStatus;
    final appBarTitle = switch (currentQuoteStatus) {
      'pending' => 'عرض السعر - بانتظار إرسال',
      'sent' => 'عرض السعر - تم الإرسال',
      'accepted' => 'عرض السعر - مقبول ✓',
      'rejected' => 'عرض السعر - مرفوض',
      _ => 'تفاصيل العرض',
    };

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: TammAppBar(title: appBarTitle),
      body: orderAsync.when(
        data: (order) => _buildBody(order),
        loading: () => const TammLoading(),
        error: (err, stack) => ErrorStateWidget(
          message: err is AppException ? err.message : 'حدث خطأ في تحميل تفاصيل الطلب',
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
      ),
    );
  }

  Widget _buildBody(Order order) {
    final isPending = order.quoteStatus == 'pending';
    final isRejected = order.quoteStatus == 'rejected';
    final showForm = isPending || isRejected;

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
                      color: context.colors.bluePrimary.withValues(alpha: 0.05),
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: context.colors.bluePrimary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.colors.bluePrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, color: context.colors.bluePrimary),
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
                                  color: context.colors.textPrimary,
                                ),
                              ),
                              if (order.customerProfile!['phone'] != null)
                                Text(
                                  order.customerProfile!['phone'],
                                  style: GoogleFonts.harmattan(
                                    fontSize: 14,
                                    color: context.colors.textSecond,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (order.customerProfile!['phone'] != null)
                          IconButton(
                            icon: Icon(Icons.phone, color: context.colors.bluePrimary),
                            style: IconButton.styleFrom(
                              backgroundColor: context.colors.bluePrimary.withValues(alpha: 0.1),
                            ),
                            onPressed: () async {
                              final url = Uri.parse('tel:${order.customerProfile!['phone']}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
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
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.bgSurface,
                    borderRadius: AppSpacing.radiusLg,
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(title: 'رقم الطلب', value: '#${order.orderNumber}'),
                      const SizedBox(height: 8),
                      _DetailRow(title: 'الحالة', value: order.statusLabel),
                      Divider(height: 24, color: context.colors.border),
                      Text(
                        'وصف الاحتياج:',
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textSecond,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.notes ?? 'لا يوجد وصف',
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          color: context.colors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      Divider(height: 24, color: context.colors.border),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 20, color: context.colors.bluePrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.address,
                              style: GoogleFonts.harmattan(
                                fontSize: 16,
                                color: context.colors.textPrimary,
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
                  showForm ? (isRejected ? 'تقديم عرض جديد' : 'تقديم عرض السعر') : 'العرض المُرسل',
                  style: GoogleFonts.harmattan(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (showForm) ...[
                  if (isRejected && order.rejectionReason != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: context.colors.error.withValues(alpha: 0.08),
                        borderRadius: AppSpacing.radiusLg,
                        border: Border.all(color: context.colors.error.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.feedback, color: context.colors.error),
                              const SizedBox(width: 8),
                              Text(
                                'سبب الرفض من العميل:',
                                style: GoogleFonts.harmattan(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.rejectionReason!,
                            style: GoogleFonts.harmattan(
                              fontSize: 16,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Edit Form for Pending / Rejected
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
                      color: context.colors.textSecond,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_attachedBytes != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.colors.success.withValues(alpha: 0.08),
                        borderRadius: AppSpacing.radiusSm,
                        border: Border.all(color: context.colors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _attachedFileName?.endsWith('.pdf') == true
                                ? Icons.picture_as_pdf
                                : Icons.image,
                            color: context.colors.success,
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
                                    color: context.colors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'جاهز للإرسال',
                                  style: GoogleFonts.harmattan(
                                    fontSize: 12,
                                    color: context.colors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: context.colors.error, size: 20),
                            onPressed: _removeAttachment,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: Icon(Icons.attach_file, color: context.colors.bluePrimary),
                      label: Text(
                        'إرفاق صورة العرض أو PDF',
                        style: GoogleFonts.harmattan(
                          fontSize: 16,
                          color: context.colors.bluePrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        side: BorderSide(color: context.colors.bluePrimary.withValues(alpha: 0.4)),
                        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.radiusSm),
                      ),
                    ),
                  ],
                ] else ...[
                  // Read-only Display for Sent/Accepted/Rejected
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.bgSurface,
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: context.colors.bluePrimary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(
                          title: 'السعر المُرسل', 
                          value: '${order.quotePrice?.toInt() ?? 0} ر.س',
                          isBoldValue: true,
                          valueColor: context.colors.blueSky,
                        ),
                        Divider(height: 24, color: context.colors.border),
                        _DetailRow(
                          title: 'مدة التنفيذ', 
                          value: order.quoteDuration ?? 'لم تحدد',
                        ),
                        Divider(height: 24, color: context.colors.border),
                        Text(
                          'تفاصيل العرض:',
                          style: GoogleFonts.harmattan(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textSecond,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.quoteDetails ?? '',
                          style: GoogleFonts.harmattan(
                            fontSize: 16,
                            color: context.colors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                        // Show attachment if exists
                        if (order.quoteAttachmentUrl != null) ...[
                          Divider(height: 24, color: context.colors.border),
                          Row(
                            children: [
                              Icon(Icons.attach_file, size: 18, color: context.colors.bluePrimary),
                              const SizedBox(width: 8),
                              Text(
                                'مرفق مع العرض',
                                style: GoogleFonts.harmattan(
                                  fontSize: 16,
                                  color: context.colors.bluePrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (order.quoteStatus == 'rejected' && order.rejectionReason != null) ...[
                          Divider(height: 24, color: context.colors.border),
                          Text(
                            'سبب الرفض من العميل:',
                            style: GoogleFonts.harmattan(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.colors.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.rejectionReason!,
                            style: GoogleFonts.harmattan(
                              fontSize: 16,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                
                // 3. Timeline
                _buildTimeline(order),
                const SizedBox(height: 32),

                // Accepted status card
                if (order.quoteStatus == 'accepted') ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.success.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: context.colors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: context.colors.success, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'العميل وافق على العرض ✓',
                                style: GoogleFonts.harmattan(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.success,
                                ),
                              ),
                              Text(
                                'يمكنك الآن تعيين فني لتنفيذ الطلب',
                                style: GoogleFonts.harmattan(
                                  fontSize: 14,
                                  color: context.colors.textSecond,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rejected status card
                if (order.quoteStatus == 'rejected') ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.error.withValues(alpha: 0.08),
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: context.colors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: context.colors.error, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'العميل رفض العرض',
                            style: GoogleFonts.harmattan(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.colors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 3. Sticky Buttons
        if (showForm)
          _buildStickyBar(
            child: TammButton(
              label: isRejected ? 'إرسال العرض الجديد' : 'إرسال العرض للعميل',
              icon: Icons.send,
              isLoading: _isSubmitting,
              onPressed: _isFormValid() ? _sendQuote : null,
            ),
          ),

        // After acceptance: assign technician
        if (order.quoteStatus == 'accepted' && (order.status == 'confirmed' || order.status == 'pending'))
          _buildStickyBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TammButton(
                  label: 'تعيين فني للتنفيذ',
                  icon: Icons.engineering,
                  onPressed: () => _showAssignDialog(order),
                ),
                const SizedBox(height: 10),
                TammButton(
                  label: 'إلغاء الطلب',
                  type: TammButtonType.secondary,
                  isLoading: _isSubmitting,
                  onPressed: () => _cancelOrder(order),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStickyBar({required Widget child}) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(top: BorderSide(color: context.colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTimeline(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التسلسل الزمني:',
          style: GoogleFonts.harmattan(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _TimelineItem(
          title: 'الطلب مبدئي',
          content: 'تم رفع الطلب من العميل',
          time: order.createdAt,
          isCompleted: true,
          isLast: order.quoteSentAt == null,
        ),
        if (order.quoteSentAt != null)
          _TimelineItem(
            title: 'تم إرسال العرض',
            content: 'قام المدير بتقديم العرض',
            time: order.quoteSentAt!,
            isCompleted: true,
            isLast: order.quoteRespondedAt == null,
          ),
        if (order.quoteRespondedAt != null)
          _TimelineItem(
            title: order.quoteStatus == 'rejected' ? 'تم الرفض' : 'تم القبول',
            content: order.quoteStatus == 'rejected' ? 'تم الرفض من العميل' : 'تم القبول من العميل وبانتظار تعيين فني',
            time: order.quoteRespondedAt!,
            isCompleted: true,
            isLast: true,
            color: order.quoteStatus == 'rejected' ? context.colors.error : context.colors.success,
          ),
      ],
    );
  }

  void _showAssignDialog(Order order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.bgSurface,
        title: Text(
          'تعيين فني',
          style: GoogleFonts.harmattan(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        content: Consumer(
          builder: (context, ref, child) {
            final techsAsync = ref.watch(techniciansProvider);
            return techsAsync.when(
              data: (techs) => SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: techs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final t = techs[i];
                    final p = t['profiles'] as Map<String, dynamic>?;
                    return ListTile(
                      title: Text(
                        p?['full_name'] ?? '',
                        style: GoogleFonts.harmattan(color: context.colors.textPrimary),
                      ),
                      subtitle: Text(
                        t['specialization'] ?? '',
                        style: GoogleFonts.harmattan(color: context.colors.textSecond, fontSize: 14),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: t['status'] == 'available'
                              ? context.colors.success.withValues(alpha: 0.15)
                              : context.colors.warning.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.radiusFull,
                        ),
                        child: Text(
                          t['status'] == 'available' ? 'متاح' : 'مشغول',
                          style: GoogleFonts.harmattan(
                            fontSize: 12,
                            color: t['status'] == 'available' ? context.colors.success : context.colors.warning,
                          ),
                        ),
                      ),
                      onTap: () async {
                        await ref.read(assignmentRepositoryProvider).assignTechnician(
                          orderId: widget.orderId,
                          technicianId: t['id'],
                        );
                        ref.invalidate(orderDetailProvider(widget.orderId));
                        ref.invalidate(managerQuotesProvider);
                        ref.invalidate(allOrdersProvider(null));
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تعيين الفني بنجاح')),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              loading: () => const TammLoading(),
              error: (e, _) => Text('$e'),
            );
          },
        ),
      ),
    );
  }

  Future<void> _cancelOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الإلغاء'),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('نعم، ألغِ', style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSubmitting = true);
      try {
        await ref.read(orderRepositoryProvider).updateOrderStatus(widget.orderId, 'cancelled');
        ref.invalidate(orderDetailProvider(widget.orderId));
        ref.invalidate(managerQuotesProvider);
        ref.invalidate(allOrdersProvider(null));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إلغاء الطلب')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
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
            color: context.colors.textSecond,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.harmattan(
            fontSize: isBoldValue ? 20 : 16,
            fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String content;
  final DateTime time;
  final bool isCompleted;
  final bool isLast;
  final Color? color;

  const _TimelineItem({
    required this.title,
    required this.content,
    required this.time,
    required this.isCompleted,
    this.isLast = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color ?? (isCompleted ? context.colors.bluePrimary : context.colors.textSecond.withValues(alpha: 0.3)),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? context.colors.bluePrimary : context.colors.textSecond.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.harmattan(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color ?? context.colors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      content,
                      style: GoogleFonts.harmattan(
                        fontSize: 14,
                        color: context.colors.textSecond,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(time),
                    style: GoogleFonts.harmattan(
                      fontSize: 12,
                      color: context.colors.textSecond,
                    ),
                  ),
                ],
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
