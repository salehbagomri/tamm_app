import '../../../../core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/tamm_app_bar.dart';
import '../../../../core/widgets/tamm_loading.dart';
import '../../../../core/widgets/tamm_empty_state.dart';
import '../../../../core/widgets/tamm_card.dart';
import '../../../../core/widgets/tamm_text_field.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';

class MyDevicesScreen extends ConsumerStatefulWidget {
  const MyDevicesScreen({super.key});
  @override
  ConsumerState<MyDevicesScreen> createState() => _MyDevicesScreenState();
}

class _MyDevicesScreenState extends ConsumerState<MyDevicesScreen> {
  List<Map<String, dynamic>>? _devices;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final data = await Supabase.instance.client
        .from('customer_devices')
        .select()
        .eq('customer_id', userId)
        .order('created_at');
    setState(() {
      _devices = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  void _showAddDialog() {
    final brandCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String type = 'ac_split';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.bgSurface,
        title: Text(
          'إضافة جهاز',
          style: AppTextStyles.body(context.colors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                dropdownColor: context.colors.bgSurface2,
                items: const [
                  DropdownMenuItem(value: 'ac_split', child: Text('سبليت')),
                  DropdownMenuItem(value: 'ac_window', child: Text('شباك')),
                  DropdownMenuItem(value: 'ac_central', child: Text('مركزي')),
                  DropdownMenuItem(
                    value: 'solar_system',
                    child: Text('منظومة شمسية'),
                  ),
                ],
                onChanged: (v) => type = v!,
              ),
              AppSpacing.gapSm,
              TammTextField(label: 'العلامة التجارية', controller: brandCtrl),
              AppSpacing.gapSm,
              TammTextField(
                label: 'الموقع في المنزل',
                hint: 'مثل: غرفة النوم',
                controller: locationCtrl,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              final userId = Supabase.instance.client.auth.currentUser!.id;
              await Supabase.instance.client.from('customer_devices').insert({
                'customer_id': userId,
                'device_type': type,
                'brand': brandCtrl.text,
                'location_in_home': locationCtrl.text,
              });
              if (!mounted) return;
              Navigator.pop(context);
              _load();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: TammAppBar(
        title: 'أجهزتي',
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      body: _loading
          ? const TammLoading()
          : _devices == null || _devices!.isEmpty
          ? const TammEmptyState(
              icon: Icons.devices_other,
              message: 'لم تسجل أجهزة بعد',
            )
          : ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: _devices!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final d = _devices![i];
                return TammCard(
                  child: Row(
                    children: [
                      Icon(
                        d['device_type'].toString().contains('solar')
                            ? Icons.solar_power
                            : Icons.ac_unit,
                        color: context.colors.bluePrimary,
                      ),
                      AppSpacing.hGapSm2,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['brand'] ?? d['device_type'],
                              style: AppTextStyles.body(
                                context.colors.textPrimary,
                              ),
                            ),
                            Text(
                              d['location_in_home'] ?? '',
                              style: AppTextStyles.bodySmall(
                                context.colors.textSecond,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: context.colors.error,
                          size: 20,
                        ),
                        onPressed: () async {
                          await Supabase.instance.client
                              .from('customer_devices')
                              .delete()
                              .eq('id', d['id']);
                          _load();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
