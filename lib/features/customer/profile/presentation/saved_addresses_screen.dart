import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import '../../../../shared/models/saved_address.dart';
import '../../../../shared/providers/saved_addresses_providers.dart';

class SavedAddressesScreen extends ConsumerWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAddresses = ref.watch(savedAddressesProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        elevation: 0,
        title: Text(
          'عناويني المحفوظة',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        actions: [
          IconButton(
            onPressed: () => _openForm(context, ref, existing: null),
            icon: Icon(
              Icons.add_circle_outline,
              color: context.colors.bluePrimary,
            ),
            tooltip: 'إضافة عنوان',
          ),
        ],
      ),
      body: asyncAddresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: context.colors.error,
                size: 40,
              ),
              AppSpacing.gapSm,
              Text(
                e is AppException ? e.message : 'حدث خطأ في تحميل العناوين',
                style: AppTextStyles.body(context.colors.textSecond),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapMd,
              TextButton(
                onPressed: () => ref.invalidate(savedAddressesProvider),
                child: Text(
                  'إعادة المحاولة',
                  style: AppTextStyles.body(context.colors.bluePrimary),
                ),
              ),
            ],
          ),
        ),
        data: (addresses) => addresses.isEmpty
            ? _EmptyState(onAdd: () => _openForm(context, ref, existing: null))
            : ListView.separated(
                padding: AppSpacing.pagePadding,
                itemCount: addresses.length + 1,
                separatorBuilder: (_, __) => AppSpacing.gapSm,
                itemBuilder: (ctx, i) {
                  if (i == addresses.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: TammButton(
                        label: 'إضافة عنوان جديد',
                        type: TammButtonType.secondary,
                        icon: Icons.add_location_alt_outlined,
                        onPressed: () => _openForm(context, ref, existing: null),
                      ),
                    );
                  }
                  return _AddressCard(
                    address: addresses[i],
                    onEdit: () =>
                        _openForm(context, ref, existing: addresses[i]),
                    onDelete: () =>
                        _confirmDelete(context, ref, addresses[i]),
                    onSetDefault: addresses[i].isDefault
                        ? null
                        : () => _setDefault(context, ref, addresses[i].id),
                  );
                },
              ),
      ),
    );
  }

  void _openForm(
    BuildContext context,
    WidgetRef ref, {
    required SavedAddress? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddressForm(
        existing: existing,
        onSaved: () => ref.invalidate(savedAddressesProvider),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedAddress address,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusLg,
        ),
        title: Text(
          'حذف العنوان',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        content: Text(
          'هل تريد حذف "${address.label}"؟',
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
              style: AppTextStyles.body(context.colors.error)
                  .copyWith(fontWeight: AppTextStyles.bold),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    try {
      await ref
          .read(savedAddressesRepositoryProvider)
          .delete(address.id);
      if (context.mounted) ref.invalidate(savedAddressesProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppException ? e.message : 'تعذّر حذف العنوان',
            style: AppTextStyles.body(Colors.white),
          ),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    try {
      await ref.read(savedAddressesRepositoryProvider).setDefault(id);
      ref.invalidate(savedAddressesProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppException ? e.message : 'تعذّر تعيين العنوان الافتراضي',
            style: AppTextStyles.body(Colors.white),
          ),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─── بطاقة عنوان ──────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(
          color: address.isDefault
              ? context.colors.bluePrimary
              : context.colors.border,
          width: address.isDefault ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.bluePrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconFor(address.label),
                color: context.colors.bluePrimary,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    address.label,
                    style: AppTextStyles.body(context.colors.textPrimary)
                        .copyWith(fontWeight: AppTextStyles.semiBold),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.bluePrimary,
                      borderRadius: AppSpacing.radiusFull,
                    ),
                    child: Text(
                      'افتراضي',
                      style: AppTextStyles.caption(Colors.white),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.gapXs,
                Text(
                  address.address,
                  style: AppTextStyles.bodySmall(context.colors.textSecond),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (address.lat != null && address.lng != null) ...[
                  AppSpacing.gapXs,
                  Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        size: 12,
                        color: context.colors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'موقع GPS محفوظ',
                        style: AppTextStyles.caption(context.colors.success),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: context.colors.border),
          Row(
            children: [
              if (onSetDefault != null)
                Expanded(
                  child: TextButton.icon(
                    onPressed: onSetDefault,
                    icon: Icon(
                      Icons.star_outline_rounded,
                      size: 16,
                      color: context.colors.warning,
                    ),
                    label: Text(
                      'افتراضي',
                      style: AppTextStyles.bodySmall(context.colors.warning),
                    ),
                  ),
                ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: context.colors.bluePrimary,
                  ),
                  label: Text(
                    'تعديل',
                    style: AppTextStyles.bodySmall(context.colors.bluePrimary),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: context.colors.error,
                  ),
                  label: Text(
                    'حذف',
                    style: AppTextStyles.bodySmall(context.colors.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String label) {
    if (label.contains('منزل') || label.contains('بيت')) {
      return Icons.home_outlined;
    }
    if (label.contains('عمل') || label.contains('مكتب')) {
      return Icons.work_outline_rounded;
    }
    return Icons.location_on_outlined;
  }
}

// ─── حالة فارغة ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: 64,
              color: context.colors.textFaint,
            ),
            AppSpacing.gapMd,
            Text(
              'لا توجد عناوين محفوظة',
              style: AppTextStyles.cardTitle(context.colors.textPrimary),
            ),
            AppSpacing.gapSm,
            Text(
              'احفظ عناوينك المتكررة للاستخدام السريع عند إتمام الطلب',
              style: AppTextStyles.bodySmall(context.colors.textSecond),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapLg,
            TammButton(
              label: 'إضافة عنوان',
              icon: Icons.add_location_alt_outlined,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── نموذج الإضافة/التعديل ────────────────────────────────────────────────────

class _AddressForm extends ConsumerStatefulWidget {
  final SavedAddress? existing;
  final VoidCallback onSaved;

  const _AddressForm({required this.existing, required this.onSaved});

  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _addressCtrl;
  bool _isDefault = false;
  bool _locationLoading = false;
  double? _lat;
  double? _lng;
  bool _saving = false;

  static const _labelSuggestions = ['المنزل', 'العمل', 'المكتب', 'عنوان آخر'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl = TextEditingController(text: e?.label ?? 'المنزل');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _isDefault = e?.isDefault ?? false;
    _lat = e?.lat;
    _lng = e?.lng;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickGps() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يجب السماح بالوصول للموقع'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحديد الموقع: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _save() async {
    final label = _labelCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    if (label.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى ملء الاسم والتفاصيل',
            style: AppTextStyles.body(Colors.white),
          ),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(savedAddressesRepositoryProvider);
      if (widget.existing == null) {
        // new
        final draft = SavedAddress(
          id: '',
          userId: '',
          label: label,
          address: address,
          city: 'المكلا',
          lat: _lat,
          lng: _lng,
          isDefault: _isDefault,
          createdAt: DateTime.now(),
        );
        await repo.add(draft);
      } else {
        await repo.update(
          widget.existing!.copyWith(
            label: label,
            address: address,
            lat: _lat,
            lng: _lng,
            isDefault: _isDefault,
          ),
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing == null ? 'تم حفظ العنوان' : 'تم تحديث العنوان',
              style: AppTextStyles.body(Colors.white),
            ),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppException ? e.message : 'تعذّر حفظ العنوان',
            style: AppTextStyles.body(Colors.white),
          ),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.existing == null ? 'إضافة عنوان جديد' : 'تعديل العنوان',
              style: AppTextStyles.cardTitle(context.colors.textPrimary),
            ),
            AppSpacing.gapMd,

            // Label suggestions
            Text(
              'اسم العنوان',
              style: AppTextStyles.label(context.colors.textPrimary),
            ),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              children: _labelSuggestions.map((s) {
                final selected = _labelCtrl.text == s;
                return ChoiceChip(
                  label: Text(
                    s,
                    style: AppTextStyles.bodySmall(
                      selected ? Colors.white : context.colors.textPrimary,
                    ),
                  ),
                  selected: selected,
                  selectedColor: context.colors.bluePrimary,
                  backgroundColor: context.colors.bgSurface2,
                  onSelected: (_) {
                    setState(() => _labelCtrl.text = s);
                  },
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.radiusFull,
                  ),
                  side: BorderSide(
                    color: selected
                        ? context.colors.bluePrimary
                        : context.colors.border,
                  ),
                );
              }).toList(),
            ),
            AppSpacing.gapSm,
            TammTextField(
              label: 'أو اكتب اسماً مخصصاً',
              hint: 'مثال: منزل أمي',
              controller: _labelCtrl,
            ),
            AppSpacing.gapMd,

            // Address detail
            TammTextField(
              label: 'تفاصيل العنوان',
              hint: 'الحي، الشارع، علامة مميزة...',
              controller: _addressCtrl,
              maxLines: 2,
            ),
            AppSpacing.gapMd,

            // GPS
            Text(
              'الموقع الجغرافي (اختياري)',
              style: AppTextStyles.label(context.colors.textPrimary),
            ),
            AppSpacing.gapSm,
            GestureDetector(
              onTap: _locationLoading ? null : _pickGps,
              child: Container(
                width: double.infinity,
                padding: AppSpacing.cardPaddingSm,
                decoration: BoxDecoration(
                  color: _lat != null
                      ? context.colors.success.withValues(alpha: 0.08)
                      : context.colors.bgSurface2,
                  borderRadius: AppSpacing.radiusSm,
                  border: Border.all(
                    color: _lat != null
                        ? context.colors.success
                        : context.colors.border,
                  ),
                ),
                child: Row(
                  children: [
                    _locationLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colors.bluePrimary,
                            ),
                          )
                        : Icon(
                            _lat != null
                                ? Icons.check_circle_outline
                                : Icons.my_location,
                            color: _lat != null
                                ? context.colors.success
                                : context.colors.bluePrimary,
                            size: 20,
                          ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(
                        _lat != null
                            ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                            : 'تحديد موقعي الحالي',
                        style: AppTextStyles.bodySmall(
                          _lat != null
                              ? context.colors.success
                              : context.colors.bluePrimary,
                        ),
                      ),
                    ),
                    if (_lat != null)
                      GestureDetector(
                        onTap: () => setState(() {
                          _lat = null;
                          _lng = null;
                        }),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: context.colors.textFaint,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapMd,

            // Default toggle
            Row(
              children: [
                Switch(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  activeThumbColor: context.colors.bluePrimary,
                ),
                AppSpacing.hGapSm,
                Expanded(
                  child: Text(
                    'تعيين كعنوان افتراضي',
                    style: AppTextStyles.body(context.colors.textPrimary),
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,

            TammButton(
              label: widget.existing == null ? 'حفظ العنوان' : 'تحديث العنوان',
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
