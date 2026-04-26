import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/product_specs.dart';
import 'tamm_text_field.dart';

class SpecsEditor extends StatefulWidget {
  final Map<String, dynamic> initialSpecs;
  final String category;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const SpecsEditor({
    super.key,
    required this.initialSpecs,
    required this.category,
    required this.onChanged,
  });

  @override
  State<SpecsEditor> createState() => _SpecsEditorState();
}

class _SpecsEditorState extends State<SpecsEditor> {
  late Map<String, dynamic> _specs;

  @override
  void initState() {
    super.initState();
    _specs = Map<String, dynamic>.from(widget.initialSpecs);
  }

  @override
  void didUpdateWidget(SpecsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category || oldWidget.initialSpecs != widget.initialSpecs) {
      _specs = Map<String, dynamic>.from(widget.initialSpecs);
    }
  }

  void _notifyChanges() {
    widget.onChanged(Map<String, dynamic>.from(_specs));
  }

  void _addSpec(String key, String value) {
    setState(() {
      _specs[key] = value;
    });
    _notifyChanges();
  }

  void _removeSpec(String key) {
    setState(() {
      _specs.remove(key);
    });
    _notifyChanges();
  }

  void _updateSpecValue(String key, String value) {
    setState(() {
      _specs[key] = value;
    });
    _notifyChanges();
  }

  void _showAddCustomSpecDialog() {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text('إضافة مواصفة مخصصة', style: GoogleFonts.harmattan(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TammTextField(
              label: 'اسم المواصفة (عربي)',
              controller: keyCtrl,
            ),
            const SizedBox(height: 12),
            TammTextField(
              label: 'القيمة',
              controller: valCtrl,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.harmattan(color: AppColors.textSecond)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.bluePrimary),
            onPressed: () {
              if (keyCtrl.text.isNotEmpty && valCtrl.text.isNotEmpty) {
                _addSpec(keyCtrl.text, valCtrl.text);
                Navigator.pop(context);
              }
            },
            child: Text('إضافة', style: GoogleFonts.harmattan(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendedKeys = categoryDefaultSpecs[widget.category] ?? [];
    final availableRecommendedKeys = recommendedKeys.where((k) => !_specs.containsKey(k)).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface2,
        borderRadius: AppSpacing.radius,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: AppColors.bluePrimary),
              const SizedBox(width: 8),
              Text(
                'المواصفات التقنية',
                style: GoogleFonts.harmattan(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (availableRecommendedKeys.isNotEmpty) ...[
            Text(
              'مواصفات مقترحة (اضغط للإضافة):',
              style: GoogleFonts.harmattan(fontSize: 14, color: AppColors.textSecond),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableRecommendedKeys.map((key) {
                return ActionChip(
                  label: Text(specsTranslation[key] ?? key, style: GoogleFonts.harmattan(fontSize: 13)),
                  backgroundColor: AppColors.bgPrimary,
                  side: const BorderSide(color: AppColors.border),
                  onPressed: () {
                    _addSpec(key, '');
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          if (_specs.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: AppSpacing.radius,
              ),
              child: Column(
                children: _specs.entries.map((e) {
                  final isLast = _specs.entries.last.key == e.key;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            specsTranslation[e.key] ?? e.key,
                            style: GoogleFonts.harmattan(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: e.value.toString(),
                            style: GoogleFonts.harmattan(),
                            decoration: InputDecoration(
                              hintText: 'القيمة...',
                              hintStyle: GoogleFonts.harmattan(color: AppColors.textFaint),
                              border: const UnderlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              isDense: true,
                            ),
                            onChanged: (val) => _updateSpecValue(e.key, val),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          onPressed: () => _removeSpec(e.key),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('إضافة من القائمة...', style: GoogleFonts.harmattan(color: AppColors.bluePrimary)),
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.bluePrimary),
                    items: specsTranslation.entries
                        .where((e) => !_specs.containsKey(e.key))
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value, style: GoogleFonts.harmattan()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) _addSpec(val, '');
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _showAddCustomSpecDialog,
                icon: const Icon(Icons.add, size: 18),
                label: Text('مواصفة مخصصة', style: GoogleFonts.harmattan()),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecond),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
